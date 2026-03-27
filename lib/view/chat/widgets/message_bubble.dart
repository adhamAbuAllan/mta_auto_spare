import 'dart:io';

import 'package:flutter/material.dart';

import '../../../constants/api_constants.dart';
import '../../../models/models.dart';
import '../../common_widgets/time_formatter.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.isMine,
    this.onReply,
  });

  final MessageModel message;
  final int currentUserId;
  final bool isMine;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xFF116466)
        : const Color(0xFFF2EEE7);
    final foreground = isMine ? Colors.white : const Color(0xFF1C1B18);
    final receiptState = message.receiptStateFor(currentUserId);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: onReply,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isMine ? 22 : 8),
              bottomRight: Radius.circular(isMine ? 8 : 22),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleColor.withValues(
                  alpha: message.isOptimistic ? 0.88 : 1,
                ),
                border: message.hasSendError
                    ? Border.all(
                        color: const Color(0xFFFFA552).withValues(alpha: 0.8),
                      )
                    : null,
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
                  if (message.media.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MessageMediaGallery(
                      attachments: message.media,
                      isMine: isMine,
                    ),
                  ],
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatRelativeTime(
                            message.serverTimestamp ?? message.clientTimestamp,
                          ),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground.withValues(alpha: 0.74),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          _MessageReceiptIcon(
                            receiptState: receiptState,
                            foreground: foreground,
                            isOptimistic: message.isOptimistic,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _messageBody(MessageModel message) {
    if (message.text.trim().isNotEmpty) {
      return message.text;
    }
    if (message.messageType == 'media' && message.media.isNotEmpty) {
      return message.media.every((attachment) => attachment.isImage)
          ? 'Photo'
          : 'Sent ${message.media.length} attachment(s)';
    }
    if (message.messageType == 'product' && message.product != null) {
      return 'Shared a request';
    }
    return 'Message';
  }
}

class _MessageMediaGallery extends StatelessWidget {
  const _MessageMediaGallery({
    required this.attachments,
    required this.isMine,
  });

  final List<MessageAttachmentModel> attachments;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final imageAttachments = attachments
        .where((attachment) => attachment.isImage)
        .toList(growable: false);
    if (imageAttachments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final attachment in attachments)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                attachment.fileUrl ?? attachment.localPath ?? 'Attachment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isMine ? Colors.white : const Color(0xFF1C1B18),
                ),
              ),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final attachment in imageAttachments)
          _MessageImageTile(attachment: attachment),
      ],
    );
  }
}

class _MessageImageTile extends StatelessWidget {
  const _MessageImageTile({required this.attachment});

  final MessageAttachmentModel attachment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openViewer(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 180,
            height: 180,
            child: ColoredBox(
              color: const Color(0x1A000000),
              child: _buildImage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      return Image.file(
        File(attachment.localPath!),
        fit: BoxFit.cover,
      );
    }
    if (attachment.fileUrl != null && attachment.fileUrl!.isNotEmpty) {
      return Image.network(
        ApiConstants.resolveUrl(attachment.fileUrl!),
        fit: BoxFit.cover,
      );
    }
    return const Center(child: Icon(Icons.image_not_supported_outlined));
  }

  void _openViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: _buildViewerImage(),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.48),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewerImage() {
    if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      return Image.file(
        File(attachment.localPath!),
        fit: BoxFit.contain,
      );
    }
    if (attachment.fileUrl != null && attachment.fileUrl!.isNotEmpty) {
      return Image.network(
        ApiConstants.resolveUrl(attachment.fileUrl!),
        fit: BoxFit.contain,
      );
    }
    return const Icon(
      Icons.image_not_supported_outlined,
      color: Colors.white,
      size: 56,
    );
  }
}

class _MessageReceiptIcon extends StatelessWidget {
  const _MessageReceiptIcon({
    required this.receiptState,
    required this.foreground,
    required this.isOptimistic,
  });

  final MessageReceiptState receiptState;
  final Color foreground;
  final bool isOptimistic;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (receiptState) {
      MessageReceiptState.pending => (
        Icons.done_rounded,
        foreground.withValues(alpha: 0.46),
      ),
      MessageReceiptState.sent => (
        Icons.done_all_rounded,
        foreground.withValues(alpha: 0.78),
      ),
      MessageReceiptState.delivered => (
        Icons.done_all_rounded,
        foreground.withValues(alpha: 0.82),
      ),
      MessageReceiptState.seen => (
        Icons.done_all_rounded,
        const Color(0xFF93E8FF),
      ),
      MessageReceiptState.failed => (
        Icons.error_outline_rounded,
        const Color(0xFFFFC67A),
      ),
    };

    return AnimatedOpacity(
      opacity: isOptimistic ? 0.92 : 1,
      duration: const Duration(milliseconds: 180),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
