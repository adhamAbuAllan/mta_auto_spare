import 'package:flutter/material.dart';

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
  });

  final ConversationListItem conversation;
  final int currentUserId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = conversationDisplayName(conversation, currentUserId);
    final participant = otherParticipant(conversation, currentUserId);
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatRelativeTime(
                              conversation.lastMessage?.timestamp,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF7A746C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        conversationPreview(conversation),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6F6A63),
                        ),
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
