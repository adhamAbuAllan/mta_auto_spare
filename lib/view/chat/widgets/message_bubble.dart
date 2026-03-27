import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../common_widgets/time_formatter.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xFF116466)
        : const Color(0xFFF2EEE7);
    final foreground = isMine ? Colors.white : const Color(0xFF1C1B18);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isMine ? 22 : 8),
              bottomRight: Radius.circular(isMine ? 8 : 22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    message.sender.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (message.replyTo != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${message.replyTo!.sender.name}: ${message.replyTo!.text}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: 0.84),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                _messageBody(message),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: foreground,
                  height: 1.32,
                ),
              ),
              if (message.product != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Request: ${message.product!.title}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatRelativeTime(
                    message.serverTimestamp ?? message.clientTimestamp,
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.74),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageBody(MessageModel message) {
    if (message.text.trim().isNotEmpty) {
      return message.text;
    }
    if (message.messageType == 'product' && message.product != null) {
      return 'Shared a request';
    }
    if (message.messageType == 'media') {
      return 'Sent ${message.media.length} attachment(s)';
    }
    return 'Message';
  }
}
