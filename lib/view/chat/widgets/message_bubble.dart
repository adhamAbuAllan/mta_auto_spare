import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/api_constants.dart';
import '../../../localization/app_localizations_x.dart';
import '../../../models/models.dart';
import '../../common_widgets/time_formatter.dart';
import 'voice_message_card.dart';
import 'voice_message_playback_controller.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.isMine,
    required this.voicePlaybackController,
    this.onReply,
    this.onLongPress,
  });

  final MessageModel message;
  final int currentUserId;
  final bool isMine;
  final VoiceMessagePlaybackController voicePlaybackController;
  final VoidCallback? onReply;
  final VoidCallback? onLongPress;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  static const double _maxSwipeOffset = 78;
  static const double _replyTriggerOffset = 52;

  double _dragOffset = 0;
  bool _didCrossReplyThreshold = false;
  bool _showOriginal = false;

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _showOriginal = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Match sent messages with the light-green request-status panel used in
    // this chat, so the conversation has one consistent status theme.
    final bubbleColor = widget.isMine
        ? const Color(0xFFEAF7EE)
        : const Color(0xFFFFFFFF);
    final foreground = const Color(0xFF1C1B18);
    final receiptState = widget.message.receiptStateFor(widget.currentUserId);
    final hasTranslatedContent = widget.message.hasTranslatedContent;
    final showOriginalText = _showOriginal && hasTranslatedContent;
    final bodyText = _messageBody(
      widget.message,
      l10n,
      showOriginalText: showOriginalText,
    );
    final swipeProgress = (_dragOffset / _replyTriggerOffset).clamp(0.0, 1.0);
    final showDeletedPlaceholder = widget.message.isDeleted;

    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: widget.onReply == null
              ? null
              : _handleHorizontalDragUpdate,
          onHorizontalDragEnd: widget.onReply == null
              ? null
              : _handleHorizontalDragEnd,
          onHorizontalDragCancel: widget.onReply == null ? null : _resetSwipe,
          child: Stack(
            alignment: widget.isMine
                ? Alignment.centerRight
                : Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 10,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 90),
                    opacity: swipeProgress,
                    child: Transform.scale(
                      scale: 0.86 + (swipeProgress * 0.18),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F0EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC2DDD4)),
                        ),
                        child: Icon(
                          Icons.reply_rounded,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(_dragOffset, 0, 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(widget.isMine ? 22 : 8),
                      bottomRight: Radius.circular(widget.isMine ? 8 : 22),
                    ),
                    onLongPress: widget.onLongPress,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bubbleColor.withValues(
                          alpha: widget.message.isOptimistic ? 0.88 : 1,
                        ),
                        border: Border.all(
                          color: widget.message.hasSendError
                              ? const Color(0xFFF59E0B)
                              : widget.isMine
                              ? const Color(0xFFB7E4C7)
                              : const Color(0xFFE4E7EC),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(22),
                          topRight: const Radius.circular(22),
                          bottomLeft: Radius.circular(widget.isMine ? 22 : 8),
                          bottomRight: Radius.circular(widget.isMine ? 8 : 22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.isMine)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                widget.message.sender.name,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: foreground.withValues(alpha: 0.84),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          if (!showDeletedPlaceholder &&
                              widget.message.replyTo != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: widget.isMine
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${widget.message.replyTo!.sender.name}: ${_replyPreviewText(widget.message.replyTo!, l10n, showOriginalText: showOriginalText)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: foreground.withValues(alpha: 0.84),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (bodyText.isNotEmpty)
                            Text(
                              bodyText,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: foreground,
                                    height: 1.32,
                                    fontStyle: showDeletedPlaceholder
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                            ),
                          if (!showDeletedPlaceholder &&
                              widget.message.media.isNotEmpty) ...[
                            if (bodyText.isNotEmpty) const SizedBox(height: 10),
                            _MessageMediaGallery(
                              attachments: widget.message.media,
                              isMine: widget.isMine,
                              message: widget.message,
                              voicePlaybackController:
                                  widget.voicePlaybackController,
                            ),
                          ],
                          if (!showDeletedPlaceholder &&
                              widget.message.product != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isMine
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                l10n.requestWithTitle(
                                  showOriginalText
                                      ? widget.message.product!.title
                                      : widget.message.product!.displayTitle,
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: foreground,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (widget.message.product!.statusDetails !=
                                null) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.message.product!.statusDetails!.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: foreground.withValues(alpha: 0.78),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ],
                          if (!showDeletedPlaceholder &&
                              hasTranslatedContent) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: foreground.withValues(
                                    alpha: 0.88,
                                  ),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showOriginal = !_showOriginal;
                                  });
                                },
                                child: Text(
                                  _showOriginal
                                      ? l10n.showTranslation
                                      : l10n.showOriginal,
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
                                if (widget.message.editedAt != null &&
                                    !widget.message.isDeleted) ...[
                                  Text(
                                    l10n.edited,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: foreground.withValues(
                                            alpha: 0.74,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  formatRelativeTime(
                                    widget.message.serverTimestamp ??
                                        widget.message.clientTimestamp,
                                    context.l10n,
                                  ),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: foreground.withValues(
                                          alpha: 0.74,
                                        ),
                                      ),
                                ),
                                if (widget.isMine) ...[
                                  const SizedBox(width: 6),
                                  _MessageReceiptIcon(
                                    receiptState: receiptState,
                                    foreground: foreground,
                                    isOptimistic: widget.message.isOptimistic,
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
            ],
          ),
        ),
      ),
    );
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final nextOffset = (_dragOffset + delta).clamp(0.0, _maxSwipeOffset);
    if (nextOffset == _dragOffset) {
      return;
    }

    if (nextOffset >= _replyTriggerOffset && !_didCrossReplyThreshold) {
      _didCrossReplyThreshold = true;
      HapticFeedback.lightImpact();
    } else if (nextOffset < _replyTriggerOffset) {
      _didCrossReplyThreshold = false;
    }

    setState(() {
      _dragOffset = nextOffset;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final shouldReply = _dragOffset >= _replyTriggerOffset;
    _resetSwipe();
    if (shouldReply) {
      widget.onReply?.call();
    }
  }

  void _resetSwipe() {
    if (!mounted) {
      return;
    }
    _didCrossReplyThreshold = false;
    if (_dragOffset == 0) {
      return;
    }
    setState(() {
      _dragOffset = 0;
    });
  }

  String _messageBody(
    MessageModel message,
    dynamic l10n, {
    required bool showOriginalText,
  }) {
    if (message.isDeleted) {
      return l10n.thisMessageWasDeleted;
    }
    if (message.text.trim().isNotEmpty) {
      return showOriginalText ? message.text : message.displayText;
    }
    if (message.messageType == 'media' && message.media.isNotEmpty) {
      if (message.media.every((attachment) => attachment.isAudio)) {
        return '';
      }
      return message.media.every((attachment) => attachment.isImage)
          ? message.media.length == 1
                ? l10n.photo
                : l10n.photosCount(message.media.length)
          : l10n.sentAttachmentsCount(message.media.length);
    }
    if (message.messageType == 'product' && message.product != null) {
      return l10n.sharedRequest;
    }
    return l10n.messageLabel;
  }

  String _replyPreviewText(
    MessageReplyModel reply,
    dynamic l10n, {
    required bool showOriginalText,
  }) {
    if (reply.isDeleted) {
      return l10n.deletedMessage;
    }
    if (reply.text.trim().isNotEmpty) {
      return showOriginalText ? reply.text : reply.displayText;
    }
    return showOriginalText
        ? reply.product?.title ?? l10n.attachment
        : reply.product?.displayTitle ?? l10n.attachment;
  }
}

class _MessageMediaGallery extends StatelessWidget {
  const _MessageMediaGallery({
    required this.attachments,
    required this.isMine,
    required this.message,
    required this.voicePlaybackController,
  });

  final List<MessageAttachmentModel> attachments;
  final bool isMine;
  final MessageModel message;
  final VoiceMessagePlaybackController voicePlaybackController;

  @override
  Widget build(BuildContext context) {
    final imageAttachments = attachments
        .where((attachment) => attachment.isImage)
        .toList(growable: false);
    final nonImageAttachments = attachments
        .where((attachment) => !attachment.isImage)
        .toList(growable: false);

    if (imageAttachments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            var index = 0;
            index < nonImageAttachments.length;
            index += 1
          ) ...[
            _buildNonImageAttachment(context, nonImageAttachments[index]),
            if (index != nonImageAttachments.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final attachment in imageAttachments)
              _MessageImageTile(attachment: attachment),
          ],
        ),
        if (nonImageAttachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (
            var index = 0;
            index < nonImageAttachments.length;
            index += 1
          ) ...[
            _buildNonImageAttachment(context, nonImageAttachments[index]),
            if (index != nonImageAttachments.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _buildNonImageAttachment(
    BuildContext context,
    MessageAttachmentModel attachment,
  ) {
    if (attachment.isAudio) {
      final playbackId = _voicePlaybackId(message, attachment);
      return VoiceMessageCard(
        key: ValueKey(playbackId),
        attachment: attachment,
        isMine: isMine,
        playbackId: playbackId,
        playbackController: voicePlaybackController,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file_rounded,
            color: isMine ? Colors.white : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isMine ? Colors.white : const Color(0xFF1C1B18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _voicePlaybackId(
    MessageModel message,
    MessageAttachmentModel attachment,
  ) {
    // Attachment IDs survive REST/socket rebuilds. The URL fallback keeps an
    // optimistic attachment stable until the server assigns its ID.
    final attachmentIdentity = attachment.id != 0
        ? attachment.id.toString()
        : (attachment.fileUrl ?? attachment.localPath ?? 'unknown');
    return '${message.id}:$attachmentIdentity';
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
      return Image.file(File(attachment.localPath!), fit: BoxFit.cover);
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
      return Image.file(File(attachment.localPath!), fit: BoxFit.contain);
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
        const Color(0xFF20A05A),
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
