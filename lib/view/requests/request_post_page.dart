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
import '../common_widgets/user_avatar.dart';
import '../common_widgets/zoomable_network_gallery_page.dart';
import '../profile/user_profile_page.dart';
import 'widgets/request_status_sheet.dart';

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
  bool _isUpdatingStatus = false;

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
    final canChangeStatus = request?.canUpdateStatus == true;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.viewRequest)),
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
                  canChangeStatus: canChangeStatus,
                  isChatLoading: _isOpeningChat,
                  isStatusUpdating: _isUpdatingStatus,
                  onChatTap: canChat
                      ? () => _openChatForRequest(request)
                      : null,
                  onChangeStatusTap: canChangeStatus
                      ? () => _changeRequestStatus(request)
                      : null,
                  onRequesterTap: () =>
                      _openRequesterProfile(request.requester),
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
        translatedTitle: request.translatedTitle,
        titleLanguage: request.titleLanguage,
        minPrice: request.minPrice,
        maxPrice: request.maxPrice,
        carModel: request.carModel,
        translationTargetLanguage: request.translationTargetLanguage,
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

  Future<void> _changeRequestStatus(PartRequest request) async {
    final requestId = request.id;
    if (requestId == null || _isUpdatingStatus) {
      return;
    }

    try {
      final statuses = await ref.read(requestStatusesProvider.future);
      if (!mounted) {
        return;
      }

      final selectedStatus = await showRequestStatusSheet(
        context,
        statuses: statuses,
        request: request,
      );
      if (!mounted ||
          selectedStatus == null ||
          selectedStatus.id == null ||
          selectedStatus.id == request.status) {
        return;
      }

      setState(() => _isUpdatingStatus = true);
      final updatedRequest = await ref
          .read(requestApiProvider)
          .updateRequestStatus(
            requestId: requestId,
            statusId: selectedStatus.id!,
          );
      ref.read(requestsNotifierProvider.notifier).upsertRequest(updatedRequest);
      if (!mounted) {
        return;
      }
      setState(() => _request = updatedRequest);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.requestStatusUpdated)),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotUpdateRequestStatus)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _openRequesterProfile(int userId) async {
    if (userId <= 0) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserProfilePage(userId: userId)),
    );
  }
}

class _RequestPostContent extends StatelessWidget {
  const _RequestPostContent({
    required this.request,
    required this.canChat,
    required this.canChangeStatus,
    required this.isChatLoading,
    required this.isStatusUpdating,
    this.onChatTap,
    this.onChangeStatusTap,
    this.onRequesterTap,
    this.sellerName,
  });

  final PartRequest request;
  final bool canChat;
  final bool canChangeStatus;
  final bool isChatLoading;
  final bool isStatusUpdating;
  final VoidCallback? onChatTap;
  final VoidCallback? onChangeStatusTap;
  final VoidCallback? onRequesterTap;
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
          Row(
            children: [
              UserAvatar(
                label: _sellerDisplayName,
                imageUrl: request.requesterDetails?.avatar,
                radius: 22,
                onTap: onRequesterTap,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: onRequesterTap,
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _sellerDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0C4A63),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: formatRelativeTime(request.createdAt, context.l10n),
              ),
              if (canChangeStatus && request.statusDetails != null)
                _MetaChip(
                  icon: Icons.flag_outlined,
                  label: request.statusDetails!.label,
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
          _TranslatedRequestCopy(request: request),
          const SizedBox(height: 20),
          Text(
            canChat
                ? 'Open a chat with the seller behind this request.'
                : canChangeStatus
                ? context.l10n.youCanManageThisRequestStatus
                : context.l10n.thisRequestBelongsToYou,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A746C)),
          ),
          if (canChangeStatus) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: isStatusUpdating ? null : onChangeStatusTap,
                icon: Icon(
                  isStatusUpdating
                      ? Icons.hourglass_top_rounded
                      : Icons.flag_circle_outlined,
                ),
                label: Text(
                  isStatusUpdating
                      ? context.l10n.updatingStatus
                      : context.l10n.changeStatus,
                ),
              ),
            ),
          ],
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
                label: Text(
                  isChatLoading
                      ? context.l10n.opening
                      : context.l10n.chat,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _sellerDisplayName {
    if (request.requesterDetails?.name.trim().isNotEmpty == true) {
      return request.requesterDetails!.name.trim();
    }
    if ((sellerName ?? '').trim().isNotEmpty) {
      return sellerName!.trim();
    }
    return 'Seller #${request.requester}';
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

class _TranslatedRequestCopy extends StatefulWidget {
  const _TranslatedRequestCopy({required this.request});

  final PartRequest request;

  @override
  State<_TranslatedRequestCopy> createState() => _TranslatedRequestCopyState();
}

class _TranslatedRequestCopyState extends State<_TranslatedRequestCopy> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final l10n = context.l10n;
    final showOriginal = _showOriginal && request.hasTranslatedContent;
    final title = showOriginal ? request.title : request.displayTitle;
    final description = showOriginal
        ? request.description
        : request.displayDescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF5F5A54),
            height: 1.45,
          ),
        ),
        if (request.hasTranslatedContent) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showOriginal = !_showOriginal;
                });
              },
              child: Text(
                _showOriginal ? l10n.showTranslation : l10n.showOriginal,
              ),
            ),
          ),
        ],
      ],
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
