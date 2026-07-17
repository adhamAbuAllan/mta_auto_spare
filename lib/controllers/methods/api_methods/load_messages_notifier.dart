import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/chat_api.dart';
import '../../../api/chat_socket_service.dart';
import '../../../models/models.dart';
import '../local_methods/chat_message_cache_store.dart';
import '../../statuses/message_state.dart';

typedef MessagePreviewChanged =
    void Function({
      required int conversationId,
      required MessageModel message,
      required bool isActiveConversation,
      required int currentUserId,
    });

typedef ConversationMessagesChanged =
    void Function({
      required int conversationId,
      required List<MessageModel> messages,
      required bool isActiveConversation,
      required int currentUserId,
    });

typedef IncomingMessageReceived =
    void Function({
      required MessageModel message,
      required bool isActiveConversation,
      required int currentUserId,
    });

typedef ConversationReadChanged = void Function(int conversationId);
typedef ResolveLiveAccessToken = Future<String?> Function();
typedef ResolveCacheUserId = int? Function();
typedef UserPresenceChanged =
    void Function({
      required int userId,
      required bool isOnline,
      DateTime? lastSeenAt,
    });

class LoadMessagesNotifier extends StateNotifier<MessageState> {
  static const Duration _typingRefreshInterval = Duration(seconds: 3);
  static const Duration _typingIdleStopDelay = Duration(seconds: 3);

  LoadMessagesNotifier(
    this._chatApi,
    this._socketService, {
    required ChatMessageCacheStore cacheStore,
    required ResolveLiveAccessToken resolveLiveAccessToken,
    required ResolveCacheUserId resolveCacheUserId,
    this.onMessagePreviewChanged,
    this.onIncomingMessageReceived,
    this.onConversationMessagesChanged,
    this.onConversationReadChanged,
    this.onUserPresenceChanged,
  }) : _resolveLiveAccessToken = resolveLiveAccessToken,
       _resolveCacheUserId = resolveCacheUserId,
       _cacheStore = cacheStore,
       super(const MessageState()) {
    _socketEventSubscription = _socketService.events.listen(_handleSocketEvent);
    _socketStatusSubscription = _socketService.statuses.listen(
      _handleSocketStatus,
    );
  }

  final ChatApi _chatApi;
  final ChatSocketService _socketService;
  final ResolveLiveAccessToken _resolveLiveAccessToken;
  final ResolveCacheUserId _resolveCacheUserId;
  final ChatMessageCacheStore _cacheStore;
  final MessagePreviewChanged? onMessagePreviewChanged;
  final IncomingMessageReceived? onIncomingMessageReceived;
  final ConversationMessagesChanged? onConversationMessagesChanged;
  final ConversationReadChanged? onConversationReadChanged;
  final UserPresenceChanged? onUserPresenceChanged;

  final Map<int, MessageState> _messageCache = {};
  final Map<int, DateTime> _pendingSeenMarkers = {};
  StreamSubscription<ChatSocketEvent>? _socketEventSubscription;
  StreamSubscription<ChatConnectionStatus>? _socketStatusSubscription;
  Timer? _typingRefreshTimer;
  Timer? _typingStopTimer;
  int _tempMessageSeed = 0;
  int? _activeConversationId;
  int? _currentUserId;
  bool _disposed = false;
  bool _typingActive = false;

  MessageState? peek(int conversationId) => _messageCache[conversationId];

  @override
  void dispose() {
    _disposed = true;
    _cancelTypingTimers();
    _socketEventSubscription?.cancel();
    _socketStatusSubscription?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> load(int conversationId, {bool forceRefresh = false}) async {
    final cachedState =
        _messageCache[conversationId] ??
        _restorePersistedConversationState(conversationId);

    state = (cachedState ?? state).copyWith(
      isLoading: forceRefresh || cachedState == null,
      conversationId: conversationId,
      messages: cachedState?.messages ?? const [],
      nextPageUrl: cachedState?.nextPageUrl,
      pendingMessageCount: cachedState?.pendingMessageCount ?? 0,
      errorMessage: null,
      isLoadingMore: false,
    );

    try {
      final page = await _chatApi.getMessages(conversationId: conversationId);
      // Socket events can arrive while this HTTP request is in flight (most
      // commonly immediately after a reconnect). Never replace that live
      // state with a potentially older paginated response.
      final latestState = _stateForConversation(conversationId);
      final mergedMessages = _mergeLoadedMessages(
        currentMessages: latestState.messages,
        loadedMessages: page.results,
        conversationId: conversationId,
      );
      final nextState = latestState.copyWith(
        isLoading: false,
        conversationId: conversationId,
        messages: mergedMessages,
        nextPageUrl: page.next,
        errorMessage: null,
      );
      _cacheConversationState(conversationId, nextState);
    } on ApiException catch (error) {
      debugPrint('[Chat][Messages][Load][$conversationId] ${error.message}');
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      debugPrint(
        '[Chat][Messages][Load][$conversationId][Unexpected] ${error.toString()}',
      );
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  // Future<void> loadMore() async {
  //   final conversationId = state.conversationId;
  //   if (conversationId == null || !state.hasMore || state.isLoadingMore) {
  //     return;
  //   }
  //
  //   state = state.copyWith(isLoadingMore: true, errorMessage: null);
  //
  //   try {
  //     final page = await _chatApi.getMessages(
  //       conversationId: conversationId,
  //       pageUrl: state.nextPageUrl,
  //     );
  //     final mergedMessages = _sortMessages([...state.messages, ...page.results]);
  //     final nextState = state.copyWith(
  //       isLoadingMore: false,
  //       messages: mergedMessages,
  //       nextPageUrl: page.next,
  //       errorMessage: null,
  //     );
  //     _cacheConversationState(conversationId, nextState);
  //   } on ApiException catch (error) {
  //     debugPrint(
  //       '[Chat][Messages][LoadMore][$conversationId] ${error.message}',
  //     );
  //     state = state.copyWith(isLoadingMore: false, errorMessage: error.message);
  //   } catch (error, stackTrace) {
  //     debugPrint(
  //       '[Chat][Messages][LoadMore][$conversationId][Unexpected] ${error.toString()}',
  //     );
  //     debugPrintStack(stackTrace: stackTrace);
  //     state = state.copyWith(
  //       isLoadingMore: false,
  //       errorMessage: error.toString(),
  //     );
  //   }
  // }

  Future<void> activateConversation({
    required int conversationId,
    required int currentUserId,
    required String accessToken,
  }) async {
    _activeConversationId = conversationId;
    _currentUserId = currentUserId;

    final currentState = _stateForConversation(conversationId).copyWith(
      conversationId: conversationId,
      connectionStatus: _socketService.status,
      errorMessage: null,
    );
    _cacheConversationState(conversationId, currentState);
    final liveAccessToken = await _resolveLiveAccessToken();
    final tokenToUse = liveAccessToken?.trim().isNotEmpty == true
        ? liveAccessToken!.trim()
        : accessToken;
    await _socketService.connect(
      conversationId: conversationId,
      token: tokenToUse,
    );
  }

  Future<void> detachConversation([int? conversationId]) async {
    final targetConversationId = conversationId ?? _activeConversationId;
    if (targetConversationId == null) {
      return;
    }

    _cancelTypingTimers();
    _typingActive = false;
    if (_activeConversationId == targetConversationId) {
      _activeConversationId = null;
      _currentUserId = null;
    }
    await _socketService.disconnect();
  }

  Future<void> deactivateConversation([int? conversationId]) async {
    final targetConversationId = conversationId ?? _activeConversationId;
    if (targetConversationId == null) {
      return;
    }

    final wasActiveConversation = targetConversationId == _activeConversationId;
    final hasConversationState =
        _messageCache.containsKey(targetConversationId) ||
        state.conversationId == targetConversationId;

    if (!wasActiveConversation && !hasConversationState) {
      return;
    }

    if (wasActiveConversation) {
      await _stopTyping(
        sendStop: _socketService.status == ChatConnectionStatus.connected,
      );
    } else {
      _cancelTypingTimers();
      _typingActive = false;
    }

    final clearedState = _stateForConversation(targetConversationId).copyWith(
      connectionStatus: ChatConnectionStatus.disconnected,
      connectedUserIds: const [],
      typingUserIds: const [],
      onlineUserIds: const [],
    );
    _cacheConversationState(targetConversationId, clearedState);
    if (state.conversationId == targetConversationId) {
      state = state.copyWith(conversationId: null);
    }
    if (wasActiveConversation) {
      _activeConversationId = null;
      _currentUserId = null;
    }
    await _socketService.disconnect();
  }

  Future<void> pauseLiveSync() async {
    _cancelTypingTimers();
    _typingActive = false;
    await _socketService.pause();
  }

  Future<void> resumeLiveSync() async {
    await _socketService.resume();
  }

  Future<void> refreshConnectionWithToken(String? accessToken) async {
    final conversationId = _activeConversationId;
    if (conversationId == null) {
      return;
    }
    if (accessToken == null || accessToken.isEmpty) {
      await _socketService.disconnect();
      return;
    }
    await _socketService.connect(
      conversationId: conversationId,
      token: accessToken,
    );
  }

  Future<void> refreshTranslationLocale() async {
    final conversationId = _activeConversationId;
    if (conversationId == null) {
      return;
    }

    final accessToken = await _resolveLiveAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      await _socketService.disconnect();
      return;
    }

    await _socketService.connect(
      conversationId: conversationId,
      token: accessToken,
    );
    await load(conversationId, forceRefresh: true);
  }

  Future<void> sendTyping({
    required bool isTyping,
    required bool hasText,
  }) async {
    if (_activeConversationId == null) {
      return;
    }

    if (!isTyping || !hasText) {
      await _stopTyping(
        sendStop: _socketService.status == ChatConnectionStatus.connected,
      );
      return;
    }

    if (_socketService.status != ChatConnectionStatus.connected) {
      return;
    }

    if (!_typingActive) {
      _typingActive = true;
      await _socketService.sendJson(const TypingStartSocketRequest().toJson());
    }

    _typingRefreshTimer ??= Timer.periodic(_typingRefreshInterval, (_) {
      _socketService.sendJson(const TypingSocketRequest().toJson());
    });
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(_typingIdleStopDelay, () {
      unawaited(_stopTyping(sendStop: true));
    });
  }

  Future<void> sendSeenIfNeeded() async {
    final conversationId = _activeConversationId;
    final currentUserId = _currentUserId;
    if (conversationId == null ||
        currentUserId == null ||
        _socketService.status != ChatConnectionStatus.connected) {
      return;
    }

    final conversationState = _stateForConversation(conversationId);
    final latestIncomingMessage = conversationState.messages
        .where((message) => message.sender.id != currentUserId)
        .fold<MessageModel?>(null, (latest, message) {
          final messageTime =
              message.serverTimestamp ?? message.clientTimestamp;
          final latestTime = latest?.serverTimestamp ?? latest?.clientTimestamp;
          if (latest == null) {
            return message;
          }
          if ((messageTime ?? DateTime.fromMillisecondsSinceEpoch(0)).isAfter(
            latestTime ?? DateTime.fromMillisecondsSinceEpoch(0),
          )) {
            return message;
          }
          return latest;
        });
    if (latestIncomingMessage == null) {
      return;
    }

    final latestSeenAt = conversationState.lastSeenByUserId[currentUserId];
    final messageTime =
        latestIncomingMessage.serverTimestamp ??
        latestIncomingMessage.clientTimestamp;
    if (messageTime == null) {
      return;
    }
    if (latestSeenAt != null && !messageTime.isAfter(latestSeenAt)) {
      return;
    }

    final lastMarkedAt = _pendingSeenMarkers[conversationId];
    if (lastMarkedAt != null && !messageTime.isAfter(lastMarkedAt)) {
      return;
    }

    _pendingSeenMarkers[conversationId] = messageTime;
    await _socketService.sendJson(const SeenSocketRequest().toJson());
  }

  Future<bool> send({
    required MessageCreateRequest request,
    required UserBrief sender,
    PartRequestBrief? optimisticProduct,
    MessageReplyModel? optimisticReply,
  }) async {
    final tempId = _nextTempMessageId();
    final optimisticAttachments = <MessageAttachmentModel>[
      for (var index = 0; index < request.attachments.length; index += 1)
        request.attachments[index].toOptimisticAttachment(
          id: tempId - index - 1,
        ),
    ];
    final optimisticMessage = MessageModel.optimistic(
      tempId: tempId,
      conversationId: request.conversation,
      sender: sender,
      messageType: request.messageType,
      text: request.text?.trim() ?? '',
      clientTimestamp: request.clientTimestamp,
      localMessageId: 'local-$tempId',
      product: optimisticProduct,
      replyTo: optimisticReply,
      media: optimisticAttachments,
    );
    final baseState = _stateForConversation(request.conversation);
    final queuedState = baseState.copyWith(
      conversationId: request.conversation,
      isLoading: false,
      isLoadingMore: false,
      pendingMessageCount: baseState.pendingMessageCount + 1,
      messages: _sortMessages([...baseState.messages, optimisticMessage]),
      errorMessage: null,
    );
    _cacheConversationState(request.conversation, queuedState);
    _notifyConversationPreviewChanged(
      conversationId: request.conversation,
      message: optimisticMessage,
      isActiveConversation: request.conversation == _activeConversationId,
    );
    try {
      final createdMessage = await _chatApi.createMessage(request);
      final currentState = _stateForConversation(request.conversation);
      final mergedState = _mergeIncomingMessage(
        currentState.copyWith(
          pendingMessageCount: _decrementPendingCount(currentState),
          errorMessage: null,
        ),
        createdMessage,
      );
      _cacheConversationState(request.conversation, mergedState);
      _notifyConversationPreviewChanged(
        conversationId: request.conversation,
        message: createdMessage,
        isActiveConversation: request.conversation == _activeConversationId,
      );
      await sendSeenIfNeeded();
      return true;
    } on ApiException catch (error) {
      debugPrint(
        '[Chat][Messages][Send][conversation=${request.conversation}] ${error.message}',
      );
      final currentState = _stateForConversation(request.conversation);
      final failedMessage = optimisticMessage.copyWith(
        isOptimistic: false,
        hasSendError: true,
      );
      final nextState = currentState.copyWith(
        pendingMessageCount: _decrementPendingCount(currentState),
        messages: [
          for (final message in currentState.messages)
            if (message.id == tempId) failedMessage else message,
        ],
        errorMessage: error.message,
      );
      _cacheConversationState(request.conversation, nextState);
      _notifyConversationPreviewChanged(
        conversationId: request.conversation,
        message: failedMessage,
        isActiveConversation: request.conversation == _activeConversationId,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[Chat][Messages][Send][conversation=${request.conversation}][Unexpected] ${error.toString()}',
      );
      debugPrintStack(stackTrace: stackTrace);
      final currentState = _stateForConversation(request.conversation);
      final failedMessage = optimisticMessage.copyWith(
        isOptimistic: false,
        hasSendError: true,
      );
      final nextState = currentState.copyWith(
        pendingMessageCount: _decrementPendingCount(currentState),
        messages: [
          for (final message in currentState.messages)
            if (message.id == tempId) failedMessage else message,
        ],
        errorMessage: error.toString(),
      );
      _cacheConversationState(request.conversation, nextState);
      _notifyConversationPreviewChanged(
        conversationId: request.conversation,
        message: failedMessage,
        isActiveConversation: request.conversation == _activeConversationId,
      );
    }

    return false;
  }

  Future<MessageModel?> editMessage({
    required MessageModel message,
    required String text,
  }) async {
    if (message.id <= 0 || message.isOptimistic) {
      return null;
    }

    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return null;
    }

    try {
      final updatedMessage = await _chatApi.editMessage(
        messageId: message.id,
        text: normalizedText,
      );
      final currentState = _stateForConversation(message.conversationId);
      final nextState = _mergeIncomingMessage(
        currentState.copyWith(errorMessage: null),
        updatedMessage,
      );
      _cacheConversationState(message.conversationId, nextState);
      _syncConversationFromState(message.conversationId);
      return updatedMessage;
    } on ApiException catch (error) {
      debugPrint(
        '[Chat][Messages][Edit][conversation=${message.conversationId}] ${error.message}',
      );
      final currentState = _stateForConversation(message.conversationId);
      _cacheConversationState(
        message.conversationId,
        currentState.copyWith(errorMessage: error.message),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[Chat][Messages][Edit][conversation=${message.conversationId}][Unexpected] ${error.toString()}',
      );
      debugPrintStack(stackTrace: stackTrace);
      final currentState = _stateForConversation(message.conversationId);
      _cacheConversationState(
        message.conversationId,
        currentState.copyWith(errorMessage: error.toString()),
      );
    }

    return null;
  }

  Future<bool> deleteMessage({
    required MessageModel message,
    required String scope,
  }) async {
    if (message.id <= 0 || message.isOptimistic) {
      return false;
    }

    try {
      final response = await _chatApi.deleteMessage(
        messageId: message.id,
        scope: scope,
      );
      final currentState = _stateForConversation(message.conversationId);

      if (response.scope == 'all' && response.message != null) {
        final nextState = _mergeIncomingMessage(
          currentState.copyWith(errorMessage: null),
          response.message!,
        );
        _cacheConversationState(message.conversationId, nextState);
      } else {
        final nextMessages = [
          for (final item in currentState.messages)
            if (item.id != message.id) item,
        ];
        _cacheConversationState(
          message.conversationId,
          currentState.copyWith(
            messages: _sortMessages(nextMessages),
            errorMessage: null,
          ),
        );
      }

      _syncConversationFromState(message.conversationId);
      return true;
    } on ApiException catch (error) {
      debugPrint(
        '[Chat][Messages][Delete][conversation=${message.conversationId}] ${error.message}',
      );
      final currentState = _stateForConversation(message.conversationId);
      _cacheConversationState(
        message.conversationId,
        currentState.copyWith(errorMessage: error.message),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[Chat][Messages][Delete][conversation=${message.conversationId}][Unexpected] ${error.toString()}',
      );
      debugPrintStack(stackTrace: stackTrace);
      final currentState = _stateForConversation(message.conversationId);
      _cacheConversationState(
        message.conversationId,
        currentState.copyWith(errorMessage: error.toString()),
      );
    }

    return false;
  }

  void _handleSocketEvent(ChatSocketEvent event) {
    if (_disposed) {
      return;
    }
    switch (event) {
      case ConversationStateSocketEvent():
        _applyRuntimeState(event.state);
      case MessageCreatedSocketEvent():
        _applyIncomingMessage(event.message);
      case ConversationTypingSocketEvent():
        _applyTypingEvent(event);
      case ConversationSeenSocketEvent():
        _applySeenEvent(event);
      case MessageStatusSocketEvent():
        _applyMessageStatus(event.status);
      case UserPresenceSocketEvent():
        _applyUserPresenceEvent(event);
      case ErrorSocketEvent():
        final conversationId = _activeConversationId;
        if (conversationId != null) {
          final currentState = _stateForConversation(
            conversationId,
          ).copyWith(errorMessage: event.detail);
          _cacheConversationState(conversationId, currentState);
        }
      case PongSocketEvent():
      case UnknownSocketEvent():
    }
  }

  void _handleSocketStatus(ChatConnectionStatus status) {
    final conversationId = _activeConversationId;
    if (conversationId == null) {
      return;
    }
    final previousStatus = _stateForConversation(
      conversationId,
    ).connectionStatus;
    final nextState = _stateForConversation(
      conversationId,
    ).copyWith(connectionStatus: status);
    _cacheConversationState(conversationId, nextState);
    if (previousStatus == ChatConnectionStatus.reconnecting &&
        status == ChatConnectionStatus.connected) {
      unawaited(load(conversationId, forceRefresh: true));
    }
    if (status == ChatConnectionStatus.connected) {
      unawaited(sendSeenIfNeeded());
    }
  }

  void _applyRuntimeState(ConversationRuntimeState runtimeState) {
    final conversationId = runtimeState.conversationId;
    if (conversationId != _activeConversationId) {
      return;
    }
    final currentState = _stateForConversation(conversationId).copyWith(
      connectedUserIds: runtimeState.connectedUserIds,
      typingUserIds: runtimeState.typingUserIds,
      onlineUserIds: runtimeState.onlineUserIds,
      presenceLastSeenByUserId: runtimeState.presenceLastSeenAtByUserId,
    );
    _cacheConversationState(conversationId, currentState);
    for (final entry in runtimeState.presenceLastSeenAtByUserId.entries) {
      onUserPresenceChanged?.call(
        userId: entry.key,
        isOnline: runtimeState.onlineUserIds.contains(entry.key),
        lastSeenAt: entry.value,
      );
    }
  }

  void _applyIncomingMessage(MessageModel message) {
    final conversationId = message.conversationId;
    if (conversationId != _activeConversationId) {
      return;
    }
    final currentState = _stateForConversation(conversationId);

    final mergedState = _mergeIncomingMessage(currentState, message);
    _cacheConversationState(conversationId, mergedState);
    _notifyConversationPreviewChanged(
      conversationId: conversationId,
      message: message,
      isActiveConversation: conversationId == _activeConversationId,
    );
    onIncomingMessageReceived?.call(
      message: message,
      isActiveConversation: true,
      currentUserId: _currentUserId ?? 0,
    );
    if (conversationId == _activeConversationId) {
      sendSeenIfNeeded();
    }
  }

  void _applyTypingEvent(ConversationTypingSocketEvent event) {
    final conversationId = event.conversationId;
    if (conversationId != _activeConversationId) {
      return;
    }
    final currentState = _stateForConversation(conversationId);
    final currentTyping = currentState.typingUserIds.toSet();
    if (event.isTyping) {
      currentTyping.add(event.userId);
    } else {
      currentTyping.remove(event.userId);
    }
    final nextState = currentState.copyWith(
      typingUserIds: currentTyping.toList()..sort(),
    );
    _cacheConversationState(conversationId, nextState);
  }

  void _applySeenEvent(ConversationSeenSocketEvent event) {
    final conversationId = event.conversationId;
    if (conversationId != _activeConversationId) {
      return;
    }
    final currentState = _stateForConversation(conversationId);
    final nextSeen = Map<int, DateTime?>.from(currentState.lastSeenByUserId);
    nextSeen[event.userId] = event.seenAt;

    final updatedMessages = [
      for (final message in currentState.messages)
        if (message.sender.id == event.userId)
          message
        else
          _applyStatusToMessage(
            message,
            MessageStatusModel(
              conversationId: conversationId,
              messageId: message.id,
              userId: event.userId,
              status: 'seen',
              updatedAt: event.seenAt,
            ),
          ),
    ];

    final nextState = currentState.copyWith(
      messages: _sortMessages(updatedMessages),
      lastSeenByUserId: nextSeen,
    );
    _cacheConversationState(conversationId, nextState);
    if (event.userId == _currentUserId) {
      onConversationReadChanged?.call(conversationId);
    }
  }

  void _applyMessageStatus(MessageStatusModel status) {
    final conversationId = status.conversationId;
    if (conversationId != _activeConversationId) {
      return;
    }
    final currentState = _stateForConversation(conversationId);
    final updatedMessages = [
      for (final message in currentState.messages)
        if (message.id == status.messageId)
          _applyStatusToMessage(message, status)
        else
          message,
    ];
    final nextState = currentState.copyWith(
      messages: _sortMessages(updatedMessages),
    );
    _cacheConversationState(conversationId, nextState);
  }

  void _applyUserPresenceEvent(UserPresenceSocketEvent event) {
    final conversationId = _activeConversationId;
    if (conversationId == null) {
      return;
    }

    final currentState = _stateForConversation(conversationId);
    final onlineUserIds = currentState.onlineUserIds.toSet();
    if (event.isOnline) {
      onlineUserIds.add(event.userId);
    } else {
      onlineUserIds.remove(event.userId);
    }

    final presenceLastSeen = Map<int, DateTime?>.from(
      currentState.presenceLastSeenByUserId,
    );
    presenceLastSeen[event.userId] = event.lastSeenAt;

    final nextState = currentState.copyWith(
      onlineUserIds: onlineUserIds.toList()..sort(),
      presenceLastSeenByUserId: presenceLastSeen,
    );
    _cacheConversationState(conversationId, nextState);
    onUserPresenceChanged?.call(
      userId: event.userId,
      isOnline: event.isOnline,
      lastSeenAt: event.lastSeenAt,
    );
  }

  MessageModel _applyStatusToMessage(
    MessageModel message,
    MessageStatusModel status,
  ) {
    final statuses = [...message.statuses];
    final existingIndex = statuses.indexWhere(
      (item) =>
          item.userId == status.userId && item.messageId == status.messageId,
    );
    if (existingIndex == -1) {
      statuses.add(status);
    } else {
      statuses[existingIndex] = status;
    }
    return message.copyWith(
      statuses: statuses,
      isOptimistic: false,
      hasSendError: false,
    );
  }

  MessageState _mergeIncomingMessage(
    MessageState baseState,
    MessageModel incoming,
  ) {
    final messages = [...baseState.messages];
    final exactIndex = messages.indexWhere(
      (message) => message.id == incoming.id,
    );
    if (exactIndex != -1) {
      _debugAttachmentPreservation(
        previous: messages[exactIndex],
        replacement: incoming,
        reason: 'incoming-exact-id',
      );
      messages[exactIndex] = _preserveKnownAttachments(
        previous: messages[exactIndex],
        replacement: incoming,
      ).copyWith(isOptimistic: false, hasSendError: false);
      return baseState.copyWith(messages: _sortMessages(messages));
    }

    final optimisticIndex = messages.indexWhere(
      (message) =>
          message.isOptimistic && _matchesOptimisticMessage(message, incoming),
    );
    if (optimisticIndex != -1) {
      _debugAttachmentPreservation(
        previous: messages[optimisticIndex],
        replacement: incoming,
        reason: 'incoming-optimistic-match',
      );
      messages[optimisticIndex] = _preserveKnownAttachments(
        previous: messages[optimisticIndex],
        replacement: incoming,
      ).copyWith(localMessageId: messages[optimisticIndex].localMessageId);
      return baseState.copyWith(messages: _sortMessages(messages));
    }

    messages.add(incoming);

    return baseState.copyWith(messages: _sortMessages(messages));
  }

  List<MessageModel> _mergeLoadedMessages({
    required List<MessageModel> currentMessages,
    required List<MessageModel> loadedMessages,
    required int conversationId,
  }) {
    final mergedById = <int, MessageModel>{
      for (final message in currentMessages) message.id: message,
    };
    for (final loaded in loadedMessages) {
      final previous = mergedById[loaded.id];
      if (previous != null) {
        _debugAttachmentPreservation(
          previous: previous,
          replacement: loaded,
          reason: 'rest-snapshot',
        );
      }
      mergedById[loaded.id] =
          _preserveKnownAttachments(
            previous: previous,
            replacement: loaded,
          ).copyWith(
            localMessageId: previous?.localMessageId,
            isOptimistic: false,
            hasSendError: false,
          );
    }
    final merged = _sortMessages(mergedById.values.toList());


    return merged;
  }

  int _audioAttachmentCount(Iterable<MessageModel> messages) => messages
      .expand((message) => message.media)
      .where((attachment) => attachment.isAudio)
      .length;

  MessageModel _preserveKnownAttachments({
    MessageModel? previous,
    required MessageModel replacement,
  }) {
    if (previous == null ||
        previous.media.isEmpty ||
        replacement.media.isNotEmpty) {
      return replacement;
    }

    return replacement.copyWith(media: previous.media);
  }

  void _debugAttachmentPreservation({
    required MessageModel previous,
    required MessageModel replacement,
    required String reason,
  }) {
    final previousAudio = _audioAttachmentCount([previous]);
    final replacementAudio = _audioAttachmentCount([replacement]);
    if (previousAudio > 0 || replacementAudio > 0) {

    }
  }

  bool _matchesOptimisticMessage(
    MessageModel optimistic,
    MessageModel incoming,
  ) {
    if (optimistic.conversationId != incoming.conversationId ||
        optimistic.sender.id != incoming.sender.id ||
        optimistic.messageType != incoming.messageType) {
      return false;
    }

    final optimisticTime = optimistic.clientTimestamp;
    final incomingTime = incoming.clientTimestamp;
    if (optimisticTime == null || incomingTime == null) {
      return false;
    }

    final diff = optimisticTime.difference(incomingTime).inSeconds.abs();
    if (diff > 8) {
      return false;
    }

    if (incoming.messageType == 'media') {
      return optimistic.media.length == incoming.media.length;
    }

    return optimistic.text.trim() == incoming.text.trim();
  }

  List<MessageModel> _sortMessages(List<MessageModel> messages) {
    final deduped = <MessageModel>[];
    final ids = <int>{};
    for (final message in messages) {
      if (message.id > 0 && ids.contains(message.id)) {
        continue;
      }
      if (message.id > 0) {
        ids.add(message.id);
      }
      deduped.add(message);
    }
    deduped.sort((left, right) {
      final leftTime = left.clientTimestamp ?? left.serverTimestamp;
      final rightTime = right.clientTimestamp ?? right.serverTimestamp;
      final timeCompare = (leftTime ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(rightTime ?? DateTime.fromMillisecondsSinceEpoch(0));
      if (timeCompare != 0) {
        return timeCompare;
      }
      final serverCompare =
          (left.serverTimestamp ??
                  leftTime ??
                  DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                right.serverTimestamp ??
                    rightTime ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              );
      if (serverCompare != 0) {
        return serverCompare;
      }
      return left.id.compareTo(right.id);
    });
    return deduped;
  }

  MessageState _stateForConversation(int conversationId) {
    return _messageCache[conversationId] ??
        (state.conversationId == conversationId
            ? state
            : MessageState(conversationId: conversationId));
  }

  void _cacheConversationState(int conversationId, MessageState nextState) {
    final normalizedState = nextState.copyWith(conversationId: conversationId);
    _messageCache[conversationId] = normalizedState;
    if (conversationId == _activeConversationId ||
        state.conversationId == conversationId) {
      state = normalizedState;
    }
    unawaited(_persistConversationState(conversationId, normalizedState));
  }

  int _nextTempMessageId() {
    _tempMessageSeed -= 1;
    return _tempMessageSeed;
  }

  int _decrementPendingCount(MessageState conversationState) {
    if (conversationState.pendingMessageCount <= 0) {
      return 0;
    }
    return conversationState.pendingMessageCount - 1;
  }

  void _notifyConversationPreviewChanged({
    required int conversationId,
    required MessageModel message,
    required bool isActiveConversation,
  }) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }
    onMessagePreviewChanged?.call(
      conversationId: conversationId,
      message: message,
      isActiveConversation: isActiveConversation,
      currentUserId: currentUserId,
    );
  }

  void _syncConversationFromState(int conversationId) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }

    final conversationState = _stateForConversation(conversationId);
    onConversationMessagesChanged?.call(
      conversationId: conversationId,
      messages: conversationState.messages,
      isActiveConversation: conversationId == _activeConversationId,
      currentUserId: currentUserId,
    );
  }

  void _cancelTypingTimers() {
    _typingRefreshTimer?.cancel();
    _typingRefreshTimer = null;
    _typingStopTimer?.cancel();
    _typingStopTimer = null;
  }

  Future<void> _stopTyping({required bool sendStop}) async {
    _cancelTypingTimers();
    final wasTyping = _typingActive;
    _typingActive = false;
    if (wasTyping && sendStop) {
      await _socketService.sendJson(const TypingStopSocketRequest().toJson());
    }
  }

  MessageState? _restorePersistedConversationState(int conversationId) {
    final currentUserId = _resolveCacheUserId();
    if (currentUserId == null) {
      return null;
    }

    final restoredState = _cacheStore.readConversationState(
      userId: currentUserId,
      conversationId: conversationId,
    );
    if (restoredState != null) {
      _messageCache[conversationId] = restoredState;
    }
    return restoredState;
  }

  Future<void> _persistConversationState(
    int conversationId,
    MessageState stateToPersist,
  ) async {
    final currentUserId = _resolveCacheUserId();
    if (currentUserId == null) {
      return;
    }

    await _cacheStore.writeConversationState(
      userId: currentUserId,
      conversationId: conversationId,
      state: stateToPersist,
    );
  }
}
