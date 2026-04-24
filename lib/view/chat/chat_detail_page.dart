import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../api/api_exception.dart';
import '../../api/chat_socket_service.dart';
import '../../controllers/methods/api_methods/load_conversations_notifier.dart';
import '../../controllers/methods/api_methods/load_messages_notifier.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/message_state.dart';
import '../../localization/app_localizations_x.dart';
import '../../models/models.dart';
import '../../session/session_state.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/empty_state_card.dart';
import '../common_widgets/user_avatar.dart';
import '../profile/user_profile_page.dart';
import 'chat_formatters.dart';
import 'widgets/message_bubble.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.conversationId,
    this.onBack,
    this.wideMode = false,
  });

  final int conversationId;
  final VoidCallback? onBack;
  final bool wideMode;

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  late final LoadConversationsNotifier _conversationsNotifier;
  late final LoadMessagesNotifier _messagesNotifier;

  List<ChatUploadImage> _selectedImages = const [];
  MessageModel? _replyTarget;
  PartRequestBrief? _selectedProduct;
  int _lastKnownMessageCount = 0;
  double _lastKeyboardInset = 0;
  bool _lastKnownOtherTyping = false;
  int _conversationLoadCycle = 0;
  MessageState _messageState = const MessageState(isLoading: true);
  ProviderSubscription<MessageState>? _messageSubscription;
  ProviderSubscription<SessionState>? _sessionSubscription;
  Timer? _voiceRecordingTicker;
  DateTime? _voiceRecordingStartedAt;
  Duration _voiceRecordingDuration = Duration.zero;
  bool _isVoiceRecording = false;
  bool _isVoiceRecorderBusy = false;
  int? _selectedSharedRequestId;
  bool _isRequestAccessPanelExpanded = true;
  bool _isLoadingSharedRequestState = false;
  bool _isUpdatingSharedRequestState = false;
  final Map<int, PartRequest> _sharedRequestsById = {};
  final Map<int, List<PartRequestAccess>> _sharedAccessesByRequestId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_handleComposerChanged);
    _composerFocusNode.addListener(_handleComposerChanged);
    _conversationsNotifier = ref.read(conversationsNotifierProvider.notifier);
    _messagesNotifier = ref.read(messagesNotifierProvider.notifier);
    _messageState = _resolveDisplayedMessageState(
      ref.read(messagesNotifierProvider),
    );
    _messageSubscription = ref.listenManual<MessageState>(
      messagesNotifierProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        final displayedState = _resolveDisplayedMessageState(next);
        setState(() {
          _messageState = displayedState;
        });
        unawaited(_refreshSharedRequestContext(displayedState.messages));
      },
    );
    _sessionSubscription = ref.listenManual<SessionState>(
      currentSessionProvider,
      (previous, next) {
        if (previous?.accessToken != next.accessToken) {
          _messagesNotifier.refreshConnectionWithToken(next.accessToken);
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final pendingProduct = ref.read(pendingSharedProductProvider);
      if (pendingProduct != null) {
        setState(() => _selectedProduct = pendingProduct);
        ref.read(pendingSharedProductProvider.notifier).state = null;
      }
      await _startConversationSession(forceRefresh: true);
    });
  }

  @override
  void didUpdateWidget(covariant ChatDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }

        await _cancelVoiceRecording(silent: true);
        setState(() {
          _selectedImages = const [];
          _replyTarget = null;
          _selectedProduct = null;
          _selectedSharedRequestId = null;
          _isRequestAccessPanelExpanded = true;
          _sharedRequestsById.clear();
          _sharedAccessesByRequestId.clear();
          _isLoadingSharedRequestState = false;
          _isUpdatingSharedRequestState = false;
          _messageState = _resolveDisplayedMessageState(
            ref.read(messagesNotifierProvider),
          );
        });
        await _startConversationSession(
          forceRefresh: true,
          previousConversationId: oldWidget.conversationId,
        );
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_cancelVoiceRecording(silent: true));
      _messagesNotifier.pauseLiveSync();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _messagesNotifier.resumeLiveSync();
      _messagesNotifier.sendSeenIfNeeded();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) {
      return;
    }
    final view = View.of(context);
    final nextKeyboardInset = view.viewInsets.bottom / view.devicePixelRatio;
    final keyboardChanged = (_lastKeyboardInset - nextKeyboardInset).abs() > 1;
    _lastKeyboardInset = nextKeyboardInset;

    if (!keyboardChanged) {
      return;
    }
    if (_composerFocusNode.hasFocus || nextKeyboardInset > 0) {
      _keepLatestMessageVisible();
    }
  }

  @override
  void dispose() {
    final conversationId = widget.conversationId;
    _conversationLoadCycle += 1;
    WidgetsBinding.instance.removeObserver(this);
    _voiceRecordingTicker?.cancel();
    _voiceRecordingTicker = null;
    _messageSubscription?.close();
    _messageSubscription = null;
    _sessionSubscription?.close();
    _sessionSubscription = null;
    _messageController.removeListener(_handleComposerChanged);
    _composerFocusNode.removeListener(_handleComposerChanged);
    _composerFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    unawaited(_audioRecorder.cancel());
    unawaited(_audioRecorder.dispose());
    unawaited(_messagesNotifier.detachConversation(conversationId));

    super.dispose();

    unawaited(
      Future<void>.microtask(() async {
        if (_conversationsNotifier.mounted) {
          _conversationsNotifier.setActiveConversationId(null);
        }
        if (_messagesNotifier.mounted) {
          await _messagesNotifier.deactivateConversation(conversationId);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider) ?? 0;
    final messageState = _messageState.conversationId == widget.conversationId
        ? _messageState
        : _resolveDisplayedMessageState(_messageState);

    if (_lastKnownMessageCount != messageState.messages.length) {
      _lastKnownMessageCount = messageState.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _keepLatestMessageVisible();
        _messagesNotifier.sendSeenIfNeeded();
      });
    }

    ConversationListItem? conversation;
    for (final item in conversationsState.conversations) {
      if (item.id == widget.conversationId) {
        conversation = item;
        break;
      }
    }

    final title = conversation == null
        ? context.l10n.conversationNumber(widget.conversationId)
        : conversationDisplayName(conversation, currentUserId, context.l10n);
    final participant = conversation == null
        ? null
        : otherParticipant(conversation, currentUserId);
    final otherUserId = participant?.user.id;
    final isOtherOnline =
        otherUserId != null &&
        (messageState.onlineUserIds.contains(otherUserId) ||
            participant?.user.isOnline == true);
    final isOtherTyping =
        otherUserId != null && messageState.typingUserIds.contains(otherUserId);
    final otherLastSeenAt = otherUserId == null
        ? null
        : messageState.presenceLastSeenByUserId[otherUserId] ??
              participant?.user.lastSeenAt;
    final presenceColor = participant == null
        ? null
        : isOtherOnline
        ? const Color(0xFF20A05A)
        : const Color(0xFFB9B2A8);
    final sharedProducts = _sharedProductsFromMessages(messageState.messages);
    final selectedSharedRequestId =
        sharedProducts.any((product) => product.id == _selectedSharedRequestId)
        ? _selectedSharedRequestId
        : sharedProducts.isEmpty
        ? null
        : sharedProducts.first.id;
    final selectedSharedProduct = selectedSharedRequestId == null
        ? null
        : sharedProducts.firstWhere(
            (product) => product.id == selectedSharedRequestId,
          );
    final selectedSharedRequest = selectedSharedRequestId == null
        ? null
        : _sharedRequestsById[selectedSharedRequestId];
    final selectedSharedAccesses = selectedSharedRequestId == null
        ? const <PartRequestAccess>[]
        : _sharedAccessesByRequestId[selectedSharedRequestId] ?? const [];

    if (_lastKnownOtherTyping != isOtherTyping) {
      _lastKnownOtherTyping = isOtherTyping;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _keepLatestMessageVisible();
      });
    }

    final content = Column(
      children: [
        _ChatHeader(
          title: title,
          connectionStatus: messageState.connectionStatus,
          statusLabel: isOtherTyping
              ? context.l10n.typing
              : conversationPresenceLabel(
                  isOnline: isOtherOnline,
                  lastSeenAt: otherLastSeenAt,
                  l10n: context.l10n,
                ),
          onBack: widget.onBack,
          showBack: widget.onBack != null || !widget.wideMode,
          avatarName: title,
          avatarUrl: participant?.user.avatar,
          presenceColor: presenceColor,
          onProfileTap: otherUserId == null
              ? null
              : () => _openUserProfile(otherUserId),
        ),
        const SizedBox(height: 16),
        if (selectedSharedProduct != null) ...[
          _RequestAccessPanel(
            sharedProducts: sharedProducts,
            selectedProductId: selectedSharedRequestId,
            selectedProduct: selectedSharedProduct,
            selectedRequest: selectedSharedRequest,
            accesses: selectedSharedAccesses,
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            isLoading: _isLoadingSharedRequestState,
            isUpdating: _isUpdatingSharedRequestState,
            isExpanded: _isRequestAccessPanelExpanded,
            onToggleExpanded: () {
              setState(() {
                _isRequestAccessPanelExpanded = !_isRequestAccessPanelExpanded;
              });
            },
            onSelectProduct: _selectSharedRequest,
            onRequestAccess: () =>
                _requestManagementAccess(selectedSharedProduct.id),
            onApproveAccess: _approveSharedAccess,
            onRejectAccess: _rejectSharedAccess,
          ),
          const SizedBox(height: 14),
        ],
        Expanded(
          child: _buildMessagesBody(
            context,
            messageState,
            currentUserId,
            showTypingIndicator: isOtherTyping,
          ),
        ),
        if (messageState.errorMessage != null &&
            messageState.messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppErrorCard(message: messageState.errorMessage!),
          ),
        const SizedBox(height: 14),
        _Composer(
          controller: _messageController,
          focusNode: _composerFocusNode,
          selectedImages: _selectedImages,
          isSending: messageState.isSending,
          isVoiceRecording: _isVoiceRecording,
          isVoiceRecorderBusy: _isVoiceRecorderBusy,
          voiceRecordingDuration: _voiceRecordingDuration,
          replyTarget: _replyTarget,
          selectedProduct: _selectedProduct,
          onPickImages: _pickImages,
          onRemoveImage: _removeSelectedImage,
          onStartVoiceRecording: _startVoiceRecording,
          onCancelVoiceRecording: _cancelVoiceRecording,
          onSendVoiceRecording: _stopAndSendVoiceMessage,
          onCancelReply: () => setState(() => _replyTarget = null),
          onCancelProduct: () => setState(() => _selectedProduct = null),
          onSend: _sendMessage,
        ),
      ],
    );

    if (widget.wideMode) {
      return content;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }

  Widget _buildMessagesBody(
    BuildContext context,
    MessageState messageState,
    int currentUserId, {
    required bool showTypingIndicator,
  }) {
    if (messageState.isLoading && messageState.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messageState.errorMessage != null && messageState.messages.isEmpty) {
      return AppErrorCard(
        message: messageState.errorMessage!,
        onRetry: () => _loadMessages(widget.conversationId, forceRefresh: true),
      );
    }

    if (messageState.messages.isEmpty) {
      return SingleChildScrollView(
        child: EmptyStateCard(
          title: context.l10n.noMessagesYet,
          message: context.l10n.noMessagesYetMessage,
          icon: Icons.forum_outlined,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              0,
              8,
              0,
              //  messageState.hasMore ?
              8,
              //    :
              //   8,
            ),
            itemCount:
                messageState.messages.length + (showTypingIndicator ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messageState.messages.length) {
                return const _TypingIndicatorBubble();
              }
              final message = messageState.messages[index];
              return MessageBubble(
                message: message,
                currentUserId: currentUserId,
                isMine: message.sender.id == currentUserId,
                onReply: () => setState(() => _replyTarget = message),
                onLongPress: () => _openMessageActions(message, currentUserId),
              );
            },
          ),
        ),
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: Padding(
        //     padding: const EdgeInsets.only(bottom: 14),
        //     child: _FloatingLoadMoreButton(
        //       isVisible: messageState.hasMore,
        //       isLoading: messageState.isLoadingMore,
        //       onPressed: messageState.isLoadingMore
        //           ? null
        //           : () {
        //         ref.read(messagesNotifierProvider.notifier).loadMore();
        //         debugPrint("next page url is ${ref.read
        //           (messagesNotifierProvider).nextPageUrl}!!!");
        //       },
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Future<void> _startConversationSession({
    required bool forceRefresh,
    int? previousConversationId,
  }) async {
    final conversationId = widget.conversationId;
    final loadCycle = ++_conversationLoadCycle;

    if (previousConversationId != null &&
        previousConversationId != conversationId) {
      ref
          .read(conversationsNotifierProvider.notifier)
          .setActiveConversationId(null);
      await _messagesNotifier.deactivateConversation(previousConversationId);
      if (!_isConversationLoadCurrent(loadCycle, conversationId)) {
        return;
      }
    }

    await _loadMessages(conversationId, forceRefresh: forceRefresh);
    if (!_isConversationLoadCurrent(loadCycle, conversationId)) {
      return;
    }

    await _activateLiveSync(conversationId);
  }

  Future<void> _loadMessages(
    int conversationId, {
    bool forceRefresh = false,
  }) async {
    await _messagesNotifier.load(conversationId, forceRefresh: forceRefresh);
    if (!mounted || widget.conversationId != conversationId) {
      return;
    }
    _messageState = _resolveDisplayedMessageState(
      ref.read(messagesNotifierProvider),
    );
    _syncConversationPreviewFromLoadedMessages(conversationId);
    await _refreshSharedRequestContext(_messageState.messages);
    _keepLatestMessageVisible();
  }

  void _syncConversationPreviewFromLoadedMessages(int conversationId) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      return;
    }
    ref
        .read(conversationsNotifierProvider.notifier)
        .syncConversationFromMessages(
          conversationId: conversationId,
          messages: _messageState.messages,
          isActiveConversation: true,
          currentUserId: currentUserId,
        );
  }

  Future<void> _activateLiveSync(int conversationId) async {
    final session = ref.read(currentSessionProvider);
    final currentUserId = ref.read(currentUserIdProvider);
    final accessToken = session.accessToken;
    if (currentUserId == null || accessToken == null || accessToken.isEmpty) {
      return;
    }
    await _messagesNotifier.activateConversation(
      conversationId: conversationId,
      currentUserId: currentUserId,
      accessToken: accessToken,
    );
    if (!mounted || widget.conversationId != conversationId) {
      return;
    }
    _conversationsNotifier.setActiveConversationId(conversationId);
    _messagesNotifier.sendSeenIfNeeded();
  }

  bool _isConversationLoadCurrent(int loadCycle, int conversationId) {
    return mounted &&
        _conversationLoadCycle == loadCycle &&
        widget.conversationId == conversationId;
  }

  MessageState _resolveDisplayedMessageState([MessageState? nextState]) {
    final MessageState activeState =
        nextState ?? ref.read(messagesNotifierProvider);
    if (activeState.conversationId == widget.conversationId) {
      return activeState;
    }
    return _messagesNotifier.peek(widget.conversationId) ??
        MessageState(conversationId: widget.conversationId, isLoading: true);
  }

  List<PartRequestBrief> _sharedProductsFromMessages(
    List<MessageModel> messages,
  ) {
    final products = <PartRequestBrief>[];
    final seenIds = <int>{};

    for (final message in messages.reversed) {
      final product = message.product;
      if (product == null || seenIds.contains(product.id)) {
        continue;
      }
      seenIds.add(product.id);
      products.add(product);
    }

    return products;
  }

  Future<void> _refreshSharedRequestContext(List<MessageModel> messages) async {
    final sharedProducts = _sharedProductsFromMessages(messages);
    final sharedIds = sharedProducts.map((product) => product.id).toSet();

    if (sharedIds.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedSharedRequestId = null;
        _isLoadingSharedRequestState = false;
        _sharedRequestsById.clear();
        _sharedAccessesByRequestId.clear();
      });
      return;
    }

    final nextSelectedId = sharedIds.contains(_selectedSharedRequestId)
        ? _selectedSharedRequestId
        : sharedProducts.first.id;
    final staleRequestIds = [
      for (final requestId in _sharedRequestsById.keys)
        if (!sharedIds.contains(requestId)) requestId,
    ];

    if (mounted) {
      setState(() {
        _selectedSharedRequestId = nextSelectedId;
        for (final requestId in staleRequestIds) {
          _sharedRequestsById.remove(requestId);
          _sharedAccessesByRequestId.remove(requestId);
        }
      });
    }

    if (nextSelectedId != null) {
      await _loadSharedRequestState(nextSelectedId);
    }
  }

  Future<void> _loadSharedRequestState(
    int requestId, {
    bool forceReload = false,
  }) async {
    final hasRequest = _sharedRequestsById.containsKey(requestId);
    final hasAccesses = _sharedAccessesByRequestId.containsKey(requestId);
    if (!forceReload && hasRequest && hasAccesses) {
      return;
    }

    if (mounted) {
      setState(() => _isLoadingSharedRequestState = true);
    }

    try {
      final requestApi = ref.read(requestApiProvider);
      final request = forceReload || !hasRequest
          ? await requestApi.getRequestById(requestId)
          : _sharedRequestsById[requestId]!;
      final accesses = forceReload || !hasAccesses
          ? await requestApi.getRequestAccesses(
              partRequestId: requestId,
              conversationId: widget.conversationId,
            )
          : _sharedAccessesByRequestId[requestId]!;
      ref.read(requestsNotifierProvider.notifier).upsertRequest(request);
      if (!mounted) {
        return;
      }
      setState(() {
        _sharedRequestsById[requestId] = request;
        _sharedAccessesByRequestId[requestId] = accesses;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSharedRequestState = false);
      }
    }
  }

  Future<void> _selectSharedRequest(int requestId) async {
    if (_selectedSharedRequestId == requestId) {
      return;
    }

    setState(() => _selectedSharedRequestId = requestId);
    await _loadSharedRequestState(requestId);
  }

  Future<void> _requestManagementAccess(int requestId) async {
    if (_isUpdatingSharedRequestState) {
      return;
    }

    setState(() => _isUpdatingSharedRequestState = true);
    try {
      await ref
          .read(requestApiProvider)
          .requestManagementAccess(
            partRequestId: requestId,
            conversationId: widget.conversationId,
          );
      await _loadSharedRequestState(requestId, forceReload: true);
      await ref.read(requestsNotifierProvider.notifier).load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.accessRequestSent)));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSendAccessRequest)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSharedRequestState = false);
      }
    }
  }

  Future<void> _approveSharedAccess(PartRequestAccess access) async {
    if (_isUpdatingSharedRequestState) {
      return;
    }

    setState(() => _isUpdatingSharedRequestState = true);
    try {
      await ref.read(requestApiProvider).approveRequestAccess(access.id);
      await _loadSharedRequestState(access.partRequest, forceReload: true);
      await ref.read(requestsNotifierProvider.notifier).load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accessRequestApproved)),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotApproveAccessRequest)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSharedRequestState = false);
      }
    }
  }

  Future<void> _rejectSharedAccess(PartRequestAccess access) async {
    if (_isUpdatingSharedRequestState) {
      return;
    }

    setState(() => _isUpdatingSharedRequestState = true);
    try {
      await ref.read(requestApiProvider).rejectRequestAccess(access.id);
      await _loadSharedRequestState(access.partRequest, forceReload: true);
      await ref.read(requestsNotifierProvider.notifier).load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accessRequestRejected)),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotRejectAccessRequest)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSharedRequestState = false);
      }
    }
  }

  Future<void> _sendMessage({
    PartRequestBrief? sharedProduct,
    List<ChatUploadImage>? attachmentsOverride,
  }) async {
    final text = _messageController.text.trim();
    final productToSend = sharedProduct ?? _selectedProduct;
    final attachments =
        attachmentsOverride ?? List<ChatUploadImage>.from(_selectedImages);
    if (text.isEmpty && attachments.isEmpty && productToSend == null) {
      return;
    }

    final currentUser = ref.read(currentSessionProvider).profile;
    if (currentUser == null) {
      return;
    }

    final replyTarget = _replyTarget;
    _messageController.clear();
    _keepLatestMessageVisible();

    final didSend = await _messagesNotifier.send(
      request: MessageCreateRequest(
        conversation: widget.conversationId,
        messageType: productToSend != null
            ? 'product'
            : attachments.isNotEmpty
            ? 'media'
            : 'text',
        text: text.isEmpty ? null : text,
        product: productToSend?.id,
        replyTo: replyTarget?.id,
        clientTimestamp: DateTime.now().toUtc(),
        attachments: attachments,
      ),
      sender: UserBrief(
        id: currentUser.id,
        name: currentUser.name,
        avatar: currentUser.avatar,
      ),
      optimisticProduct: productToSend,
      optimisticReply: replyTarget == null
          ? null
          : _replyPreviewFromMessage(replyTarget),
    );
    if (!mounted) {
      return;
    }
    if (didSend) {
      setState(() {
        _selectedImages = const [];
        _replyTarget = null;
        _selectedProduct = null;
      });
      _messagesNotifier.sendTyping(isTyping: false, hasText: false);
    }
    _keepLatestMessageVisible();
  }

  Future<void> _openMessageActions(
    MessageModel message,
    int currentUserId,
  ) async {
    final l10n = context.l10n;
    final canCopy = _canCopyMessage(message);
    final canEdit = _canEditMessage(message, currentUserId);
    final canDelete = _canDeleteForMe(message);
    if (!canCopy && !canEdit && !canDelete) {
      return;
    }

    final action = await showModalBottomSheet<_ChatMessageAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (canCopy)
                ListTile(
                  leading: const Icon(Icons.content_copy_rounded),
                  title: Text(l10n.copyMessage),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.copy),
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(l10n.editMessage),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.edit),
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(l10n.deleteMessage),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.delete),
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: Text(l10n.cancel),
                onTap: () =>
                    Navigator.of(context).pop(_ChatMessageAction.cancel),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null || action == _ChatMessageAction.cancel) {
      return;
    }

    switch (action) {
      case _ChatMessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text.trim()));
        _showComposerSnackBar(l10n.messageCopied);
        break;
      case _ChatMessageAction.edit:
        await _editMessage(message);
        break;
      case _ChatMessageAction.delete:
        await _confirmDeleteMessage(message, currentUserId);
        break;
      case _ChatMessageAction.cancel:
        break;
    }
  }

  Future<void> _editMessage(MessageModel message) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: message.text);
    String draft = message.text;

    final updatedText = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final trimmedDraft = draft.trim();
            final canSave =
                trimmedDraft.isNotEmpty && trimmedDraft != message.text.trim();
            return AlertDialog(
              title: Text(l10n.editMessageTitle),
              content: TextField(
                controller: controller,
                autofocus: true,
                minLines: 1,
                maxLines: 5,
                onChanged: (value) {
                  setModalState(() {
                    draft = value;
                  });
                },
                decoration: InputDecoration(hintText: l10n.updateYourMessage),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(trimmedDraft)
                      : null,
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (!mounted || updatedText == null) {
      return;
    }

    final updatedMessage = await _messagesNotifier.editMessage(
      message: message,
      text: updatedText,
    );
    if (!mounted) {
      return;
    }
    if (updatedMessage == null) {
      _showComposerSnackBar(l10n.messageCouldNotBeUpdated);
      return;
    }

    if (_replyTarget?.id == updatedMessage.id) {
      setState(() {
        _replyTarget = updatedMessage;
      });
    }
    _showComposerSnackBar(l10n.messageUpdated);
  }

  Future<void> _confirmDeleteMessage(
    MessageModel message,
    int currentUserId,
  ) async {
    final l10n = context.l10n;
    final canDeleteForAll = _canDeleteForAll(message, currentUserId);
    final scope = await showModalBottomSheet<_ChatMessageDeleteScope>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (canDeleteForAll)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded),
                  title: Text(l10n.deleteForAll),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageDeleteScope.all),
                ),
              ListTile(
                leading: const Icon(Icons.person_remove_alt_1_rounded),
                title: Text(l10n.deleteOnlyMe),
                onTap: () =>
                    Navigator.of(context).pop(_ChatMessageDeleteScope.me),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: Text(l10n.cancel),
                onTap: () =>
                    Navigator.of(context).pop(_ChatMessageDeleteScope.cancel),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || scope == null || scope == _ChatMessageDeleteScope.cancel) {
      return;
    }

    final didDelete = await _messagesNotifier.deleteMessage(
      message: message,
      scope: scope.apiValue,
    );
    if (!mounted) {
      return;
    }
    if (!didDelete) {
      _showComposerSnackBar(l10n.messageCouldNotBeDeleted);
      return;
    }

    if (_replyTarget?.id == message.id) {
      setState(() {
        _replyTarget = null;
      });
    }
    _showComposerSnackBar(
      scope == _ChatMessageDeleteScope.all
          ? l10n.messageDeletedForEveryone
          : l10n.messageDeletedForYou,
    );
  }

  bool _canCopyMessage(MessageModel message) {
    return !message.isDeleted && message.text.trim().isNotEmpty;
  }

  Future<void> _openUserProfile(int userId) async {
    if (userId <= 0) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserProfilePage(userId: userId)),
    );
  }

  bool _canEditMessage(MessageModel message, int currentUserId) {
    return !message.isDeleted &&
        !message.isOptimistic &&
        !message.hasSendError &&
        message.sender.id == currentUserId &&
        message.messageType == 'text' &&
        message.media.isEmpty &&
        message.product == null;
  }

  bool _canDeleteForMe(MessageModel message) {
    return !message.isOptimistic && message.id > 0;
  }

  bool _canDeleteForAll(MessageModel message, int currentUserId) {
    return _canDeleteForMe(message) &&
        !message.isDeleted &&
        message.sender.id == currentUserId;
  }

  Future<void> _startVoiceRecording() async {
    final l10n = context.l10n;
    if (_isVoiceRecording || _isVoiceRecorderBusy) {
      return;
    }
    if (_messageController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedProduct != null) {
      _showComposerSnackBar(l10n.sendOrClearDraftBeforeVoiceMessage);
      return;
    }

    setState(() {
      _isVoiceRecorderBusy = true;
    });

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showComposerSnackBar(l10n.microphonePermissionRequiredForVoiceMessage);
        return;
      }

      final tempDirectory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${tempDirectory.path}${Platform.pathSeparator}voice-${widget.conversationId}-$timestamp.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 24000,
          numChannels: 1,
          bitRate: 48000,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: filePath,
      );
      if (!mounted) {
        await _audioRecorder.cancel();
        return;
      }

      _composerFocusNode.unfocus();
      _messagesNotifier.sendTyping(isTyping: false, hasText: false);
      setState(() {
        _isVoiceRecording = true;
        _voiceRecordingStartedAt = DateTime.now();
        _voiceRecordingDuration = Duration.zero;
      });
      _startVoiceRecordingTicker();
      _keepLatestMessageVisible();
    } catch (_) {
      _showComposerSnackBar(l10n.voiceRecordingCouldNotStart);
    } finally {
      if (mounted) {
        setState(() {
          _isVoiceRecorderBusy = false;
        });
      }
    }
  }

  Future<void> _cancelVoiceRecording({bool silent = false}) async {
    final l10n = context.l10n;
    if (_isVoiceRecorderBusy) {
      return;
    }

    final shouldCancel = _isVoiceRecording || _voiceRecordingStartedAt != null;
    if (!shouldCancel) {
      return;
    }

    if (mounted) {
      setState(() {
        _isVoiceRecorderBusy = true;
      });
    }

    try {
      await _audioRecorder.cancel();
      if (!silent) {
        _showComposerSnackBar(l10n.voiceMessageDiscarded);
      }
    } catch (_) {
      if (!silent) {
        _showComposerSnackBar(l10n.voiceMessageDiscardFailed);
      }
    } finally {
      _resetVoiceRecordingState();
      if (mounted) {
        setState(() {
          _isVoiceRecorderBusy = false;
        });
      }
    }
  }

  Future<void> _stopAndSendVoiceMessage() async {
    final l10n = context.l10n;
    if (!_isVoiceRecording || _isVoiceRecorderBusy) {
      return;
    }

    setState(() {
      _isVoiceRecorderBusy = true;
    });

    try {
      final recordedPath = await _audioRecorder.stop();
      if (recordedPath == null || recordedPath.trim().isEmpty) {
        _resetVoiceRecordingState();
        _showComposerSnackBar(l10n.noVoiceMessageCaptured);
        return;
      }

      final recordedFile = File(recordedPath);
      final attachment = ChatUploadImage(
        path: recordedPath,
        fileName: recordedFile.path.split(Platform.pathSeparator).last,
        contentType: 'audio/mp4',
        size: await recordedFile.length(),
      );

      _resetVoiceRecordingState();
      await _sendMessage(attachmentsOverride: [attachment]);
    } catch (_) {
      _showComposerSnackBar(l10n.voiceMessageCouldNotBeSent);
      _resetVoiceRecordingState();
    } finally {
      if (mounted) {
        setState(() {
          _isVoiceRecorderBusy = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 88,
      requestFullMetadata: false,
    );
    if (!mounted || pickedFiles.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages = [
        ..._selectedImages,
        ...pickedFiles.map(_mapPickedFile),
      ];
    });
  }

  void _removeSelectedImage(ChatUploadImage image) {
    setState(() {
      _selectedImages = _selectedImages
          .where((item) => item.path != image.path)
          .toList(growable: false);
    });
  }

  void _handleComposerChanged() {
    if (_isVoiceRecording) {
      _messagesNotifier.sendTyping(isTyping: false, hasText: false);
      return;
    }
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_composerFocusNode.hasFocus) {
      _keepLatestMessageVisible();
    }
    _messagesNotifier.sendTyping(
      isTyping: _composerFocusNode.hasFocus && hasText,
      hasText: hasText,
    );
  }

  ChatUploadImage _mapPickedFile(XFile file) {
    final fileName = file.name.trim().isNotEmpty
        ? file.name
        : file.path.split(Platform.pathSeparator).last;
    return ChatUploadImage(
      path: file.path,
      fileName: fileName,
      contentType: lookupMimeType(file.path) ?? _fallbackMimeType(fileName),
    );
  }

  String _fallbackMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  void _startVoiceRecordingTicker() {
    _voiceRecordingTicker?.cancel();
    _voiceRecordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _voiceRecordingStartedAt;
      if (!mounted || startedAt == null) {
        return;
      }
      setState(() {
        _voiceRecordingDuration = DateTime.now().difference(startedAt);
      });
    });
  }

  void _resetVoiceRecordingState() {
    _voiceRecordingTicker?.cancel();
    _voiceRecordingTicker = null;
    _voiceRecordingStartedAt = null;
    _voiceRecordingDuration = Duration.zero;
    _isVoiceRecording = false;
  }

  void _showComposerSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  MessageReplyModel _replyPreviewFromMessage(MessageModel message) {
    final l10n = context.l10n;
    return MessageReplyModel(
      id: message.id,
      sender: message.sender,
      text: message.isDeleted
          ? l10n.deletedMessage
          : message.text.trim().isNotEmpty
          ? message.text
          : message.media.any((attachment) => attachment.isAudio)
          ? l10n.voiceMessage
          : message.media.any((attachment) => attachment.isImage)
          ? l10n.photo
          : message.product?.title ?? l10n.attachment,
      translatedText: message.text.trim().isNotEmpty
          ? message.translatedText
          : null,
      textLanguage: message.textLanguage,
      product: message.isDeleted ? null : message.product,
      translationTargetLanguage: message.translationTargetLanguage,
      clientTimestamp: message.clientTimestamp,
      serverTimestamp: message.serverTimestamp,
      editedAt: message.editedAt,
      isDeleted: message.isDeleted,
    );
  }

  void _scheduleScrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final targetOffset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }

      _scrollController.jumpTo(targetOffset);
    });
  }

  void _keepLatestMessageVisible() {
    _scheduleScrollToBottom(animated: true);
    _scheduleDeferredBottomSync(const Duration(milliseconds: 120));
    _scheduleDeferredBottomSync(const Duration(milliseconds: 260));
    _scheduleDeferredBottomSync(const Duration(milliseconds: 420));
  }

  void _scheduleDeferredBottomSync(Duration delay) {
    Future<void>.delayed(delay, () {
      if (!mounted) {
        return;
      }
      _scheduleScrollToBottom(animated: true);
    });
  }
}

enum _ChatMessageAction { copy, edit, delete, cancel }

enum _ChatMessageDeleteScope {
  all('all'),
  me('me'),
  cancel('');

  const _ChatMessageDeleteScope(this.apiValue);

  final String apiValue;
}

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 108),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFF2EEE7),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => _TypingIndicatorDot(
                    progress: _controller.value,
                    index: index,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TypingIndicatorDot extends StatelessWidget {
  const _TypingIndicatorDot({required this.progress, required this.index});

  final double progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final shifted = (progress - (index * 0.16) + 1) % 1;
    final wave = math.sin(shifted * math.pi).clamp(0.0, 1.0).toDouble();
    final lift = wave * 5;
    final opacity = 0.34 + (wave * 0.66);

    return Padding(
      padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
      child: Transform.translate(
        offset: Offset(0, -lift),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF7B756D),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.statusLabel,
    required this.connectionStatus,
    required this.avatarName,
    required this.avatarUrl,
    required this.presenceColor,
    required this.showBack,
    this.onProfileTap,
    this.onBack,
  });

  final String title;
  final String statusLabel;
  final ChatConnectionStatus connectionStatus;
  final String avatarName;
  final String? avatarUrl;
  final Color? presenceColor;
  final bool showBack;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        UserAvatar(
          label: avatarName,
          imageUrl: avatarUrl,
          //   presenceColor: presenceColor,
          onTap: onProfileTap,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: onProfileTap,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (presenceColor != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: presenceColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _connectionLabel(context, statusLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6F6A63),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _connectionLabel(BuildContext context, String fallbackStatus) {
    return switch (connectionStatus) {
      ChatConnectionStatus.connecting => context.l10n.connecting,
      ChatConnectionStatus.reconnecting => context.l10n.reconnecting,
      ChatConnectionStatus.failed => context.l10n.liveUpdatesUnavailable,
      ChatConnectionStatus.connected => fallbackStatus,
      ChatConnectionStatus.disconnected => fallbackStatus,
    };
  }
}

class _RequestAccessPanel extends StatelessWidget {
  const _RequestAccessPanel({
    required this.sharedProducts,
    required this.selectedProductId,
    required this.selectedProduct,
    required this.selectedRequest,
    required this.accesses,
    required this.currentUserId,
    required this.otherUserId,
    required this.isLoading,
    required this.isUpdating,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onSelectProduct,
    required this.onRequestAccess,
    required this.onApproveAccess,
    required this.onRejectAccess,
  });

  final List<PartRequestBrief> sharedProducts;
  final int? selectedProductId;
  final PartRequestBrief selectedProduct;
  final PartRequest? selectedRequest;
  final List<PartRequestAccess> accesses;
  final int currentUserId;
  final int? otherUserId;
  final bool isLoading;
  final bool isUpdating;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onSelectProduct;
  final Future<void> Function() onRequestAccess;
  final Future<void> Function(PartRequestAccess access) onApproveAccess;
  final Future<void> Function(PartRequestAccess access) onRejectAccess;

  @override
  Widget build(BuildContext context) {
    final request = selectedRequest;
    final statusLabel =
        request?.statusDetails?.label ?? selectedProduct.statusDetails?.label;
    final isOwner = request?.isOwner ?? false;
    final hasManageAccess = request?.canUpdateStatus == true;

    PartRequestAccess? myAccess;
    PartRequestAccess? acceptedAccess;
    PartRequestAccess? pendingOtherAccess;
    for (final access in accesses) {
      if (access.user == currentUserId) {
        myAccess = access;
      }
      if (access.isAccepted && acceptedAccess == null) {
        acceptedAccess = access;
      }
      if (otherUserId != null &&
          access.user == otherUserId &&
          access.isPending &&
          pendingOtherAccess == null) {
        pendingOtherAccess = access;
      }
    }

    final infoText = switch ((
      isOwner,
      myAccess?.status,
      acceptedAccess?.user,
    )) {
      (true, _, final acceptedUserId?) when acceptedUserId == otherUserId =>
        context.l10n.thisChatCanManageRequestStatus,
      (true, _, final acceptedUserId?) when acceptedUserId != otherUserId =>
        context.l10n.thisRequestIsAssignedToAnotherSupplier,
      (true, _, _) => context.l10n.noAccessRequestForThisRequestYet,
      (false, 'accepted', _) => context.l10n.youCanChangeThisRequestStatusNow,
      (false, 'pending', _) => context.l10n.waitingForOwnerApproval,
      (false, 'rejected', _) => context.l10n.ownerRejectedYourAccessRequest,
      _ => context.l10n.askOwnerForStatusAccess,
    };
    final pendingAccessForOther = pendingOtherAccess;
    final toggleTooltip = isExpanded
        ? context.l10n.collapseRequestControl
        : context.l10n.expandRequestControl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0D7CA)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.requestControl,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedProduct.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF0C4A63),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: toggleTooltip,
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ),
              ],
            ),
            if (statusLabel != null && statusLabel.trim().isNotEmpty) ...[
              // const SizedBox(height: 10),
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 10,
              //     vertical: 6,
              //   ),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFE3EEF1),
              //     borderRadius: BorderRadius.circular(999),
              //   ),
              //   child: Text(
              //     statusLabel,
              //     style: Theme.of(context).textTheme.labelLarge?.copyWith(
              //       color: const Color(0xFF0C4A63),
              //       fontWeight: FontWeight.w800,
              //     ),
              //   ),
              // ),
            ],
            if (isExpanded) ...[
              const SizedBox(height: 12),
              if (sharedProducts.length > 1)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final product in sharedProducts)
                      ChoiceChip(
                        label: Text(product.displayTitle),
                        selected: product.id == selectedProductId,
                        onSelected: (_) => onSelectProduct(product.id),
                      ),
                  ],
                ),
              if (sharedProducts.length > 1) const SizedBox(height: 12),
              if (isLoading && request == null)
                const LinearProgressIndicator()
              else
                Text(
                  infoText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F6A63),
                    height: 1.35,
                  ),
                ),
              if (request?.grantedUser != null) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.currentManager(request!.grantedUser!.name),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0C4A63),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (isOwner && pendingAccessForOther != null)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: isUpdating
                          ? null
                          : () => onApproveAccess(pendingAccessForOther),
                      icon: Icon(
                        isUpdating
                            ? Icons.hourglass_top_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      label: Text(
                        isUpdating
                            ? context.l10n.approving
                            : context.l10n.approveAccess,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isUpdating
                          ? null
                          : () => onRejectAccess(pendingAccessForOther),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(context.l10n.rejectAccess),
                    ),
                  ],
                )
              else if (!isOwner &&
                  !hasManageAccess &&
                  myAccess?.status != 'pending')
                FilledButton.tonalIcon(
                  onPressed: isUpdating ? null : onRequestAccess,
                  icon: Icon(
                    isUpdating
                        ? Icons.hourglass_top_rounded
                        : Icons.lock_open_rounded,
                  ),
                  label: Text(
                    isUpdating
                        ? context.l10n.sendingRequest
                        : context.l10n.requestAccess,
                  ),
                )
              else if (!isOwner && myAccess?.status == 'pending')
                Text(
                  context.l10n.accessRequestPending,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8A5A1F),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (!isOwner && hasManageAccess)
                Text(
                  context.l10n.openAssignedRequestsToUpdateStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0C4A63),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.selectedImages,
    required this.isSending,
    required this.isVoiceRecording,
    required this.isVoiceRecorderBusy,
    required this.voiceRecordingDuration,
    required this.replyTarget,
    required this.selectedProduct,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onStartVoiceRecording,
    required this.onCancelVoiceRecording,
    required this.onSendVoiceRecording,
    required this.onCancelReply,
    required this.onCancelProduct,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<ChatUploadImage> selectedImages;
  final bool isSending;
  final bool isVoiceRecording;
  final bool isVoiceRecorderBusy;
  final Duration voiceRecordingDuration;
  final MessageModel? replyTarget;
  final PartRequestBrief? selectedProduct;
  final Future<void> Function() onPickImages;
  final void Function(ChatUploadImage image) onRemoveImage;
  final Future<void> Function() onStartVoiceRecording;
  final Future<void> Function({bool silent}) onCancelVoiceRecording;
  final Future<void> Function() onSendVoiceRecording;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelProduct;
  final Future<void> Function({PartRequestBrief? sharedProduct}) onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DFD2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTarget != null) ...[
              _ReplyPreviewCard(message: replyTarget!, onCancel: onCancelReply),
              const SizedBox(height: 12),
            ],
            if (selectedProduct != null) ...[
              _ProductPreviewCard(
                product: selectedProduct!,
                onCancel: onCancelProduct,
              ),
              const SizedBox(height: 12),
            ],
            if (selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final image = selectedImages[index];
                    return _SelectedImageCard(
                      image: image,
                      onRemove: () => onRemoveImage(image),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isVoiceRecording)
              _VoiceRecordingComposer(
                isBusy: isVoiceRecorderBusy || isSending,
                duration: voiceRecordingDuration,
                onCancel: () => onCancelVoiceRecording(silent: false),
                onSend: onSendVoiceRecording,
              )
            else
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: context.l10n.uploadImages,
                    onPressed: isSending || isVoiceRecorderBusy
                        ? null
                        : onPickImages,
                    icon: const Icon(Icons.photo_library_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      enabled: !isVoiceRecorderBusy,
                      decoration: InputDecoration(
                        hintText: context.l10n.writeAMessage,
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final hasText = value.text.trim().isNotEmpty;
                      final canSend =
                          hasText ||
                          selectedImages.isNotEmpty ||
                          selectedProduct != null;
                      if (canSend) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: isSending || isVoiceRecorderBusy
                                  ? null
                                  : () => onSend(),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(14),
                              ),
                              icon: Icon(
                                isSending
                                    ? Icons.hourglass_top_rounded
                                    : Icons.send_rounded,
                              ),
                              tooltip: isSending
                                  ? context.l10n.sending
                                  : context.l10n.sendMessage,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: isVoiceRecorderBusy
                                ? null
                                : onStartVoiceRecording,
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                            ),
                            icon: Icon(
                              isVoiceRecorderBusy
                                  ? Icons.hourglass_top_rounded
                                  : Icons.mic_rounded,
                            ),
                            tooltip: isVoiceRecorderBusy
                                ? context.l10n.preparingRecorder
                                : context.l10n.recordVoiceMessage,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceRecordingComposer extends StatelessWidget {
  const _VoiceRecordingComposer({
    required this.isBusy,
    required this.duration,
    required this.onCancel,
    required this.onSend,
  });

  final bool isBusy;
  final Duration duration;
  final Future<void> Function() onCancel;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD0C4)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isBusy ? null : onCancel,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: context.l10n.discardVoiceMessage,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD34C3E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RecordingWaveStrip(color: const Color(0xFFD34C3E)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDuration(duration),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8A2D24),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            onPressed: isBusy ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFD34C3E),
              foregroundColor: Colors.white,
            ),
            icon: Icon(
              isBusy ? Icons.hourglass_top_rounded : Icons.send_rounded,
            ),
            tooltip: isBusy
                ? context.l10n.sending
                : context.l10n.sendVoiceMessage,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _RecordingWaveStrip extends StatefulWidget {
  const _RecordingWaveStrip({required this.color});

  final Color color;

  @override
  State<_RecordingWaveStrip> createState() => _RecordingWaveStripState();
}

class _RecordingWaveStripState extends State<_RecordingWaveStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final barCount = math.max(18, (constraints.maxWidth / 7).floor());
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(barCount, (index) {
                final shifted = (_controller.value + (index * 0.07)) % 1;
                final wave = math.sin(shifted * math.pi).abs();
                final height = 6 + (wave * 14);
                return Container(
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.32 + (wave * 0.68)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _ReplyPreviewCard extends StatelessWidget {
  const _ReplyPreviewCard({required this.message, required this.onCancel});

  final MessageModel message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = message.isDeleted
        ? l10n.deletedMessage
        : message.text.trim().isNotEmpty
        ? message.displayText
        : message.media.any((attachment) => attachment.isAudio)
        ? l10n.voiceMessage
        : message.media.any((attachment) => attachment.isImage)
        ? l10n.photo
        : message.product?.displayTitle ?? l10n.attachment;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E8E4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.replyingTo(message.sender.name),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F6A63),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({required this.product, required this.onCancel});

  final PartRequestBrief product;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priceLabel = switch ((product.minPrice, product.maxPrice)) {
      (final min?, final max?) => '$min - $max',
      (final min?, null) => l10n.fromPrice(min.toString()),
      (null, final max?) => l10n.upToPrice(max.toString()),
      _ => l10n.noPriceRange,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D5A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: Color(0xFFB35B00)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.attachedRequest,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB35B00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (product.carModel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.carModel!.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF0C4A63),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F6A63),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SelectedImageCard extends StatelessWidget {
  const _SelectedImageCard({required this.image, required this.onRemove});

  final ChatUploadImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 92,
            height: 92,
            child: Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
