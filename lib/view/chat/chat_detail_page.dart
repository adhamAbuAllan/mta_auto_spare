import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/message_state.dart';
import '../../models/models.dart';
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

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
  }

  @override
  void didUpdateWidget(covariant ChatDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawMessageState = ref.watch(messagesNotifierProvider);
    final conversationsState = ref.watch(conversationsNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider) ?? 0;
    final messageState = rawMessageState.conversationId == widget.conversationId
        ? rawMessageState
        : const MessageState(isLoading: true);

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

    final content = Column(
      children: [
        _ChatHeader(
          title: title,
          subtitle: conversation == null
              ? 'Chat thread'
              : 'Request conversation',
          onBack: widget.onBack,
          showBack: widget.onBack != null || !widget.wideMode,
          avatarName: title,
          avatarUrl: participant?.user.avatar,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildMessagesBody(context, messageState, currentUserId),
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
          isSending: messageState.isSending,
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
    int currentUserId,
  ) {
    if (messageState.isLoading && messageState.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messageState.errorMessage != null && messageState.messages.isEmpty) {
      return AppErrorCard(
        message: messageState.errorMessage!,
        onRetry: _loadMessages,
      );
    }

    if (messageState.messages.isEmpty) {
      return const EmptyStateCard(
        title: 'No messages yet',
        message: 'Say hello and start the conversation.',
        icon: Icons.forum_outlined,
      );
    }

    return Column(
      children: [
        if (messageState.hasMore)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: messageState.isLoadingMore
                  ? null
                  : () =>
                        ref.read(messagesNotifierProvider.notifier).loadMore(),
              child: Text(
                messageState.isLoadingMore ? 'Loading...' : 'Load More',
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messageState.messages.length,
            itemBuilder: (context, index) {
              final message = messageState.messages[index];
              return MessageBubble(
                message: message,
                isMine: message.sender.id == currentUserId,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadMessages() async {
    await ref
        .read(messagesNotifierProvider.notifier)
        .load(widget.conversationId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final success = await ref
        .read(messagesNotifierProvider.notifier)
        .send(
          MessageCreateRequest(
            conversation: widget.conversationId,
            messageType: 'text',
            text: text,
            clientTimestamp: DateTime.now().toUtc(),
          ),
        );

    if (!success || !mounted) {
      return;
    }

    _messageController.clear();
    ref.read(conversationsNotifierProvider.notifier).load();
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.avatarName,
    required this.avatarUrl,
    required this.showBack,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final String avatarName;
  final String? avatarUrl;
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
        UserAvatar(label: avatarName, imageUrl: avatarUrl),
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
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F6A63),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;

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
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
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
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isSending ? null : onSend,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: Text(isSending ? 'Sending...' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }
}
