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

import '../../api/chat_socket_service.dart';
import '../../controllers/methods/api_methods/load_conversations_notifier.dart';
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

        await _cancelVoiceRecording(silent: true);
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
        child: const EmptyStateCard(
          title: 'No messages yet',
          message: 'Say hello and start the conversation.',
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
    ref
        .read(conversationsNotifierProvider.notifier)
        .setActiveConversationId(conversationId);
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
                  title: const Text('Copy message'),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.copy),
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit message'),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.edit),
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Delete message'),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageAction.delete),
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
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
        _showComposerSnackBar('Message copied.');
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
              title: const Text('Edit Message'),
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
                decoration: const InputDecoration(
                  hintText: 'Update your message',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(trimmedDraft)
                      : null,
                  child: const Text('Save'),
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
      _showComposerSnackBar('Message could not be updated.');
      return;
    }

    if (_replyTarget?.id == updatedMessage.id) {
      setState(() {
        _replyTarget = updatedMessage;
      });
    }
    _showComposerSnackBar('Message updated.');
  }

  Future<void> _confirmDeleteMessage(
    MessageModel message,
    int currentUserId,
  ) async {
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
                  title: const Text('Delete for all'),
                  onTap: () =>
                      Navigator.of(context).pop(_ChatMessageDeleteScope.all),
                ),
              ListTile(
                leading: const Icon(Icons.person_remove_alt_1_rounded),
                title: const Text('Delete only me'),
                onTap: () =>
                    Navigator.of(context).pop(_ChatMessageDeleteScope.me),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
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
      _showComposerSnackBar('Message could not be deleted.');
      return;
    }

    if (_replyTarget?.id == message.id) {
      setState(() {
        _replyTarget = null;
      });
    }
    _showComposerSnackBar(
      scope == _ChatMessageDeleteScope.all
          ? 'Message deleted for everyone.'
          : 'Message deleted for you.',
    );
  }

  bool _canCopyMessage(MessageModel message) {
    return !message.isDeleted && message.text.trim().isNotEmpty;
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
    if (_isVoiceRecording || _isVoiceRecorderBusy) {
      return;
    }
    if (_messageController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedProduct != null) {
      _showComposerSnackBar(
        'Send or clear the current draft before recording a voice message.',
      );
      return;
    }

    setState(() {
      _isVoiceRecorderBusy = true;
    });

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showComposerSnackBar(
          'Microphone permission is required to record a voice message.',
        );
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
      _showComposerSnackBar('Voice recording could not start on this device.');
    } finally {
      if (mounted) {
        setState(() {
          _isVoiceRecorderBusy = false;
        });
      }
    }
  }

  Future<void> _cancelVoiceRecording({bool silent = false}) async {
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
        _showComposerSnackBar('Voice message discarded.');
      }
    } catch (_) {
      if (!silent) {
        _showComposerSnackBar('Voice message could not be discarded cleanly.');
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
        _showComposerSnackBar('No voice message was captured.');
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
      _showComposerSnackBar('Voice message could not be sent.');
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
    return MessageReplyModel(
      id: message.id,
      sender: message.sender,
      text: message.isDeleted
          ? 'Deleted message'
          : message.text.trim().isNotEmpty
          ? message.text
          : message.media.any((attachment) => attachment.isAudio)
          ? 'Voice message'
          : message.media.any((attachment) => attachment.isImage)
          ? 'Photo'
          : message.product?.title ?? 'Attachment',
      product: message.isDeleted ? null : message.product,
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
                    tooltip: 'Upload images',
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
                                  ? 'Sending...'
                                  : 'Send message',
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
                                ? 'Preparing recorder...'
                                : 'Record voice message',
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
            tooltip: 'Discard voice message',
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
            tooltip: isBusy ? 'Sending...' : 'Send voice message',
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
    final preview = message.isDeleted
        ? 'Deleted message'
        : message.text.trim().isNotEmpty
        ? message.text
        : message.media.any((attachment) => attachment.isAudio)
        ? 'Voice message'
        : message.media.any((attachment) => attachment.isImage)
        ? 'Photo'
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
