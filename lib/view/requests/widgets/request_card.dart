import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../common_widgets/app_panel.dart';
import '../../common_widgets/time_formatter.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.isMine,
    required this.onChatTap,
    this.isChatLoading = false,
  });

  final PartRequest request;
  final bool isMine;
  final VoidCallback onChatTap;
  final bool isChatLoading;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _MetaChip(
                icon: Icons.location_on_outlined,
                label: request.city?.trim().isNotEmpty == true
                    ? request.city!
                    : 'City not set',
              ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: formatRelativeTime(request.createdAt),
              ),
              if (request.minPrice != null || request.maxPrice != null)
                _MetaChip(
                  icon: Icons.sell_outlined,
                  label: _priceLabel(request),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            request.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            request.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF5F5A54),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  isMine
                      ? 'This request belongs to you.'
                      : 'Open a chat with the seller behind this request.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7A746C),
                  ),
                ),
              ),
              if (!isMine) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: isChatLoading ? null : onChatTap,
                  icon: Icon(
                    isChatLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.chat_bubble_outline_rounded,
                  ),
                  label: Text(isChatLoading ? 'Opening...' : 'Chat Seller'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _priceLabel(PartRequest request) {
    final minPrice = request.minPrice?.trim();
    final maxPrice = request.maxPrice?.trim();

    if (minPrice != null &&
        minPrice.isNotEmpty &&
        maxPrice != null &&
        maxPrice.isNotEmpty) {
      return '$minPrice - $maxPrice';
    }
    if (minPrice != null && minPrice.isNotEmpty) {
      return 'From $minPrice';
    }
    if (maxPrice != null && maxPrice.isNotEmpty) {
      return 'Up to $maxPrice';
    }
    return 'Open budget';
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
