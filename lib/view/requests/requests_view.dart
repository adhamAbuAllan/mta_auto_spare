import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../common_widgets/async_error_message.dart';
import '../common_widgets/empty_state_card.dart';
import '../profile/user_profile_page.dart';
import 'create_request_page.dart';
import 'request_post_page.dart';
import 'widgets/request_card.dart';
import 'widgets/request_status_sheet.dart';

class RequestsViewController {
  _RequestsViewState? _state;

  Future<void> scrollToTopAndRefresh() async {
    await _state?._scrollToTopAndRefresh();
  }

  void _attach(_RequestsViewState state) {
    _state = state;
  }

  void _detach(_RequestsViewState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

class RequestsView extends ConsumerStatefulWidget {
  const RequestsView({
    super.key,
    required this.wideMode,
    required this.onOpenConversation,
    this.controller,
  });

  final bool wideMode;
  final ValueChanged<int> onOpenConversation;
  final RequestsViewController? controller;

  @override
  ConsumerState<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<RequestsView> {
  static const _scrollActivityWindow = Duration(milliseconds: 350);
  static const _slowFrameThreshold = Duration(milliseconds: 20);

  int? _pendingChatRequestId;
  int? _deletingRequestId;
  int? _updatingStatusRequestId;
  DateTime? _lastScrollActivityAt;
  DateTime? _lastPerformanceLogAt;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.controller?._attach(this);
    if (kDebugMode) {
      SchedulerBinding.instance.addTimingsCallback(_handleFrameTimings);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final requestState = ref.read(requestsNotifierProvider);
      if (requestState.requests.isEmpty && !requestState.isLoading) {
        ref.read(requestsNotifierProvider.notifier).load();
      }
    });
  }

  @override
  void didUpdateWidget(covariant RequestsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller?._detach(this);
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _scrollController.dispose();
    if (kDebugMode) {
      SchedulerBinding.instance.removeTimingsCallback(_handleFrameTimings);
    }
    super.dispose();
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
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: CustomScrollView(
            controller: _scrollController,
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
                            selected:
                                requestState.selectedStatusId == status.id,
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
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      _lastScrollActivityAt = DateTime.now();
    }
    return false;
  }

  void _handleFrameTimings(List<FrameTiming> timings) {
    final lastScrollActivityAt = _lastScrollActivityAt;
    if (lastScrollActivityAt == null ||
        DateTime.now().difference(lastScrollActivityAt) >
            _scrollActivityWindow) {
      return;
    }

    for (final timing in timings) {
      final isSlowFrame =
          timing.totalSpan >= _slowFrameThreshold ||
          timing.buildDuration >= _slowFrameThreshold ||
          timing.rasterDuration >= _slowFrameThreshold;
      if (!isSlowFrame) {
        continue;
      }

      final now = DateTime.now();
      if (_lastPerformanceLogAt != null &&
          now.difference(_lastPerformanceLogAt!) <
              const Duration(milliseconds: 250)) {
        return;
      }
      _lastPerformanceLogAt = now;

      debugPrint(
        '[Requests][Performance] Slow scroll frame: '
        'total=${_milliseconds(timing.totalSpan)}, '
        'build=${_milliseconds(timing.buildDuration)}, '
        'raster=${_milliseconds(timing.rasterDuration)}, '
        'requests=${ref.read(activeRequestsProvider).length}',
      );
      return;
    }
  }

  String _milliseconds(Duration duration) =>
      '${(duration.inMicroseconds / 1000).toStringAsFixed(1)}ms';

  Future<void> _scrollToTopAndRefresh() async {
    if (!mounted) {
      return;
    }

    if (_scrollController.hasClients && _scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted || ref.read(requestsNotifierProvider).isLoading) {
      return;
    }

    await ref.read(requestsNotifierProvider.notifier).load();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizeErrorText(error.message, context.l10n))),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizeErrorText(error.message, context.l10n))),
      );
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
      } on ApiException {
        if (!mounted) {
          return;
        }
      } catch (_) {
        if (!mounted) {
          return;
        }
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
