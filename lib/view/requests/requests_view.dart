import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/request_state.dart';
import '../../localization/app_localizations_x.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/empty_state_card.dart';
import '../profile/user_profile_page.dart';
import 'create_request_page.dart';
import 'request_post_page.dart';
import 'widgets/request_card.dart';
import 'widgets/request_status_sheet.dart';

class RequestsView extends ConsumerStatefulWidget {
  const RequestsView({
    super.key,
    required this.wideMode,
    required this.onOpenConversation,
  });

  final bool wideMode;
  final ValueChanged<int> onOpenConversation;

  @override
  ConsumerState<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<RequestsView> {
  int? _pendingChatRequestId;
  int? _deletingRequestId;
  int? _updatingStatusRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final requestState = ref.read(requestsNotifierProvider);
      if (requestState.requests.isEmpty && !requestState.isLoading) {
        ref.read(requestsNotifierProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(requestsNotifierProvider);
    final currentUser = ref.watch(currentSessionProvider).profile;
    final currentUserId = currentUser?.id;
    final requestStatusesAsync = ref.watch(requestStatusesProvider);
    // final browseRequests = ref.watch(browseRequestsProvider);
    // final myRequests = ref.watch(myRequestsProvider);
    // final assignedRequests = ref.watch(assignedRequestsProvider);
    final activeRequests = ref.watch(activeRequestsProvider);

    final listBody = _buildListBody(
      context,
      requestState: requestState,
      activeRequests: activeRequests,
      currentUserId: currentUserId,
    );

    return Padding(
      padding: EdgeInsets.all(widget.wideMode ? 0 : 6),
      child: RefreshIndicator(
        onRefresh: () => ref.read(requestsNotifierProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            // SliverToBoxAdapter(
            //   child: _RequestsHero(
            //     userName: currentUser?.name ?? context.l10n.marketplaceUser,
            //     browseCount: browseRequests.length,
            //     mineCount: myRequests.length,
            //     assignedCount: assignedRequests.length,
            //   //Unused
            //   onCreateRequest: _openCreateRequest,
            //   ),
            // ),
           // const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // SliverToBoxAdapter(
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: Text(
            //           context.l10n.requests,
            //           style: Theme.of(context).textTheme.headlineSmall
            //               ?.copyWith(fontWeight: FontWeight.w900),
            //         ),
            //       ),
            //       IconButton.filledTonal(
            //         tooltip: context.l10n.refreshRequests,
            //         onPressed: requestState.isLoading
            //             ? null
            //             : () => ref
            //                   .read(requestsNotifierProvider.notifier)
            //                   .load(),
            //         icon: const Icon(Icons.refresh_rounded),
            //       ),
            //     ],
            //   ),
            // ),
            // const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // SliverToBoxAdapter(
            //   child: Text(
            //     switch (requestState.segment) {
            //       RequestSegment.browse =>
            //         context.l10n.browseRequestPostsFromOtherSellers,
            //       RequestSegment.mine => context.l10n.seeRequestPostsYouCreated,
            //       RequestSegment.assigned =>
            //         context.l10n.requestsYouCanManageNow,
            //     },
            //     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //       color: const Color(0xFF6F6A63),
            //     ),
            //   ),
            // ),
            //const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<RequestSegment>(
                  segments: [
                    ButtonSegment<RequestSegment>(
                      value: RequestSegment.browse,
                      label: Text(context.l10n.browseRequests),
                      icon: Icon(Icons.travel_explore_rounded),
                    ),
                    ButtonSegment<RequestSegment>(
                      value: RequestSegment.mine,
                      label: Text(context.l10n.myRequests),
                      icon: Icon(Icons.assignment_outlined),
                    ),
                    ButtonSegment<RequestSegment>(
                      value: RequestSegment.assigned,
                      label: Text(context.l10n.assignedRequests),
                      icon: Icon(Icons.task_alt_rounded),
                    ),
                  ],
                  selected: {requestState.segment},
                  onSelectionChanged: (selection) {
                    ref
                        .read(requestsNotifierProvider.notifier)
                        .setSegment(selection.first);
                  },
                ),
              ),
            ),
            if (requestState.segment != RequestSegment.browse) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: requestStatusesAsync.when(
                  data: (statuses) {
                    final chips = <Widget>[
                      FilterChip(
                        label: Text(context.l10n.allStatuses),
                        selected: requestState.selectedStatusId == null,
                        onSelected: (_) {
                          ref
                              .read(requestsNotifierProvider.notifier)
                              .setStatusFilter(null);
                        },
                      ),
                      for (final status in statuses)
                        FilterChip(
                          label: Text(status.label),
                          selected: requestState.selectedStatusId == status.id,
                          onSelected: (_) {
                            ref
                                .read(requestsNotifierProvider.notifier)
                                .setStatusFilter(status.id);
                          },
                        ),
                    ];
                    return SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: chips.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => chips[index],
                      ),
                    );
                  },
                  error: (_, _) => const SizedBox.shrink(),
                  loading: () => const LinearProgressIndicator(),
                ),
              ),
            ],
            if (requestState.errorMessage != null &&
                requestState.requests.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: AppErrorCard(message: requestState.errorMessage!),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            listBody,
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(
    BuildContext context, {
    required RequestState requestState,
    required List<PartRequest> activeRequests,
    required int? currentUserId,
  }) {
    if (requestState.isLoading && requestState.requests.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (requestState.errorMessage != null && requestState.requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorCard(
          message: requestState.errorMessage!,
          onRetry: () => ref.read(requestsNotifierProvider.notifier).load(),
        ),
      );
    }

    if (activeRequests.isEmpty) {
      final isMine = requestState.segment == RequestSegment.mine;
      final isAssigned = requestState.segment == RequestSegment.assigned;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyStateCard(
            title: isMine
                ? context.l10n.noRequestsYet
                : isAssigned
                ? context.l10n.noAssignedRequestsYet
                : context.l10n.noSellerRequestsYet,
            message: isMine
                ? context.l10n.createFirstRequestPostMessage
                : isAssigned
                ? context.l10n.noAssignedRequestsYetMessage
                : context.l10n.noSellerRequestsYetMessage,
            actionLabel: isMine ? context.l10n.createRequest : null,
            onAction: isMine ? _openCreateRequest : null,
            icon: isMine
                ? Icons.add_box_outlined
                : isAssigned
                ? Icons.task_alt_outlined
                : Icons.inventory_2_outlined,
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: activeRequests.length,
      itemBuilder: (context, index) {
        final request = activeRequests[index];
        final isMine =
            currentUserId != null && request.requester == currentUserId;
        final canChangeStatus = request.canUpdateStatus;
        final showStatus = requestState.segment != RequestSegment.browse;

        return RequestCard(
          request: request,
          isMine: isMine,
          canChangeStatus: canChangeStatus,
          showStatus: showStatus,
          isChatLoading: _pendingChatRequestId == request.id,
          isDeleteLoading: _deletingRequestId == request.id,
          onViewTap: () => _openRequest(request),
          onChatTap: () => _startConversation(request),
          onChangeStatusTap: canChangeStatus
              ? () => _changeRequestStatus(request)
              : null,
          onEditTap: isMine ? () => _openEditRequest(request) : null,
          onDeleteTap: isMine ? () => _confirmDeleteRequest(request) : null,
          onRequesterTap: () => _openUserProfile(request.requester),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 14),
    );
  }

  Future<void> _openCreateRequest() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreateRequestPage()));
  }

  Future<void> _openEditRequest(PartRequest request) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateRequestPage(initialRequest: request),
      ),
    );
  }

  Future<void> _openRequest(PartRequest request) async {
    final requestId = request.id;
    if (requestId == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestPostPage(
          requestId: requestId,
          initialRequest: request,
          sellerName: request.requesterDetails?.name,
        ),
      ),
    );
  }

  Future<void> _openUserProfile(int userId) async {
    if (userId <= 0) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserProfilePage(userId: userId)),
    );
  }

  Future<void> _confirmDeleteRequest(PartRequest request) async {
    final requestId = request.id;
    if (requestId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.deleteRequest),
          content: Text(
            context.l10n.deleteRequestConfirmation(request.displayTitle),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() => _deletingRequestId = requestId);

    try {
      await ref.read(requestApiProvider).deleteRequest(requestId);
      ref.read(requestsNotifierProvider.notifier).removeRequestById(requestId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.requestDeletedSuccessfully)),
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
        SnackBar(content: Text(context.l10n.couldNotDeleteRequest)),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingRequestId = null);
      }
    }
  }

  Future<void> _changeRequestStatus(PartRequest request) async {
    final requestId = request.id;
    if (requestId == null || _updatingStatusRequestId != null) {
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

      setState(() => _updatingStatusRequestId = requestId);
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
        setState(() => _updatingStatusRequestId = null);
      }
    }
  }

  Future<void> _startConversation(PartRequest request) async {
    final currentUserId = ref.read(currentUserIdProvider);
    final requestId = request.id;
    if (currentUserId == null ||
        request.requester == currentUserId ||
        requestId == null) {
      return;
    }

    setState(() => _pendingChatRequestId = requestId);

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

    setState(() => _pendingChatRequestId = null);

    final ensureState = ref.read(ensureConversationNotifierProvider);
    if (conversationId == null) {
      final message =
          ensureState.errorMessage ?? context.l10n.couldNotOpenConversation;
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
              '${error.message} ${context.l10n.requestAttachedResendHint}',
            ),
          ),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.initialRequestCouldNotBeSentAutomatically,
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
    widget.onOpenConversation(conversationId);
  }
}

class _RequestsHero extends StatelessWidget {
  const _RequestsHero({
    required this.userName,
    required this.browseCount,
    required this.mineCount,
    required this.assignedCount,
    required this.onCreateRequest,
  });

  final String userName;
  final int browseCount;
  final int mineCount;
  final int assignedCount;
  final VoidCallback onCreateRequest;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C4A63), Color(0xFF116466)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.welcomeBackUser(userName),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HeroStat(label: context.l10n.browse, value: '$browseCount'),
                _HeroStat(label: context.l10n.mine, value: '$mineCount'),
                _HeroStat(
                  label: context.l10n.assigned,
                  value: '$assignedCount',
                ),
              ],
            ),
            // const SizedBox(height: 18),
            // FilledButton.tonalIcon(
            //   onPressed: onCreateRequest,
            //   style: FilledButton.styleFrom(
            //     backgroundColor: Colors.white,
            //     foregroundColor: const Color(0xFF0C4A63),
            //   ),
            //   icon: const Icon(Icons.add_circle_outline_rounded),
            //   label: Text(context.l10n.createRequest),
            // ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
