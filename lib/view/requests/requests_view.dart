import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/chat_provider.dart';
import '../../controllers/providers/request_provider.dart';
import '../../controllers/statuses/request_state.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/empty_state_card.dart';
import 'create_request_page.dart';
import 'widgets/request_card.dart';

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
  int? _pendingRequestId;

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
    final browseRequests = ref.watch(browseRequestsProvider);
    final myRequests = ref.watch(myRequestsProvider);
    final activeRequests = ref.watch(activeRequestsProvider);

    final listBody = _buildListBody(
      context,
      requestState: requestState,
      activeRequests: activeRequests,
      currentUserId: currentUserId,
    );

    return Padding(
      padding: EdgeInsets.all(widget.wideMode ? 0 : 16),
      child: RefreshIndicator(
        onRefresh: () => ref.read(requestsNotifierProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _RequestsHero(
                userName: currentUser?.name ?? 'Marketplace user',
                browseCount: browseRequests.length,
                mineCount: myRequests.length,
                onCreateRequest: _openCreateRequest,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Requests',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Refresh requests',
                    onPressed: requestState.isLoading
                        ? null
                        : () => ref
                              .read(requestsNotifierProvider.notifier)
                              .load(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Text(
                requestState.segment == RequestSegment.browse
                    ? 'Browse request posts from other sellers.'
                    : 'See the request posts you created.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F6A63),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<RequestSegment>(
                  segments: const [
                    ButtonSegment<RequestSegment>(
                      value: RequestSegment.browse,
                      label: Text('Browse Requests'),
                      icon: Icon(Icons.travel_explore_rounded),
                    ),
                    ButtonSegment<RequestSegment>(
                      value: RequestSegment.mine,
                      label: Text('My Requests'),
                      icon: Icon(Icons.assignment_outlined),
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
            if (requestState.errorMessage != null &&
                requestState.requests.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: AppErrorCard(message: requestState.errorMessage!),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyStateCard(
            title: isMine ? 'No requests yet' : 'No seller requests yet',
            message: isMine
                ? 'Create your first request post and it will show up here.'
                : 'There are no request posts from other sellers yet. Pull to refresh later.',
            actionLabel: isMine ? 'Create Request' : null,
            onAction: isMine ? _openCreateRequest : null,
            icon: isMine ? Icons.add_box_outlined : Icons.inventory_2_outlined,
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

        return RequestCard(
          request: request,
          isMine: isMine,
          isChatLoading: _pendingRequestId == request.id,
          onChatTap: () => _startConversation(request),
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

  Future<void> _startConversation(PartRequest request) async {
    final currentUserId = ref.read(currentUserIdProvider);
    final requestId = request.id;
    if (currentUserId == null ||
        request.requester == currentUserId ||
        requestId == null) {
      return;
    }

    setState(() => _pendingRequestId = requestId);

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

    setState(() => _pendingRequestId = null);

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
    );
    var shouldStageSharedRequest = true;

    if (ensureState.wasCreated && requestId != null) {
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
    widget.onOpenConversation(conversationId);
  }
}

class _RequestsHero extends StatelessWidget {
  const _RequestsHero({
    required this.userName,
    required this.browseCount,
    required this.mineCount,
    required this.onCreateRequest,
  });

  final String userName;
  final int browseCount;
  final int mineCount;
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
              'Welcome back, $userName',
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
                _HeroStat(label: 'Browse', value: '$browseCount'),
                _HeroStat(label: 'Mine', value: '$mineCount'),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onCreateRequest,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0C4A63),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Create Request'),
            ),
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
