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
part 'chat_detail/chat_detail_request_access.dart';
part 'chat_detail/chat_detail_message_actions.dart';
part 'chat_detail/chat_detail_voice_and_media.dart';
part 'chat_detail/chat_detail_status_widgets.dart';
part 'chat_detail/chat_detail_composer_widgets.dart';

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

abstract class _ChatDetailPageStateBase extends ConsumerState<ChatDetailPage> {
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

  void _showComposerSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

class _ChatDetailPageState extends _ChatDetailPageStateVoiceAndMedia
    with WidgetsBindingObserver {

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
}
