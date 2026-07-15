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
    final theme = Theme.of(context);
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
    final unreadCount = conversation.unreadCount;
    final hasUnread = unreadCount > 0;
    final previewColor = hasUnread
        ? const Color(0xFF111827)
        : const Color(0xFF6F6A63);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEAF7F2) : Colors.white,
        borderRadius: BorderRadius.circular(isSelected ? 16 : 0),
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isSelected ? 16 : 0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatar(
                  label: displayName,
                  imageUrl: participant?.user.avatar,
                  radius: 24,
                  presenceColor: presenceColor,
                  onTap: onProfileTap,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: hasUnread
                              ? FontWeight.w900
                              : FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: previewColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 42, maxWidth: 58),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRelativeTime(
                          conversation.lastMessage?.timestamp,
                          l10n,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasUnread
                              ? theme.primaryColor
                              : const Color(0xFF7A746C),
                          fontWeight: hasUnread
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasUnread)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 22),
                    ],
                  ),
                ),
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
        const Color(0xFF027A48),
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
