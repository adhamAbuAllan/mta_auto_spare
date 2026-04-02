import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/conversation_state.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/empty_state_card.dart';
import 'widgets/conversation_tile_card.dart';

class ConversationsView extends ConsumerStatefulWidget {
  const ConversationsView({
    super.key,
    required this.wideMode,
    required this.onOpenConversation,
  });

  final bool wideMode;
  final ValueChanged<int> onOpenConversation;

  @override
  ConsumerState<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends ConsumerState<ConversationsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(conversationsNotifierProvider);
      if (state.conversations.isEmpty && !state.isLoading) {
        ref.read(conversationsNotifierProvider.notifier).load();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final notifier = ref.read(conversationsNotifierProvider.notifier);
    notifier.load(forceRefresh: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationsNotifierProvider);
    final selectedConversationId = ref.watch(selectedConversationIdProvider);
    final currentUserId = ref.watch(currentUserIdProvider) ?? 0;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversations',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        if (conversationState.errorMessage != null &&
            conversationState.conversations.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppErrorCard(message: conversationState.errorMessage!),
        ],
        const SizedBox(height: 18),
        Expanded(
          child: _buildBody(
            context,
            conversationState,
            currentUserId,
            selectedConversationId,
          ),
        ),
      ],
    );

    if (widget.wideMode) {
      return content;
    }

    return Padding(padding: const EdgeInsets.all(16), child: content);
  }

  Widget _buildBody(
    BuildContext context,
    ConversationState conversationState,
    int currentUserId,
    int? selectedConversationId,
  ) {
    if (conversationState.isLoading &&
        conversationState.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationState.errorMessage != null &&
        conversationState.conversations.isEmpty) {
      return AppErrorCard(
        message: conversationState.errorMessage!,
        onRetry: () => ref
            .read(conversationsNotifierProvider.notifier)
            .load(forceRefresh: true),
      );
    }

    if (conversationState.conversations.isEmpty) {
      return const EmptyStateCard(
        title: 'No conversations yet',
        message:
            'When you tap the chat button from a request card, the conversation will appear here.',
        icon: Icons.chat_bubble_outline_rounded,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: conversationState.conversations.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == conversationState.conversations.length) {
          if (!conversationState.hasMore) {
            return const SizedBox(height: 4);
          }
          return Center(
            child: OutlinedButton(
              onPressed: conversationState.isLoadingMore
                  ? null
                  : () => ref
                        .read(conversationsNotifierProvider.notifier)
                        .loadMore(),
              child: Text(
                conversationState.isLoadingMore ? 'Loading...' : 'Load More',
              ),
            ),
          );
        }

        final conversation = conversationState.conversations[index];
        return ConversationTileCard(
          conversation: conversation,
          currentUserId: currentUserId,
          isSelected: selectedConversationId == conversation.id,
          onTap: () {
            ref
                .read(conversationsNotifierProvider.notifier)
                .markConversationRead(conversation.id);
            widget.onOpenConversation(conversation.id);
          },
        );
      },
    );
  }
}
