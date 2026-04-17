import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../constants/api_constants.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../models/models.dart';
import '../chat/chat_detail_page.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/car_model_card.dart';
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
  bool _isOpeningChat = false;

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
    final currentUserId = ref.watch(currentUserIdProvider);
    final isMine =
        request != null &&
        currentUserId != null &&
        request.requester == currentUserId;
    final canChat =
        request != null &&
        currentUserId != null &&
        !isMine &&
        request.id != null;

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
                  canChat: canChat,
                  isChatLoading: _isOpeningChat,
                  onChatTap: canChat
                      ? () => _openChatForRequest(request)
                      : null,
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

  Future<void> _openChatForRequest(PartRequest request) async {
    final currentUserId = ref.read(currentUserIdProvider);
    final requestId = request.id;
    if (currentUserId == null ||
        request.requester == currentUserId ||
        requestId == null ||
        _isOpeningChat) {
      return;
    }

    setState(() => _isOpeningChat = true);

    try {
      final conversationId = await ref
          .read(ensureConversationNotifierProvider.notifier)
          .ensureConversation(
            currentUserId: currentUserId,
            ownerUserId: request.requester,
            requestTitle: request.title,
            currentConversations: ref
                .read(conversationsNotifierProvider)
                .conversations,
          );

      if (!mounted) {
        return;
      }

      final ensureState = ref.read(ensureConversationNotifierProvider);
      if (conversationId == null) {
        final message =
            ensureState.errorMessage ?? 'Could not open the conversation.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      final requestBrief = PartRequestBrief(
        id: requestId,
        title: request.title,
        minPrice: request.minPrice,
        maxPrice: request.maxPrice,
        carModel: request.carModel,
      );
      var shouldStageSharedRequest = true;

      if (ensureState.wasCreated) {
        try {
          await ref
              .read(chatApiProvider)
              .createMessage(
                MessageCreateRequest(
                  conversation: conversationId,
                  messageType: 'product',
                  product: requestId,
                  clientTimestamp: DateTime.now().toUtc(),
                ),
              );
          shouldStageSharedRequest = false;
        } on ApiException catch (error) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${error.message} The request is attached in the chat composer so you can resend it.',
              ),
            ),
          );
        } catch (_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The chat opened, but the initial request could not be sent automatically.',
              ),
            ),
          );
        }
      }

      if (ensureState.wasCreated) {
        await ref
            .read(conversationsNotifierProvider.notifier)
            .load(forceRefresh: true);
      }

      ref.read(pendingSharedProductProvider.notifier).state =
          shouldStageSharedRequest ? requestBrief : null;
      ref.read(selectedConversationIdProvider.notifier).state = conversationId;

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatDetailPage(conversationId: conversationId),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningChat = false);
      }
    }
  }
}

class _RequestPostContent extends StatelessWidget {
  const _RequestPostContent({
    required this.request,
    required this.canChat,
    required this.isChatLoading,
    this.onChatTap,
    this.sellerName,
  });

  final PartRequest request;
  final bool canChat;
  final bool isChatLoading;
  final VoidCallback? onChatTap;
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
          if (request.carModel != null) ...[
            CarModelCard(carModel: request.carModel!, compact: true),
            const SizedBox(height: 18),
          ],
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
                label: formatRelativeTime(request.createdAt, context.l10n),
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
          const SizedBox(height: 20),
          Text(
            canChat
                ? 'Open a chat with the seller behind this request.'
                : 'This request belongs to you.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A746C)),
          ),
          if (canChat) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isChatLoading ? null : onChatTap,
                icon: Icon(
                  isChatLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.chat_bubble_outline_rounded,
                ),
                label: Text(isChatLoading ? 'Opening...' : 'Chat Seller'),
              ),
            ),
          ],
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
