import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../constants/api_constants.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/time_formatter.dart';
import '../common_widgets/zoomable_network_gallery_page.dart';

class RequestPostPage extends ConsumerStatefulWidget {
  const RequestPostPage({
    super.key,
    required this.requestId,
    this.initialRequest,
    this.sellerName,
  });

  final int requestId;
  final PartRequest? initialRequest;
  final String? sellerName;

  @override
  ConsumerState<RequestPostPage> createState() => _RequestPostPageState();
}

class _RequestPostPageState extends ConsumerState<RequestPostPage> {
  PartRequest? _request;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    if (_request == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRequest();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Post')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRequest,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_isLoading && request == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null && request == null)
                AppErrorCard(
                  message: _errorMessage!,
                  onRetry: () {
                    _loadRequest();
                  },
                )
              else if (request != null)
                _RequestPostContent(
                  request: request,
                  sellerName: widget.sellerName,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = await ref
          .read(requestApiProvider)
          .getRequestById(widget.requestId);
      ref.read(requestsNotifierProvider.notifier).upsertRequest(request);
      if (!mounted) {
        return;
      }
      setState(() {
        _request = request;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not load that request post right now.';
        _isLoading = false;
      });
    }
  }
}

class _RequestPostContent extends StatelessWidget {
  const _RequestPostContent({required this.request, this.sellerName});

  final PartRequest request;
  final String? sellerName;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrls = request.images
        .map((image) => ApiConstants.resolveUrl(image.image))
        .toList(growable: false);

    return AppPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resolvedImageUrls.isNotEmpty) ...[
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: resolvedImageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final imageUrl = resolvedImageUrls[index];
                  return GestureDetector(
                    onTap: () => _openImageGallery(
                      context,
                      resolvedImageUrls: resolvedImageUrls,
                      initialIndex: index,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          headers: const {
                            ApiConstants.ngrokHeaderKey:
                                ApiConstants.ngrokHeaderValue,
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(
                icon: Icons.storefront_outlined,
                label: (sellerName ?? '').trim().isNotEmpty
                    ? sellerName!.trim()
                    : 'Seller #${request.requester}',
              ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: formatRelativeTime(request.createdAt),
              ),
              _MetaChip(
                icon: Icons.location_on_outlined,
                label: request.city?.trim().isNotEmpty == true
                    ? request.city!.trim()
                    : 'City not set',
              ),
              if (request.minPrice != null || request.maxPrice != null)
                _MetaChip(icon: Icons.sell_outlined, label: _priceLabel()),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            request.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            request.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF5F5A54),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String _priceLabel() {
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
          heroTagBuilder: (index) => 'request-post-image-${request.id}-$index',
        ),
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
