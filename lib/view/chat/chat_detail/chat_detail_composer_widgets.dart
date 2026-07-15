part of '../chat_detail_page.dart';

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.selectedImages,
    required this.isSending,
    required this.isVoiceRecording,
    required this.isVoiceRecorderBusy,
    required this.voiceRecordingDuration,
    required this.replyTarget,
    required this.selectedProduct,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onStartVoiceRecording,
    required this.onCancelVoiceRecording,
    required this.onSendVoiceRecording,
    required this.onCancelReply,
    required this.onCancelProduct,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<ChatUploadImage> selectedImages;
  final bool isSending;
  final bool isVoiceRecording;
  final bool isVoiceRecorderBusy;
  final Duration voiceRecordingDuration;
  final MessageModel? replyTarget;
  final PartRequestBrief? selectedProduct;
  final Future<void> Function() onPickImages;
  final void Function(ChatUploadImage image) onRemoveImage;
  final Future<void> Function() onStartVoiceRecording;
  final Future<void> Function({bool silent}) onCancelVoiceRecording;
  final Future<void> Function() onSendVoiceRecording;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelProduct;
  final Future<void> Function({PartRequestBrief? sharedProduct}) onSend;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTarget != null) ...[
              _ReplyPreviewCard(message: replyTarget!, onCancel: onCancelReply),
              const SizedBox(height: 12),
            ],
            if (selectedProduct != null) ...[
              _ProductPreviewCard(
                product: selectedProduct!,
                onCancel: onCancelProduct,
              ),
              const SizedBox(height: 12),
            ],
            if (selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final image = selectedImages[index];
                    return _SelectedImageCard(
                      image: image,
                      onRemove: () => onRemoveImage(image),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isVoiceRecording)
              _VoiceRecordingComposer(
                isBusy: isVoiceRecorderBusy || isSending,
                duration: voiceRecordingDuration,
                onCancel: () => onCancelVoiceRecording(silent: false),
                onSend: onSendVoiceRecording,
              )
            else
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: context.l10n.uploadImages,
                    onPressed: isSending || isVoiceRecorderBusy
                        ? null
                        : onPickImages,
                    icon: const Icon(Icons.photo_library_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      enabled: !isVoiceRecorderBusy,
                      decoration: InputDecoration(
                        hintText: context.l10n.writeAMessage,
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final hasText = value.text.trim().isNotEmpty;
                      final canSend =
                          hasText ||
                          selectedImages.isNotEmpty ||
                          selectedProduct != null;
                      if (canSend) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: isSending || isVoiceRecorderBusy
                                  ? null
                                  : () => onSend(),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(14),
                              ),
                              icon: Icon(
                                isSending
                                    ? Icons.hourglass_top_rounded
                                    : Icons.send_rounded,
                              ),
                              tooltip: isSending
                                  ? context.l10n.sending
                                  : context.l10n.sendMessage,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: isVoiceRecorderBusy
                                ? null
                                : onStartVoiceRecording,
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                            ),
                            icon: Icon(
                              isVoiceRecorderBusy
                                  ? Icons.hourglass_top_rounded
                                  : Icons.mic_rounded,
                            ),
                            tooltip: isVoiceRecorderBusy
                                ? context.l10n.preparingRecorder
                                : context.l10n.recordVoiceMessage,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceRecordingComposer extends StatelessWidget {
  const _VoiceRecordingComposer({
    required this.isBusy,
    required this.duration,
    required this.onCancel,
    required this.onSend,
  });

  final bool isBusy;
  final Duration duration;
  final Future<void> Function() onCancel;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD0C4)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isBusy ? null : onCancel,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: context.l10n.discardVoiceMessage,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD34C3E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RecordingWaveStrip(color: const Color(0xFFD34C3E)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDuration(duration),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8A2D24),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            onPressed: isBusy ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFD34C3E),
              foregroundColor: Colors.white,
            ),
            icon: Icon(
              isBusy ? Icons.hourglass_top_rounded : Icons.send_rounded,
            ),
            tooltip: isBusy
                ? context.l10n.sending
                : context.l10n.sendVoiceMessage,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _RecordingWaveStrip extends StatefulWidget {
  const _RecordingWaveStrip({required this.color});

  final Color color;

  @override
  State<_RecordingWaveStrip> createState() => _RecordingWaveStripState();
}

class _RecordingWaveStripState extends State<_RecordingWaveStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final barCount = math.max(18, (constraints.maxWidth / 7).floor());
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(barCount, (index) {
                final shifted = (_controller.value + (index * 0.07)) % 1;
                final wave = math.sin(shifted * math.pi).abs();
                final height = 6 + (wave * 14);
                return Container(
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.32 + (wave * 0.68)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _ReplyPreviewCard extends StatelessWidget {
  const _ReplyPreviewCard({required this.message, required this.onCancel});

  final MessageModel message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = message.isDeleted
        ? l10n.deletedMessage
        : message.text.trim().isNotEmpty
        ? message.displayText
        : message.media.any((attachment) => attachment.isAudio)
        ? l10n.voiceMessage
        : message.media.any((attachment) => attachment.isImage)
        ? l10n.photo
        : message.product?.displayTitle ?? l10n.attachment;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E8E4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.replyingTo(message.sender.name),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F6A63),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({required this.product, required this.onCancel});

  final PartRequestBrief product;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priceLabel = switch ((product.minPrice, product.maxPrice)) {
      (final min?, final max?) => '$min - $max',
      (final min?, null) => l10n.fromPrice(min.toString()),
      (null, final max?) => l10n.upToPrice(max.toString()),
      _ => l10n.noPriceRange,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D5A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: Color(0xFFB35B00)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.attachedRequest,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB35B00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (product.carModel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.carModel!.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1E5E33),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F6A63),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SelectedImageCard extends StatelessWidget {
  const _SelectedImageCard({required this.image, required this.onRemove});

  final ChatUploadImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 92,
            height: 92,
            child: Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
