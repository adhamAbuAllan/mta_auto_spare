import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/chat_api.dart';
import '../../../api/chat_socket_service.dart';
import '../../../api/inbox_socket_service.dart';
import '../../../models/models.dart';
import '../../../session/session_state.dart';
import '../../statuses/conversation_state.dart';

class LoadConversationsNotifier extends StateNotifier<ConversationState> {
  LoadConversationsNotifier(this._chatApi, this._inboxSocketService)
    : super(const ConversationState()) {
    _inboxMessageSubscription = _inboxSocketService.messages.listen(
      _handleInboxMessage,
    );
    _inboxStatusSubscription = _inboxSocketService.statuses.listen(
      _handleInboxStatus,
    );
  }

  final ChatApi _chatApi;
  final InboxSocketService _inboxSocketService;
  StreamSubscription<MessageModel>? _inboxMessageSubscription;
  StreamSubscription<ChatConnectionStatus>? _inboxStatusSubscription;
  ChatConnectionStatus _inboxStatus = ChatConnectionStatus.disconnected;
  int? _currentUserId;
  int? _activeConversationId;
  // Inbox delivery is at-least-once, so reconnects can replay a message that
  // has already updated this list. Keep a small in-memory record per chat to
  // avoid treating that replay as another unread message.
  final Map<int, Set<int>> _handledInboxMessageIds = {};
  static const int _maxHandledInboxMessageIdsPerConversation = 200;

  @override
  void dispose() {
    _inboxMessageSubscription?.cancel();
    _inboxStatusSubscription?.cancel();
    unawaited(_inboxSocketService.disconnect());
    super.dispose();
  }

  Future<void> syncWithSession(SessionState session) async {
    _currentUserId = session.profile?.id;
    final accessToken = session.accessToken?.trim() ?? '';
    if (!session.isAuthenticated ||
        _currentUserId == null ||
        accessToken.isEmpty) {
      await _inboxSocketService.disconnect();
      return;
    }

    await _inboxSocketService.connect(token: accessToken);
  }

  Future<void> refreshTranslationLocale(SessionState session) async {
    await syncWithSession(session);
    if (state.conversations.isEmpty && !state.isLoading) {
      return;
    }
    await load(forceRefresh: true);
  }

  void setActiveConversationId(int? conversationId) {
    _activeConversationId = conversationId;
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh && state.conversations.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      nextPageUrl: null,
      conversations: forceRefresh ? state.conversations : const [],
    );

    try {
      final page = await _chatApi.getConversations();
      state = state.copyWith(
        isLoading: false,
        conversations: _sortConversationsByActivity(page.results),
        nextPageUrl: page.next,
        errorMessage: null,
      );
      _rememberConversationPreviews(page.results);
    } on ApiException catch (error) {
      debugPrint('[Chat][Conversations][Load] ${error.message}');
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      debugPrint('[Chat][Conversations][Load][Unexpected] ${error.toString()}');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final page = await _chatApi.getConversations(pageUrl: state.nextPageUrl);
      state = state.copyWith(
        isLoadingMore: false,
        conversations: _sortConversationsByActivity([
          ...state.conversations,
          ...page.results,
        ]),
        nextPageUrl: page.next,
        errorMessage: null,
      );
      _rememberConversationPreviews(page.results);
    } on ApiException catch (error) {
      debugPrint('[Chat][Conversations][LoadMore] ${error.message}');
      state = state.copyWith(isLoadingMore: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      debugPrint(
        '[Chat][Conversations][LoadMore][Unexpected] ${error.toString()}',
      );
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  void touchConversationFromMessage({
    required int conversationId,
    required MessageModel message,
    required int currentUserId,
    bool isActiveConversation = false,
  }) {
    final index = state.conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index == -1) {
      unawaited(load(forceRefresh: true));
      return;
    }

    final currentConversation = state.conversations[index];
    if (_wasInboxMessageHandled(message)) {
      return;
    }
    _rememberInboxMessage(message);
    final nextUnreadCount =
        isActiveConversation || message.sender.id == currentUserId
        ? 0
        : currentConversation.unreadCount + 1;
    final nextLastMessage =
        _shouldReplaceConversationPreview(
          currentConversation.lastMessage,
          message,
        )
        ? _buildLastMessagePreview(message)
        : currentConversation.lastMessage;
    final updatedConversation = currentConversation.copyWith(
      lastMessage: nextLastMessage,
      unreadCount: nextUnreadCount,
    );

    final updatedList = [...state.conversations];
    updatedList[index] = updatedConversation;

    state = state.copyWith(
      conversations: _sortConversationsByActivity(updatedList),
    );
  }

  void syncConversationFromMessages({
    required int conversationId,
    required List<MessageModel> messages,
    required int currentUserId,
    bool isActiveConversation = false,
  }) {
    final index = state.conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index == -1) {
      unawaited(load(forceRefresh: true));
      return;
    }

    final currentConversation = state.conversations[index];
    final latestMessage = messages.isEmpty ? null : messages.last;
    final updatedConversation = currentConversation.copyWith(
      lastMessage: latestMessage == null
          ? null
          : _buildLastMessagePreview(latestMessage),
      unreadCount: isActiveConversation ? 0 : currentConversation.unreadCount,
    );

    final updatedList = [...state.conversations];
    updatedList[index] = updatedConversation;
    state = state.copyWith(
      conversations: _sortConversationsByActivity(updatedList),
    );
  }

  ConversationLastMessagePreview _buildLastMessagePreview(
    MessageModel message,
  ) {
    return ConversationLastMessagePreview(
      id: message.id,
      messageType: message.messageType,
      text: _buildPreviewText(message),
      translatedText: message.translatedText,
      textLanguage: message.textLanguage,
      senderId: message.sender.id,
      senderName: message.sender.name,
      product: message.product,
      translationTargetLanguage: message.translationTargetLanguage,
      timestamp: _messageActivityAt(message),
      editedAt: message.editedAt,
      isDeleted: message.isDeleted,
      statuses: message.statuses,
      isOptimistic: message.isOptimistic,
      hasSendError: message.hasSendError,
    );
  }

  String _buildPreviewText(MessageModel message) {
    if (message.isDeleted) {
      return 'This message was deleted';
    }

    final trimmedText = message.displayText.trim();
    if (trimmedText.isNotEmpty) {
      return trimmedText;
    }

    switch (message.messageType) {
      case 'product':
        final title = message.product?.displayTitle.trim();
        if (title != null && title.isNotEmpty) {
          return 'Shared request: $title';
        }
        return 'Shared a request';
      case 'media':
        if (message.media.length > 1) {
          if (message.media.every((attachment) => attachment.isAudio)) {
            return 'Sent ${message.media.length} voice messages';
          }
          return 'Sent ${message.media.length} attachments';
        }
        if (message.media.any((attachment) => attachment.isAudio)) {
          return 'Sent a voice message';
        }
        if (message.media.any((attachment) => attachment.isImage)) {
          return 'Sent an image';
        }
        return 'Sent an attachment';
      default:
        return 'New message';
    }
  }

  bool _shouldReplaceConversationPreview(
    ConversationLastMessagePreview? currentPreview,
    MessageModel incomingMessage,
  ) {
    if (currentPreview == null || currentPreview.id == incomingMessage.id) {
      return true;
    }

    return _compareActivity(
          leftTimestamp: _messageActivityAt(incomingMessage),
          leftId: incomingMessage.id,
          rightTimestamp: currentPreview.timestamp,
          rightId: currentPreview.id,
        ) >
        0;
  }

  List<ConversationListItem> _sortConversationsByActivity(
    List<ConversationListItem> conversations,
  ) {
    final sorted = [...conversations];
    sorted.sort((left, right) {
      return _compareActivity(
        leftTimestamp: right.lastMessage?.timestamp,
        leftId: right.lastMessage?.id ?? right.id,
        rightTimestamp: left.lastMessage?.timestamp,
        rightId: left.lastMessage?.id ?? left.id,
      );
    });
    return sorted;
  }

  DateTime? _messageActivityAt(MessageModel message) {
    return message.serverTimestamp ?? message.clientTimestamp;
  }

  int _compareActivity({
    required DateTime? leftTimestamp,
    required int leftId,
    required DateTime? rightTimestamp,
    required int rightId,
  }) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final timestampCompare = (leftTimestamp ?? epoch).compareTo(
      rightTimestamp ?? epoch,
    );
    if (timestampCompare != 0) {
      return timestampCompare;
    }
    return leftId.compareTo(rightId);
  }

  void markConversationRead(int conversationId) {
    final index = state.conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index == -1) {
      return;
    }
    final updatedList = [...state.conversations];
    updatedList[index] = updatedList[index].copyWith(unreadCount: 0);
    state = state.copyWith(conversations: updatedList);
  }

  void updateUserPresence({
    required int userId,
    required bool isOnline,
    DateTime? lastSeenAt,
  }) {
    var didChange = false;
    final updatedConversations = state.conversations
        .map((conversation) {
          final participants = conversation.participants
              .map((participant) {
                if (participant.user.id != userId) {
                  return participant;
                }
                didChange = true;
                return participant.copyWith(
                  user: participant.user.copyWith(
                    isOnline: isOnline,
                    lastSeenAt: lastSeenAt,
                  ),
                );
              })
              .toList(growable: false);
          return conversation.copyWith(participants: participants);
        })
        .toList(growable: false);

    if (!didChange) {
      return;
    }

    state = state.copyWith(
      conversations: _sortConversationsByActivity(updatedConversations),
    );
  }

  void _handleInboxMessage(MessageModel message) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }

    touchConversationFromMessage(
      conversationId: message.conversationId,
      message: message,
      currentUserId: currentUserId,
      isActiveConversation: _activeConversationId == message.conversationId,
    );
  }

  bool _wasInboxMessageHandled(MessageModel message) {
    final handledIds = _handledInboxMessageIds[message.conversationId];
    if (handledIds?.contains(message.id) == true) {
      return true;
    }

    final conversation = state.conversations
        .where((item) => item.id == message.conversationId)
        .firstOrNull;
    return conversation?.lastMessage?.id == message.id;
  }

  void _rememberConversationPreviews(List<ConversationListItem> conversations) {
    for (final conversation in conversations) {
      final messageId = conversation.lastMessage?.id;
      if (messageId != null) {
        _rememberInboxMessageId(conversation.id, messageId);
      }
    }
  }

  void _rememberInboxMessage(MessageModel message) {
    _rememberInboxMessageId(message.conversationId, message.id);
  }

  void _rememberInboxMessageId(int conversationId, int messageId) {
    final handledIds = _handledInboxMessageIds.putIfAbsent(
      conversationId,
      () => <int>{},
    );
    handledIds.add(messageId);
    if (handledIds.length > _maxHandledInboxMessageIdsPerConversation) {
      handledIds.remove(handledIds.first);
    }
  }

  void _handleInboxStatus(ChatConnectionStatus status) {
    final previousStatus = _inboxStatus;
    _inboxStatus = status;
    if (previousStatus == ChatConnectionStatus.reconnecting &&
        status == ChatConnectionStatus.connected &&
        state.conversations.isNotEmpty) {
      unawaited(load(forceRefresh: true));
    }
  }
}
