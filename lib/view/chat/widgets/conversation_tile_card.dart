import 'package:flutter/material.dart';

import '../../../localization/app_localizations_x.dart';
import '../../../models/models.dart';
import '../../common_widgets/time_formatter.dart';
import '../../common_widgets/user_avatar.dart';
import '../chat_formatters.dart';

class ConversationTileCard extends StatelessWidget {
  const ConversationTileCard({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
    this.onProfileTap,
  });

  final ConversationListItem conversation;
  final int currentUserId;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayName = conversationDisplayName(
      conversation,
      currentUserId,
      l10n,
    );
    final participant = otherParticipant(conversation, currentUserId);
    final lastMessage = conversation.lastMessage;
    final isLastMessageMine =
        lastMessage != null && lastMessage.senderId == currentUserId;
    final lastOwnMessage = isLastMessageMine ? lastMessage : null;
    final presenceColor = participant == null
        ? null
        : participant.user.isOnline
        ? const Color(0xFF20A05A)
        : const Color(0xFFB9B2A8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F8F7) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? const Color(0xFF116466) : const Color(0xFFE7DFD2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  label: displayName,
                  imageUrl: participant?.user.avatar,
                  radius: 22,
                  presenceColor: presenceColor,
                  onTap: onProfileTap,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: onProfileTap,
                              style: TextButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatRelativeTime(
                              conversation.lastMessage?.timestamp,
                              l10n,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF7A746C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (lastOwnMessage != null) ...[
                            _ConversationReceiptIcon(
                              receiptState: lastOwnMessage.receiptStateFor(
                                currentUserId,
                              ),
                              isOptimistic: lastOwnMessage.isOptimistic,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              conversationPreview(conversation, l10n),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF6F6A63)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF116466),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      conversation.unreadCount > 9
                          ? '9+'
                          : '${conversation.unreadCount}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationReceiptIcon extends StatelessWidget {
  const _ConversationReceiptIcon({
    required this.receiptState,
    required this.isOptimistic,
  });

  final MessageReceiptState receiptState;
  final bool isOptimistic;

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF8C867E);
    final (icon, color) = switch (receiptState) {
      MessageReceiptState.pending => (
        Icons.done_rounded,
        baseColor.withValues(alpha: 0.55),
      ),
      MessageReceiptState.sent => (
        Icons.done_rounded,
        baseColor.withValues(alpha: 0.82),
      ),
      MessageReceiptState.delivered => (
        Icons.done_all_rounded,
        baseColor.withValues(alpha: 0.88),
      ),
      MessageReceiptState.seen => (
        Icons.done_all_rounded,
        const Color(0xFF2B9CC3),
      ),
      MessageReceiptState.failed => (
        Icons.error_outline_rounded,
        const Color(0xFFD47C42),
      ),
    };

    return AnimatedOpacity(
      opacity: isOptimistic ? 0.9 : 1,
      duration: const Duration(milliseconds: 180),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
