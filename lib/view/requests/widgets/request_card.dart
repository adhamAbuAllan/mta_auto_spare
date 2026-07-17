import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../constants/api_constants.dart';
import '../../../localization/app_localizations_x.dart';
import '../../../models/models.dart';
import '../../common_widgets/app_panel.dart';
import '../../common_widgets/car_model_card.dart';
import '../../common_widgets/debug_performance_probe.dart';
import '../../common_widgets/time_formatter.dart';
import '../../common_widgets/user_avatar.dart';
import '../../common_widgets/zoomable_network_gallery_page.dart';

class RequestCard extends StatefulWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.isMine,
    required this.canChangeStatus,
    required this.showStatus,
    required this.onViewTap,
    required this.onChatTap,
    this.isChatLoading = false,
    this.onEditTap,
    this.onDeleteTap,
    this.onChangeStatusTap,
    this.onRequesterTap,
    this.isDeleteLoading = false,
  });

  final PartRequest request;
  final bool isMine;
  final bool canChangeStatus;
  final bool showStatus;
  final VoidCallback onViewTap;
  final VoidCallback onChatTap;
  final bool isChatLoading;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onChangeStatusTap;
  final VoidCallback? onRequesterTap;
  final bool isDeleteLoading;

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  @override
  Widget build(BuildContext context) {
    final resolvedImageUrls = widget.request.images
        .map((image) => ApiConstants.resolveUrl(image.image))
        .toList(growable: false);
    final resolvedThumbnailUrls = widget.request.images
        .map((image) => ApiConstants.resolveUrl(image.thumbnail ?? image.image))
        .toList(growable: false);

    return DebugPerformanceProbe(
      label: 'request#${widget.request.id ?? 'new'}/card',
      child: AppPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.request.images.isNotEmpty) ...[
              DebugPerformanceProbe(
                label: 'request#${widget.request.id ?? 'new'}/images',
                child: SizedBox(
                  height: 176,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemExtent: 204,
                    cacheExtent: 0,
                    itemCount: widget.request.images.length,
                    itemBuilder: (context, index) {
                      final resolvedImageUrl = resolvedImageUrls[index];
                      final resolvedThumbnailUrl = resolvedThumbnailUrls[index];

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          key: ValueKey(
                            'request-image-thumbnail-${widget.request.id ?? 0}-$index',
                          ),
                          onTap: () {
                            final image = widget.request.images[index];
                            debugPrint(
                              'Request image data: ${jsonEncode({...image.toJson(), 'image': resolvedImageUrl})}',
                            );
                            _openImageGallery(
                              context,
                              resolvedImageUrls: resolvedImageUrls,
                              initialIndex: index,
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 1.1,
                              child: Hero(
                                tag: _heroTagForIndex(index),
                                child: _RequestCardImageThumbnail(
                                  imageUrl: resolvedThumbnailUrl,
                                  requestId: widget.request.id ?? 0,
                                  imageIndex: index,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.request.carModel != null) ...[
              DebugPerformanceProbe(
                label: 'request#${widget.request.id ?? 'new'}/car-model',
                child: CarModelCard(
                  carModel: widget.request.carModel ?? CarModelOption(),
                  compact: true,
                ),
              ),
              const SizedBox(height: 14),
            ],
            DebugPerformanceProbe(
              label: 'request#${widget.request.id ?? 'new'}/requester',
              child: _RequesterSummary(
                name: widget.request.requesterDetails?.name,
                avatarUrl: widget.request.requesterDetails?.avatar,
                fallbackLabel: 'User #${widget.request.requester}',
                onTap: widget.onRequesterTap,
              ),
            ),
            const SizedBox(height: 14),
            if (widget.isMine || widget.canChangeStatus) ...[
              _RequestOwnershipBanner(
                icon: widget.isMine
                    ? Icons.person_pin_circle_outlined
                    : Icons.assignment_turned_in_outlined,
                label: widget.isMine
                    ? context.l10n.thisRequestBelongsToYou
                    : context.l10n.youCanManageThisRequestStatus,
                tone: const Color(0xFFEAF7EE),
                foreground: const Color(0xFF027A48),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                if (widget.showStatus && widget.request.statusDetails != null)
                  _MetaChip(
                    icon: Icons.flag_outlined,
                    label: widget.request.statusDetails?.label ?? "",
                  ),
                _MetaChip(
                  icon: Icons.location_on_outlined,
                  label: widget.request.city?.trim().isNotEmpty == true
                      ? widget.request.city
                      : context.l10n.cityNotSet,
                ),
                _MetaChip(
                  icon: Icons.schedule_outlined,
                  label: formatRelativeTime(
                    widget.request.createdAt,
                    context.l10n,
                  ),
                ),

                /// where you want to enable the preice widget on this widget.
                /// just uncommit the following lines.
                // if (widget.request.minPrice != null || widget.request.maxPrice !=
                //     null)
                //   _MetaChip(
                //     icon: Icons.sell_outlined,
                //     label: _priceLabel(widget.request, context),
                //   ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.request.displayTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              widget.request.displayDescription,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF5F5A54),
                height: 1.35,
              ),
            ),
            if (!widget.isMine && !widget.canChangeStatus) ...[
              const SizedBox(height: 14),
              Text(
                context.l10n.openChatWithSellerBehindRequest,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (widget.isMine)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onViewTap,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(context.l10n.viewRequest),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onChangeStatusTap,
                    icon: const Icon(Icons.flag_circle_outlined),
                    label: Text(context.l10n.changeStatus),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onEditTap,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(context.l10n.edit),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.isDeleteLoading ? null :
                    widget.onDeleteTap,
                    style: FilledButton.styleFrom(
                      //   foregroundColor: const Color(0xFF9F2D2D),
                    ),
                    icon: Icon(
                      widget.isDeleteLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.delete_outline_rounded,
                    ),
                    label: Text(
                      widget.isDeleteLoading
                          ? context.l10n.deleting
                          : context.l10n.delete,
                    ),
                  ),
                ],
              )
            else if (widget.canChangeStatus)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onViewTap,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(context.l10n.viewRequest),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onChangeStatusTap,
                    icon: const Icon(Icons.flag_circle_outlined),
                    label: Text(context.l10n.changeStatus),
                  ),
                  FilledButton.icon(
                    onPressed: widget.isChatLoading ? null : widget.onChatTap,
                    icon: Icon(
                      widget.isChatLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.chat_bubble_outline_rounded,
                    ),
                    label: Text(
                      widget.isChatLoading ? context.l10n.opening : context.l10n
                          .chat,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onViewTap,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(context.l10n.viewRequest),
                    ),
                    FilledButton.icon(
                      onPressed: widget.isChatLoading ? null : widget.onChatTap,
                      icon: Icon(
                        widget.isChatLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.chat_bubble_outline_rounded,
                      ),
                      label: Text(
                        widget.isChatLoading ? context.l10n.opening : context
                            .l10n
                            .chat,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _priceLabel(PartRequest request, dynamic context) {
    final minPrice = request.minPrice?.trim();
    final maxPrice = request.maxPrice?.trim();

    if (minPrice != null &&
        minPrice.isNotEmpty &&
        maxPrice != null &&
        maxPrice.isNotEmpty) {
      return '$minPrice - $maxPrice';
    }
    if (minPrice != null && minPrice.isNotEmpty) {
      return context.l10n.fromPrice(minPrice);
    }
    if (maxPrice != null && maxPrice.isNotEmpty) {
      return context.l10n.upToPrice(maxPrice);
    }
    return context.l10n.noPriceRange;
  }

  Object _heroTagForIndex(int index) {
    return 'request-image-${widget.request.id ?? 'new'}-$index';
  }

  void _openImageGallery(
    BuildContext context, {
    required List<String> resolvedImageUrls,
    required int initialIndex,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ZoomableNetworkGalleryPage(
          imageUrls: resolvedImageUrls,
          initialIndex: initialIndex,
          headers: const {
            ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
          },
          heroTagBuilder: _heroTagForIndex,
        ),
      ),
    );
  }
}

class _RequestOwnershipBanner extends StatelessWidget {
  const _RequestOwnershipBanner({
    required this.icon,
    required this.label,
    required this.tone,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      //width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequesterSummary extends StatefulWidget {
  const _RequesterSummary({
    this.name,
    this.avatarUrl,
    this.fallbackLabel,
    this.onTap,
  });

  final String? name;
  final String? avatarUrl;
  final String? fallbackLabel;
  final VoidCallback? onTap;

  @override
  State<_RequesterSummary> createState() => _RequesterSummaryState();
}

class _RequesterSummaryState extends State<_RequesterSummary> {
  @override
  Widget build(BuildContext context) {
    final displayName = widget.name?.trim().isNotEmpty == true
        ? widget.name?.trim()
        : widget.fallbackLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          label: displayName ?? "",
          imageUrl: widget.avatarUrl,
          radius: 20,
          onTap: widget.onTap,
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Text(
                displayName ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E5E33),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestCardImageThumbnail extends StatelessWidget {
  const _RequestCardImageThumbnail({
    required this.imageUrl,
    required this.requestId,
    required this.imageIndex,
  });

  final String imageUrl;
  final int requestId;
  final int imageIndex;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        _RequestImageSkeleton(
          key: ValueKey('request-image-skeleton-$requestId-$imageIndex'),
        ),
        Image.network(
          imageUrl,
          cacheWidth: (194 * devicePixelRatio).ceil(),
          cacheHeight: (176 * devicePixelRatio).ceil(),
          fit: BoxFit.cover,
          headers: const {
            ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            final hasLoadedImage = wasSynchronouslyLoaded || frame != null;
            return AnimatedOpacity(
              opacity: hasLoadedImage ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey('request-image-loaded-$requestId-$imageIndex'),
                child: child,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              '[Requests][Images] Failed to render image for '
              'request #$requestId: '
              '$imageUrl '
              'error=$error',
            );
            return Container(
              color: const Color(0xFFF2EEE7),
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFF7A746C),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RequestImageSkeleton extends StatelessWidget {
  const _RequestImageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4DBD0), Color(0xFFF4EEE5), Color(0xFFE4DBD0)],
          stops: [0.08, 0.42, 1],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFFB9AFA2)),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({this.icon, this.label});

  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E5E33)),
          const SizedBox(width: 6),
          Text(
            label ?? "",
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFF5F5A54)),
          ),
        ],
      ),
    );
  }
}
