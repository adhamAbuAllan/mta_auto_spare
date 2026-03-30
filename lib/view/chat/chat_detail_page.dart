import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../api/chat_socket_service.dart';
import '../../controllers/methods/api_methods/load_messages_notifier.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/message_state.dart';
import '../../models/models.dart';
import '../../session/session_state.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/empty_state_card.dart';
import '../common_widgets/user_avatar.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_handleComposerChanged);
    _composerFocusNode.addListener(_handleComposerChanged);
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
        setState(() {
          _messageState = _resolveDisplayedMessageState(next);
        });
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

        setState(() {
          _selectedImages = const [];
          _replyTarget = null;
          _selectedProduct = null;
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
    _conversationLoadCycle += 1;
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.close();
    _messageSubscription = null;
    _sessionSubscription?.close();
    _sessionSubscription = null;
    _messageController.removeListener(_handleComposerChanged);
    _composerFocusNode.removeListener(_handleComposerChanged);
    _composerFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    unawaited(_messagesNotifier.deactivateConversation(widget.conversationId));

    super.dispose();
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
        ? 'Conversation #${widget.conversationId}'
        : conversationDisplayName(conversation, currentUserId);
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
              ? 'Typing...'
              : conversationPresenceLabel(
                  isOnline: isOtherOnline,
                  lastSeenAt: otherLastSeenAt,
                ),
          onBack: widget.onBack,
          showBack: widget.onBack != null || !widget.wideMode,
          avatarName: title,
          avatarUrl: participant?.user.avatar,
          presenceColor: presenceColor,
        ),
        const SizedBox(height: 16),
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
          replyTarget: _replyTarget,
          selectedProduct: _selectedProduct,
          onPickImages: _pickImages,
          onRemoveImage: _removeSelectedImage,
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
      return const EmptyStateCard(
        title: 'No messages yet',
        message: 'Say hello and start the conversation.',
        icon: Icons.forum_outlined,
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
    _keepLatestMessageVisible();
  }

  void _syncConversationPreviewFromLoadedMessages(int conversationId) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || _messageState.messages.isEmpty) {
      return;
    }

    final latestMessage = _messageState.messages.last;
    if (latestMessage.conversationId != conversationId) {
      return;
    }

    ref
        .read(conversationsNotifierProvider.notifier)
        .touchConversationFromMessage(
          conversationId: conversationId,
          message: latestMessage,
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

  Future<void> _sendMessage({PartRequestBrief? sharedProduct}) async {
    final text = _messageController.text.trim();
    final productToSend = sharedProduct ?? _selectedProduct;
    if (text.isEmpty && _selectedImages.isEmpty && productToSend == null) {
      return;
    }

    final currentUser = ref.read(currentSessionProvider).profile;
    if (currentUser == null) {
      return;
    }

    final attachments = List<ChatUploadImage>.from(_selectedImages);
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

  MessageReplyModel _replyPreviewFromMessage(MessageModel message) {
    return MessageReplyModel(
      id: message.id,
      sender: message.sender,
      text: message.text,
      product: message.product,
      clientTimestamp: message.clientTimestamp,
      serverTimestamp: message.serverTimestamp,
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
    this.onBack,
  });

  final String title;
  final String statusLabel;
  final ChatConnectionStatus connectionStatus;
  final String avatarName;
  final String? avatarUrl;
  final Color? presenceColor;
  final bool showBack;
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
        ),
        const SizedBox(width: 12),
        Expanded(
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
                      _connectionLabel(statusLabel),
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
      ],
    );
  }

  String _connectionLabel(String fallbackStatus) {
    return switch (connectionStatus) {
      ChatConnectionStatus.connecting => 'Connecting...',
      ChatConnectionStatus.reconnecting => 'Reconnecting...',
      ChatConnectionStatus.failed => 'Live updates unavailable',
      ChatConnectionStatus.connected => fallbackStatus,
      ChatConnectionStatus.disconnected => fallbackStatus,
    };
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.selectedImages,
    required this.isSending,
    required this.replyTarget,
    required this.selectedProduct,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onCancelReply,
    required this.onCancelProduct,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<ChatUploadImage> selectedImages;
  final bool isSending;
  final MessageModel? replyTarget;
  final PartRequestBrief? selectedProduct;
  final Future<void> Function() onPickImages;
  final void Function(ChatUploadImage image) onRemoveImage;
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
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Upload images',
                  onPressed: isSending ? null : onPickImages,
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
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
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
                    if (!canSend) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: isSending ? null : () => onSend(),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                          ),
                          icon: Icon(
                            isSending
                                ? Icons.hourglass_top_rounded
                                : Icons.send_rounded,
                          ),
                          tooltip: isSending ? 'Sending...' : 'Send message',
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

class _ReplyPreviewCard extends StatelessWidget {
  const _ReplyPreviewCard({required this.message, required this.onCancel});

  final MessageModel message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final preview = message.text.trim().isNotEmpty
        ? message.text
        : message.product?.title ?? 'Attachment';
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
                  'Replying to ${message.sender.name}',
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
    final priceLabel = switch ((product.minPrice, product.maxPrice)) {
      (final min?, final max?) => '$min - $max',
      (final min?, null) => 'From $min',
      (null, final max?) => 'Up to $max',
      _ => 'No price range',
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
                  'Attached request',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB35B00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
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
