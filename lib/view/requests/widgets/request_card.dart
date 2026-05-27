import 'package:flutter/material.dart';

import '../../../constants/api_constants.dart';
import '../../../localization/app_localizations_x.dart';
import '../../../models/models.dart';
import '../../common_widgets/app_panel.dart';
import '../../common_widgets/car_model_card.dart';
import '../../common_widgets/time_formatter.dart';
import '../../common_widgets/user_avatar.dart';
import '../../common_widgets/zoomable_network_gallery_page.dart';

class RequestCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final resolvedImageUrls = request.images
        .map((image) => ApiConstants.resolveUrl(image.image))
        .toList(growable: false);

    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request.images.isNotEmpty) ...[
            SizedBox(
              height: 228,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final resolvedImageUrl = resolvedImageUrls[index];

                  return GestureDetector(
                    key: ValueKey(
                      'request-image-thumbnail-${request.id ?? 0}-$index',
                    ),
                    onTap: () => _openImageGallery(
                      context,
                      resolvedImageUrls: resolvedImageUrls,
                      initialIndex: index,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 1.1,
                        child: Hero(
                          tag: _heroTagForIndex(index),
                          child: _RequestCardImageThumbnail(
                            imageUrl: resolvedImageUrl,
                            requestId: request.id ?? 0,
                            imageIndex: index,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (request.carModel != null) ...[
            CarModelCard(carModel: request.carModel!, compact: true),
            const SizedBox(height: 14),
          ],
          _RequesterSummary(
            name: request.requesterDetails?.name,
            avatarUrl: request.requesterDetails?.avatar,
            fallbackLabel: 'User #${request.requester}',
            onTap: onRequesterTap,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              if (showStatus && request.statusDetails != null)
                _MetaChip(
                  icon: Icons.flag_outlined,
                  label: request.statusDetails!.label,
                ),
              _MetaChip(
                icon: Icons.location_on_outlined,
                label: request.city?.trim().isNotEmpty == true
                    ? request.city!
                    : context.l10n.cityNotSet,
              ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: formatRelativeTime(request.createdAt, context.l10n),
              ),
              if (request.minPrice != null || request.maxPrice != null)
                _MetaChip(
                  icon: Icons.sell_outlined,
                  label: _priceLabel(request, context),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            request.displayTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            request.displayDescription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF5F5A54),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isMine
                ? context.l10n.thisRequestBelongsToYou
                : canChangeStatus
                ? context.l10n.youCanManageThisRequestStatus
                : context.l10n.openChatWithSellerBehindRequest,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A746C)),
          ),
          const SizedBox(height: 12),
          if (isMine)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewTap,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(context.l10n.viewRequest),
                ),
                FilledButton.tonalIcon(
                  onPressed: onChangeStatusTap,
                  icon: const Icon(Icons.flag_circle_outlined),
                  label: Text(context.l10n.changeStatus),
                ),
                OutlinedButton.icon(
                  onPressed: onEditTap,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(context.l10n.edit),
                ),
                FilledButton.tonalIcon(
                  onPressed: isDeleteLoading ? null : onDeleteTap,
                  style: FilledButton.styleFrom(
                    //   foregroundColor: const Color(0xFF9F2D2D),
                  ),
                  icon: Icon(
                    isDeleteLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.delete_outline_rounded,
                  ),
                  label: Text(
                    isDeleteLoading
                        ? context.l10n.deleting
                        : context.l10n.delete,
                  ),
                ),
              ],
            )
          else if (canChangeStatus)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewTap,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(context.l10n.viewRequest),
                ),
                FilledButton.tonalIcon(
                  onPressed: onChangeStatusTap,
                  icon: const Icon(Icons.flag_circle_outlined),
                  label: Text(context.l10n.changeStatus),
                ),
                FilledButton.icon(
                  onPressed: isChatLoading ? null : onChatTap,
                  icon: Icon(
                    isChatLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.chat_bubble_outline_rounded,
                  ),
                  label: Text(
                    isChatLoading
                        ? context.l10n.opening
                        : context.l10n.chat,
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
                    onPressed: onViewTap,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(context.l10n.viewRequest),
                  ),
                  FilledButton.icon(
                    onPressed: isChatLoading ? null : onChatTap,
                    icon: Icon(
                      isChatLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.chat_bubble_outline_rounded,
                    ),
                    label: Text(
                      isChatLoading
                          ? context.l10n.opening
                          : context.l10n.chat,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
    return 'request-image-${request.id ?? 'new'}-$index';
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

class _RequesterSummary extends StatelessWidget {
  const _RequesterSummary({
    required this.name,
    required this.avatarUrl,
    required this.fallbackLabel,
    this.onTap,
  });

  final String? name;
  final String? avatarUrl;
  final String fallbackLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : fallbackLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          label: displayName,
          imageUrl: avatarUrl,
          radius: 20,
          onTap: onTap,
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: TextButton(
            onPressed: onTap,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0C4A63),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        _RequestImageSkeleton(
          key: ValueKey('request-image-skeleton-$requestId-$imageIndex'),
        ),
        Image.network(
          imageUrl,
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
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
          Icon(icon, size: 16, color: const Color(0xFF0C4A63)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFF5F5A54)),
          ),
        ],
      ),
    );
  }
}
