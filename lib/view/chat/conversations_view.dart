import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/conversation_state.dart';
import '../../localization/app_localizations_x.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/empty_state_card.dart';
import '../profile/user_profile_page.dart';
import 'chat_formatters.dart';
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
      if (!mounted) {
        return;
      }
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
                    context.l10n.conversations,
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
        const SizedBox(height: 8),
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
      return Center(
        child: EmptyStateCard(
          title: context.l10n.noConversationsYet,
          message: context.l10n.noConversationsYetMessage,
          icon: Icons.chat_bubble_outline_rounded,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: conversationState.conversations.length + 1,
      separatorBuilder: (context, index) => const SizedBox.shrink(),
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
                conversationState.isLoadingMore
                    ? context.l10n.loading
                    : context.l10n.loadMore,
              ),
            ),
          );
        }

        final conversation = conversationState.conversations[index];
        final participant = otherParticipant(conversation, currentUserId);
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
          onProfileTap: participant == null
              ? null
              : () => _openUserProfile(participant.user.id),
        );
      },
    );
  }

  Future<void> _openUserProfile(int userId) async {
    if (userId <= 0) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserProfilePage(userId: userId)),
    );
  }
}
