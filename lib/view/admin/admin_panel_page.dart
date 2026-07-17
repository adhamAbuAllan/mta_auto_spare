import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/async_error_message.dart';
import '../common_widgets/time_formatter.dart';

class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
  final TextEditingController _userSearchController = TextEditingController();
  String _userStatusFilter = '';

  AdminDashboardSummary? _dashboard;
  String? _dashboardError;
  bool _isLoadingDashboard = true;

  List<ApiUser> _users = const [];
  String? _usersNextPage;
  String? _usersError;
  bool _isLoadingUsers = true;
  bool _isLoadingMoreUsers = false;
  bool _isUpdatingUser = false;

  List<UserReportEntry> _reports = const [];
  String? _reportsNextPage;
  String? _reportsError;
  bool _isLoadingReports = true;
  bool _isLoadingMoreReports = false;
  bool _isUpdatingReport = false;

  List<PartRequest> _adminRequests = const [];
  List<PartRequestStatus> _requestStatuses = const [];
  String? _adminRequestsNextPage;
  String? _adminRequestsError;
  bool _isLoadingAdminRequests = true;
  bool _isLoadingMoreAdminRequests = false;
  bool _isUpdatingAdminRequest = false;

  List<CarMakeOption> _catalogMakes = const [];
  List<SparePart> _catalogParts = const [];
  String? _catalogError;
  bool _isLoadingCatalog = true;

  List<ConversationListItem> _adminConversations = const [];
  String? _adminConversationsError;
  bool _isLoadingAdminConversations = true;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final isAdmin = session.profile?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.adminPanel)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [AppErrorCard(message: context.l10n.adminAccessRequired)],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.adminPanel),
          bottom: TabBar(
            unselectedLabelColor: Colors.grey,
            labelColor: Colors.white,
            tabs: [
              Tab(text: context.l10n.adminDashboardTab),
              Tab(text: context.l10n.adminUsersTab),
              Tab(text: context.l10n.adminRequests),
              Tab(text: context.l10n.adminCatalog),
              Tab(text: context.l10n.adminReportsTab),
              Tab(text: context.l10n.chats),
            ],
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.refreshRequests,
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Container(
          color: const Color(0xFFF6F0E8),
          child: TabBarView(
            children: [
              _buildDashboardTab(context),
              _buildUsersTab(context),
              _buildAdminRequestsTab(context),
              _buildCatalogTab(context),
              _buildReportsTab(context),
              _buildAdminChatsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    if (_isLoadingUsers && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usersError != null && _users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            AppErrorCard(message: _usersError!, onRetry: _refreshUsers),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _userSearchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _refreshUsers(),
            decoration: InputDecoration(
              labelText: context.l10n.adminSearchUsers,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: context.l10n.adminSearchUsers,
                onPressed: _refreshUsers,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _userFilterChip(
                context,
                label: context.l10n.adminUserStatusAll,
                value: '',
              ),
              _userFilterChip(
                context,
                label: context.l10n.userActiveStatus,
                value: 'active',
              ),
              _userFilterChip(
                context,
                label: context.l10n.userBlockedStatus,
                value: 'blocked',
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final user in _users) ...[
            _AdminUserCard(
              user: user,
              isBusy: _isUpdatingUser,
              isCurrentUser:
                  (ref.read(currentSessionProvider).profile?.id ?? 0) ==
                  user.id,
              roleLabel: _roleLabel(context, user),
              statusLabel: _userStatusLabel(context, user),
              onBlockToggle: () => _handleUserBlockToggle(user),
              onManage: () => _showUserDetails(user),
            ),
            const SizedBox(height: 14),
          ],
          if (_usersNextPage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton.icon(
                onPressed: _isLoadingMoreUsers ? null : _loadMoreUsers,
                icon: Icon(
                  _isLoadingMoreUsers
                      ? Icons.hourglass_top_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  _isLoadingMoreUsers
                      ? context.l10n.loading
                      : context.l10n.loadMore,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _userFilterChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: _userStatusFilter == value,
      onSelected: (_) {
        if (_userStatusFilter == value) {
          return;
        }
        setState(() => _userStatusFilter = value);
        _refreshUsers();
      },
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    if (_isLoadingReports && _reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reportsError != null && _reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            AppErrorCard(message: _reportsError!, onRetry: _refreshReports),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (_reports.isEmpty)
            AppPanel(
              child: Text(
                context.l10n.noUserReportsYet,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6F6A63)),
              ),
            )
          else
            for (final report in _reports) ...[
              _AdminReportCard(
                report: report,
                isBusy: _isUpdatingReport,
                statusLabel: _reportStatusLabel(context, report.status),
                onReview: () => _reviewReport(report),
              ),
              const SizedBox(height: 14),
            ],
          if (_reportsNextPage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton.icon(
                onPressed: _isLoadingMoreReports ? null : _loadMoreReports,
                icon: Icon(
                  _isLoadingMoreReports
                      ? Icons.hourglass_top_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  _isLoadingMoreReports
                      ? context.l10n.loading
                      : context.l10n.loadMore,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshDashboard(),
      _refreshUsers(),
      _refreshAdminRequests(),
      _refreshCatalog(),
      _refreshReports(),
      _refreshAdminConversations(),
    ]);
  }

  Future<void> _refreshAdminConversations() async {
    setState(() {
      _isLoadingAdminConversations = true;
      _adminConversationsError = null;
    });
    try {
      final conversations = await ref
          .read(chatApiProvider)
          .getAllConversations();
      if (mounted) {
        setState(() => _adminConversations = conversations);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _adminConversationsError = _errorMessage(
            error,
            context.l10n.couldNotOpenChatRightNow,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAdminConversations = false);
      }
    }
  }

  Widget _buildAdminChatsTab(BuildContext context) {
    if (_isLoadingAdminConversations && _adminConversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_adminConversationsError != null && _adminConversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshAdminConversations,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            AppErrorCard(
              message: _adminConversationsError!,
              onRetry: _refreshAdminConversations,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshAdminConversations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (_adminConversations.isEmpty)
            AppPanel(child: Text(context.l10n.chats))
          else
            for (final conversation in _adminConversations) ...[
              AppPanel(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    conversation.title.trim().isEmpty
                        ? '#${conversation.id}'
                        : conversation.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    conversation.lastMessage?.text.trim().isNotEmpty == true
                        ? conversation.lastMessage!.text.trim()
                        : context.l10n.chats,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: context.l10n.chatAction,
                    onPressed: () => _showAdminConversation(conversation),
                    icon: const Icon(Icons.forum_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Future<void> _showAdminConversation(ConversationListItem conversation) async {
    try {
      final page = await ref
          .read(chatApiProvider)
          .getMessages(conversationId: conversation.id);
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _AdminConversationSheet(
          conversation: conversation,
          messages: page.results,
          onDeleteMessage: (message) async {
            await ref
                .read(chatApiProvider)
                .deleteMessage(messageId: message.id, scope: 'all');
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            if (mounted) {
              await _refreshAdminConversations();
            }
          },
        ),
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          _errorMessage(error, context.l10n.couldNotOpenChatRightNow),
        );
      }
    }
  }

  Future<void> _refreshCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });
    try {
      final catalogApi = ref.read(catalogApiProvider);
      final results = await Future.wait([
        catalogApi.getAllCarMakes(),
        catalogApi.getAllSpareParts(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _catalogMakes = results[0] as List<CarMakeOption>;
        _catalogParts = results[1] as List<SparePart>;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _catalogError = _errorMessage(
            error,
            context.l10n.adminCatalogCouldNotLoad,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCatalog = false);
      }
    }
  }

  Widget _buildCatalogTab(BuildContext context) {
    if (_isLoadingCatalog && _catalogMakes.isEmpty && _catalogParts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_catalogError != null &&
        _catalogMakes.isEmpty &&
        _catalogParts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshCatalog,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            AppErrorCard(message: _catalogError!, onRetry: _refreshCatalog),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshCatalog,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.adminCatalog,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: context.l10n.adminAddMake,
                onPressed: _showCreateMakeDialog,
                icon: const Icon(Icons.directions_car_outlined),
              ),
              IconButton(
                tooltip: context.l10n.adminAddSparePart,
                onPressed: _showCreateSparePartDialog,
                icon: const Icon(Icons.add_box_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final make in _catalogMakes) ...[
            _AdminCatalogMakeCard(
              make: make,
              onAddModel: () => _showCreateModelDialog(make),
              onEditMake: () => _showEditMakeDialog(make),
              onDeleteMake: () => _deleteMake(make),
              onEditModel: (model) => _showEditModelDialog(make, model),
              onDeleteModel: _deleteModel,
            ),
            const SizedBox(height: 12),
          ],
          if (_catalogParts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.adminSpareParts,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (final part in _catalogParts) ...[
              _AdminSparePartCard(
                part: part,
                onEdit: () => _showEditSparePartDialog(part),
                onDelete: () => _deleteSparePart(part),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _showCreateSparePartDialog() async {
    final name = TextEditingController();
    final description = TextEditingController();
    final price = TextEditingController();
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.adminAddSparePart),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: context.l10n.adminItemName,
                ),
              ),
              TextField(
                controller: description,
                decoration: InputDecoration(
                  labelText: context.l10n.adminItemDescription,
                ),
              ),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.adminItemPrice,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.save),
            ),
          ],
        ),
      );
      if (accepted != true ||
          name.text.trim().isEmpty ||
          price.text.trim().isEmpty) {
        return;
      }
      await ref
          .read(catalogApiProvider)
          .createSparePart(
            name: name.text,
            description: description.text,
            price: price.text,
          );
      if (mounted) {
        await _refreshCatalog();
      }
    } finally {
      name.dispose();
      description.dispose();
      price.dispose();
    }
  }

  Future<void> _showEditSparePartDialog(SparePart part) async {
    if (part.id == null) {
      return;
    }
    final name = TextEditingController(text: part.name);
    final description = TextEditingController(text: part.description);
    final price = TextEditingController(text: part.price);
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.adminAddSparePart),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: context.l10n.adminItemName,
                ),
              ),
              TextField(
                controller: description,
                decoration: InputDecoration(
                  labelText: context.l10n.adminItemDescription,
                ),
              ),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.adminItemPrice,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.save),
            ),
          ],
        ),
      );
      if (accepted != true ||
          name.text.trim().isEmpty ||
          price.text.trim().isEmpty) {
        return;
      }
      await ref
          .read(catalogApiProvider)
          .updateSparePart(
            SparePart(
              id: part.id,
              name: name.text,
              description: description.text,
              price: price.text,
              createdAt: part.createdAt,
            ),
          );
      if (mounted) {
        await _refreshCatalog();
      }
    } finally {
      name.dispose();
      description.dispose();
      price.dispose();
    }
  }

  Future<String?> _showCatalogNameDialog({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    try {
      final result = await showDialog<String>(
        context: context,
        requestFocus: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _closeCatalogDialog(dialogContext, value.trim());
              }
            },
            decoration: InputDecoration(labelText: context.l10n.adminItemName),
          ),
          actions: [
            TextButton(
              onPressed: () => _closeCatalogDialog(dialogContext),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _closeCatalogDialog(dialogContext, controller.text.trim());
                }
              },
              child: Text(context.l10n.save),
            ),
          ],
        ),
      );
      // showDialog completes when pop starts, before its reverse transition
      // has removed the dialog subtree from the active build scope.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return result;
    } finally {
      controller.dispose();
    }
  }

  void _closeCatalogDialog(BuildContext dialogContext, [String? value]) {
    FocusScope.of(dialogContext).unfocus(disposition: UnfocusDisposition.scope);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop(value);
      }
    });
  }

  Future<void> _showCreateMakeDialog() async {
    final name = await _showCatalogNameDialog(title: context.l10n.adminAddMake);
    if (name == null) {
      return;
    }
    await ref.read(catalogApiProvider).createCarMake(name);
    if (mounted) {
      await _refreshCatalog();
    }
  }

  Future<void> _showEditMakeDialog(CarMakeOption make) async {
    final name = await _showCatalogNameDialog(
      title: context.l10n.adminAddMake,
      initialValue: make.name,
    );
    if (name == null) {
      return;
    }
    await ref
        .read(catalogApiProvider)
        .updateCarMake(makeId: make.id, name: name);
    if (mounted) {
      await _refreshCatalog();
    }
  }

  Future<void> _showCreateModelDialog(CarMakeOption make) async {
    final name = await _showCatalogNameDialog(
      title: context.l10n.adminAddModel,
    );
    if (name == null) {
      return;
    }
    await ref
        .read(catalogApiProvider)
        .createCarModel(makeId: make.id, name: name);
    if (mounted) {
      await _refreshCatalog();
    }
  }

  Future<void> _showEditModelDialog(
    CarMakeOption make,
    CarModelOption model,
  ) async {
    final name = await _showCatalogNameDialog(
      title: context.l10n.adminAddModel,
      initialValue: model.name ?? model.displayName ?? '',
    );
    if (name == null || model.id == null) {
      return;
    }
    await ref
        .read(catalogApiProvider)
        .updateCarModel(
          modelId: model.id!,
          name: name,
          isActive: model.isActive ?? true,
        );
    if (mounted) {
      await _refreshCatalog();
    }
  }

  Future<void> _deleteMake(CarMakeOption make) async {
    await ref.read(catalogApiProvider).deleteCarMake(make.id);
    if (mounted) {
      await _refreshCatalog();
    }
  }

  Future<void> _deleteModel(CarModelOption model) async {
    if (model.id == null) {
      return;
    }
    await ref.read(catalogApiProvider).deleteCarModel(model.id!);
    if (mounted) {
      await _refreshCatalog();
    }
  }

  Future<void> _deleteSparePart(SparePart part) async {
    if (part.id == null) {
      return;
    }
    await ref.read(catalogApiProvider).deleteSparePart(part.id!);
    if (mounted) {
      await _refreshCatalog();
    }
  }

  Future<void> _refreshAdminRequests() async {
    await _loadAdminRequests(reset: true);
  }

  Future<void> _loadMoreAdminRequests() async {
    await _loadAdminRequests(reset: false);
  }

  Future<void> _loadAdminRequests({required bool reset}) async {
    if (!reset &&
        (_adminRequestsNextPage == null || _isLoadingMoreAdminRequests)) {
      return;
    }
    setState(() {
      if (reset) {
        _isLoadingAdminRequests = true;
        _adminRequestsError = null;
      } else {
        _isLoadingMoreAdminRequests = true;
      }
    });
    try {
      final requestApi = ref.read(requestApiProvider);
      final page = await requestApi.getRequests(
        pageUrl: reset ? null : _adminRequestsNextPage,
      );
      final statuses = reset
          ? await requestApi.getAllRequestStatuses()
          : _requestStatuses;
      if (!mounted) {
        return;
      }
      setState(() {
        _adminRequests = reset
            ? page.results
            : [..._adminRequests, ...page.results];
        _adminRequestsNextPage = page.next;
        _requestStatuses = statuses;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _adminRequestsError = _errorMessage(
          error,
          context.l10n.couldNotUpdateRequestStatus,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAdminRequests = false;
          _isLoadingMoreAdminRequests = false;
        });
      }
    }
  }

  Widget _buildAdminRequestsTab(BuildContext context) {
    if (_isLoadingAdminRequests && _adminRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_adminRequestsError != null && _adminRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshAdminRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            AppErrorCard(
              message: _adminRequestsError!,
              onRetry: _refreshAdminRequests,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAdminRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (_adminRequests.isEmpty)
            AppPanel(child: Text(context.l10n.noRequestsYet))
          else
            for (final request in _adminRequests) ...[
              _AdminRequestCard(
                request: request,
                statuses: _requestStatuses,
                isBusy: _isUpdatingAdminRequest,
                onStatusChanged: (statusId) =>
                    _updateAdminRequestStatus(request, statusId),
                onDelete: () => _deleteAdminRequest(request),
                onManageAccess: () => _showRequestAccesses(request),
              ),
              const SizedBox(height: 14),
            ],
          if (_adminRequestsNextPage != null)
            OutlinedButton.icon(
              onPressed: _isLoadingMoreAdminRequests
                  ? null
                  : _loadMoreAdminRequests,
              icon: Icon(
                _isLoadingMoreAdminRequests
                    ? Icons.hourglass_top_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(
                _isLoadingMoreAdminRequests
                    ? context.l10n.loading
                    : context.l10n.loadMore,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateAdminRequestStatus(
    PartRequest request,
    int statusId,
  ) async {
    if (_isUpdatingAdminRequest || request.id == null) {
      return;
    }
    setState(() => _isUpdatingAdminRequest = true);
    try {
      await ref
          .read(requestApiProvider)
          .updateRequestStatus(requestId: request.id!, statusId: statusId);
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.requestStatusUpdated);
      await _refreshAdminRequests();
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          _errorMessage(error, context.l10n.couldNotUpdateRequestStatus),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAdminRequest = false);
      }
    }
  }

  Future<void> _deleteAdminRequest(PartRequest request) async {
    if (_isUpdatingAdminRequest || request.id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteRequest),
        content: Text(
          context.l10n.deleteRequestConfirmation(request.displayTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.deleteRequest),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _isUpdatingAdminRequest = true);
    try {
      await ref.read(requestApiProvider).deleteRequest(request.id!);
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.requestDeletedSuccessfully);
      await _refreshAdminRequests();
    } catch (error) {
      if (mounted) {
        _showSnackBar(_errorMessage(error, context.l10n.couldNotDeleteRequest));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAdminRequest = false);
      }
    }
  }

  Future<void> _showRequestAccesses(PartRequest request) async {
    if (request.id == null) {
      return;
    }
    try {
      final accesses = await ref
          .read(requestApiProvider)
          .getRequestAccesses(partRequestId: request.id!);
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                context.l10n.expandRequestControl,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (accesses.isEmpty)
                Text(context.l10n.adminNoSupplierResponses)
              else
                for (final access in accesses)
                  _AdminAccessCard(
                    access: access,
                    isBusy: _isUpdatingAdminRequest,
                    onApprove: access.isPending
                        ? () {
                            Navigator.of(sheetContext).pop();
                            _reviewRequestAccess(access, approve: true);
                          }
                        : null,
                    onReject: access.isPending
                        ? () {
                            Navigator.of(sheetContext).pop();
                            _reviewRequestAccess(access, approve: false);
                          }
                        : null,
                  ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          _errorMessage(error, context.l10n.couldNotApproveAccessRequest),
        );
      }
    }
  }

  Future<void> _reviewRequestAccess(
    PartRequestAccess access, {
    required bool approve,
  }) async {
    if (_isUpdatingAdminRequest) {
      return;
    }
    setState(() => _isUpdatingAdminRequest = true);
    try {
      final api = ref.read(requestApiProvider);
      if (approve) {
        await api.approveRequestAccess(access.id);
      } else {
        await api.rejectRequestAccess(access.id);
      }
      if (!mounted) {
        return;
      }
      _showSnackBar(
        approve
            ? context.l10n.accessRequestApproved
            : context.l10n.accessRequestRejected,
      );
      await _refreshAdminRequests();
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          _errorMessage(
            error,
            approve
                ? context.l10n.couldNotApproveAccessRequest
                : context.l10n.couldNotRejectAccessRequest,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAdminRequest = false);
      }
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });
    try {
      final dashboard = await ref.read(userApiProvider).getAdminDashboard();
      if (!mounted) {
        return;
      }
      setState(() => _dashboard = dashboard);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboardError = _errorMessage(
          error,
          context.l10n.adminDashboardCouldNotLoad,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
      }
    }
  }

  Widget _buildDashboardTab(BuildContext context) {
    if (_isLoadingDashboard && _dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardError != null && _dashboard == null) {
      return RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 80),
            AppErrorCard(message: _dashboardError!, onRetry: _refreshDashboard),
          ],
        ),
      );
    }

    final dashboard = _dashboard!;
    final metrics = [
      (
        context.l10n.adminAccountsTotal,
        dashboard.usersTotal,
        Icons.people_alt_outlined,
        const Color(0xFFE8F4EA),
      ),
      (
        context.l10n.adminActiveUsers,
        dashboard.usersActive,
        Icons.person_outline_rounded,
        const Color(0xFFEAF4F1),
      ),
      (
        context.l10n.adminBlockedUsers,
        dashboard.usersBlocked,
        Icons.person_off_outlined,
        const Color(0xFFFFF1F1),
      ),
      (
        context.l10n.adminSuppliers,
        dashboard.suppliersTotal,
        Icons.storefront_outlined,
        const Color(0xFFFFF3E7),
      ),
      (
        context.l10n.adminOpenReports,
        dashboard.reportsOpen,
        Icons.flag_outlined,
        const Color(0xFFFFF3E7),
      ),
      (
        context.l10n.adminRequests,
        dashboard.requestsTotal,
        Icons.assignment_outlined,
        const Color(0xFFEAF4F1),
      ),
      (
        context.l10n.adminConversations,
        dashboard.conversationsTotal,
        Icons.forum_outlined,
        const Color(0xFFE8F4EA),
      ),
      (
        context.l10n.adminMessages,
        dashboard.messagesTotal,
        Icons.chat_bubble_outline_rounded,
        const Color(0xFFF2F8F7),
      ),
      (
        context.l10n.adminCatalogItems,
        dashboard.sparePartsTotal +
            dashboard.carMakesTotal +
            dashboard.carModelsTotal,
        Icons.inventory_2_outlined,
        const Color(0xFFFFF7EB),
      ),
      (
        context.l10n.adminActiveSubscriptions,
        dashboard.subscriptionsActive,
        Icons.card_membership_outlined,
        const Color(0xFFEAF4F1),
      ),
      (
        context.l10n.adminPendingPayments,
        dashboard.paymentsPending,
        Icons.payments_outlined,
        const Color(0xFFFFF3E7),
      ),
    ];

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 600
              ? 3
              : 2;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 2 ? 1.55 : 1.35,
                ),
                itemBuilder: (context, index) {
                  final metric = metrics[index];
                  return _AdminMetricCard(
                    label: metric.$1,
                    value: metric.$2,
                    icon: metric.$3,
                    tone: metric.$4,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _refreshUsers() async {
    await _loadUsers(reset: true);
  }

  Future<void> _refreshReports() async {
    await _loadReports(reset: true);
  }

  Future<void> _loadMoreUsers() async {
    await _loadUsers(reset: false);
  }

  Future<void> _loadMoreReports() async {
    await _loadReports(reset: false);
  }

  Future<void> _loadUsers({required bool reset}) async {
    if (!reset && (_usersNextPage == null || _isLoadingMoreUsers)) {
      return;
    }

    setState(() {
      if (reset) {
        _isLoadingUsers = true;
        _usersError = null;
      } else {
        _isLoadingMoreUsers = true;
      }
    });

    try {
      final page = await ref
          .read(userApiProvider)
          .getUsers(
            pageUrl: reset ? null : _usersNextPage,
            search: reset ? _userSearchController.text : null,
            status: reset ? _userStatusFilter : null,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _users = reset ? page.results : [..._users, ...page.results];
        _usersNextPage = page.next;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _usersError = _errorMessage(
          error,
          context.l10n.adminUsersCouldNotBeLoaded,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
          _isLoadingMoreUsers = false;
        });
      }
    }
  }

  Future<void> _loadReports({required bool reset}) async {
    if (!reset && (_reportsNextPage == null || _isLoadingMoreReports)) {
      return;
    }

    setState(() {
      if (reset) {
        _isLoadingReports = true;
        _reportsError = null;
      } else {
        _isLoadingMoreReports = true;
      }
    });

    try {
      final page = await ref
          .read(userApiProvider)
          .getUserReports(pageUrl: reset ? null : _reportsNextPage);
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = reset ? page.results : [..._reports, ...page.results];
        _reportsNextPage = page.next;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _reportsError = _errorMessage(
          error,
          context.l10n.adminReportsCouldNotBeLoaded,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
          _isLoadingMoreReports = false;
        });
      }
    }
  }

  Future<void> _handleUserBlockToggle(ApiUser user) async {
    final isBlocked = _isBlockedUser(user);
    if (_isUpdatingUser) {
      return;
    }

    if (isBlocked) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(context.l10n.unblockUserTitle(user.name)),
            content: Text(context.l10n.unblockUserMessage(user.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.unblockUserAction),
              ),
            ],
          );
        },
      );
      if (confirm != true) {
        return;
      }
    }

    String? reason;
    if (!isBlocked) {
      reason = await _showBlockReasonDialog(user);
      if (reason == null) {
        return;
      }
    }

    setState(() => _isUpdatingUser = true);
    try {
      if (isBlocked) {
        await ref.read(userApiProvider).unblockUser(user.id ?? 0);
      } else {
        await ref
            .read(userApiProvider)
            .blockUser(userId: user.id ?? 0, reason: reason);
      }
      if (!mounted) {
        return;
      }
      _showSnackBar(
        isBlocked ? context.l10n.userUnblocked : context.l10n.userBlocked,
      );
      await _refreshUsers();
      await _refreshReports();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(
        _errorMessage(
          error,
          isBlocked
              ? context.l10n.couldNotUnblockUser
              : context.l10n.couldNotBlockUser,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingUser = false);
      }
    }
  }

  Future<void> _showUserDetails(ApiUser user) async {
    final isCurrentUser =
        (ref.read(currentSessionProvider).profile?.id ?? 0) == user.id;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                user.name,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(user.phone ?? '#${user.id ?? '-'}'),
              const SizedBox(height: 4),
              Text(_roleLabel(sheetContext, user)),
              const SizedBox(height: 4),
              Text(_userStatusLabel(sheetContext, user)),
              const SizedBox(height: 4),
              Text(
                user.phoneVerifiedAt == null
                    ? context.l10n.adminVerifyPhone
                    : context.l10n.adminPhoneVerified,
              ),
              const SizedBox(height: 16),
              if (!isCurrentUser) ...[
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: Text(context.l10n.adminChangeRole),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _changeUserRole(user);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.password_rounded),
                  title: Text(context.l10n.adminResetPassword),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _resetUserPassword(user);
                  },
                ),
                if (user.phoneVerifiedAt == null)
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(context.l10n.adminVerifyPhone),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _verifyUserPhone(user);
                    },
                  ),
                ListTile(
                  leading: Icon(
                    _isBlockedUser(user)
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                  ),
                  title: Text(
                    _isBlockedUser(user)
                        ? context.l10n.unblockUserAction
                        : context.l10n.blockUserAction,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleUserBlockToggle(user);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeUserRole(ApiUser user) async {
    final nextRole = user.role.trim().toLowerCase() == 'supplier'
        ? 'user'
        : 'supplier';
    if (_isUpdatingUser || user.id == null) {
      return;
    }
    setState(() => _isUpdatingUser = true);
    try {
      await ref
          .read(userApiProvider)
          .setUserRole(userId: user.id!, role: nextRole);
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.adminChangeRole);
      await _refreshUsers();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_errorMessage(error, context.l10n.adminChangeRole));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingUser = false);
      }
    }
  }

  Future<void> _resetUserPassword(ApiUser user) async {
    if (_isUpdatingUser || user.id == null) {
      return;
    }
    final controller = TextEditingController();
    try {
      final password = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(context.l10n.adminResetPassword),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: context.l10n.password),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text;
                  if (value.length >= 8) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                child: Text(context.l10n.save),
              ),
            ],
          );
        },
      );
      if (password == null) {
        return;
      }
      setState(() => _isUpdatingUser = true);
      await ref
          .read(userApiProvider)
          .resetUserPassword(userId: user.id!, password: password);
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.adminResetPassword);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_errorMessage(error, context.l10n.adminResetPassword));
    } finally {
      controller.dispose();
      if (mounted) {
        setState(() => _isUpdatingUser = false);
      }
    }
  }

  Future<void> _verifyUserPhone(ApiUser user) async {
    if (_isUpdatingUser || user.id == null) {
      return;
    }
    setState(() => _isUpdatingUser = true);
    try {
      await ref.read(userApiProvider).verifyUserPhone(user.id!);
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.adminPhoneVerified);
      await _refreshUsers();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_errorMessage(error, context.l10n.adminVerifyPhone));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingUser = false);
      }
    }
  }

  Future<String?> _showBlockReasonDialog(ApiUser user) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(context.l10n.blockUserTitle(user.name)),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.blockReasonLabel,
                hintText: context.l10n.blockReasonHint,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: Text(context.l10n.blockUserAction),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _reviewReport(UserReportEntry report) async {
    if (_isUpdatingReport) {
      return;
    }

    final reviewDraft = await _showReviewDialog(report);
    if (reviewDraft == null) {
      return;
    }

    setState(() => _isUpdatingReport = true);
    try {
      await ref
          .read(userApiProvider)
          .reviewUserReport(
            reportId: report.id,
            status: reviewDraft.status,
            adminNotes: reviewDraft.notes,
          );
      if (!mounted) {
        return;
      }
      _showSnackBar(context.l10n.reportUpdated);
      await _refreshReports();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_errorMessage(error, context.l10n.couldNotUpdateReport));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingReport = false);
      }
    }
  }

  Future<_ReportReviewDraft?> _showReviewDialog(UserReportEntry report) async {
    final controller = TextEditingController(text: report.adminNotes);
    var selectedStatus = report.status;
    try {
      return await showDialog<_ReportReviewDraft>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(context.l10n.reviewReportTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: context.l10n.reportStatusLabel,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'open',
                          child: Text(context.l10n.reportStatusOpen),
                        ),
                        DropdownMenuItem(
                          value: 'reviewed',
                          child: Text(context.l10n.reportStatusReviewed),
                        ),
                        DropdownMenuItem(
                          value: 'dismissed',
                          child: Text(context.l10n.reportStatusDismissed),
                        ),
                        DropdownMenuItem(
                          value: 'actioned',
                          child: Text(context.l10n.reportStatusActioned),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.l10n.adminNotesLabel,
                        hintText: context.l10n.adminNotesHint,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(
                        _ReportReviewDraft(
                          status: selectedStatus,
                          notes: controller.text.trim(),
                        ),
                      );
                    },
                    child: Text(context.l10n.save),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  bool _isBlockedUser(ApiUser user) {
    return !user.isActive && user.blockedAt != null;
  }

  String _userStatusLabel(BuildContext context, ApiUser user) {
    if (_isBlockedUser(user)) {
      return context.l10n.userBlockedStatus;
    }
    return context.l10n.userActiveStatus;
  }

  String _reportStatusLabel(BuildContext context, String status) {
    return switch (status) {
      'reviewed' => context.l10n.reportStatusReviewed,
      'dismissed' => context.l10n.reportStatusDismissed,
      'actioned' => context.l10n.reportStatusActioned,
      _ => context.l10n.reportStatusOpen,
    };
  }

  String _roleLabel(BuildContext context, ApiUser user) {
    if (user.isAdmin) {
      return context.l10n.adminRole;
    }
    if (user.role.trim().toLowerCase() == 'supplier') {
      return context.l10n.supplierRole;
    }
    return context.l10n.userRole;
  }

  String _errorMessage(Object error, String fallback) {
    return localizeErrorMessage(error, context.l10n, fallback: fallback);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.isBusy,
    required this.isCurrentUser,
    required this.roleLabel,
    required this.statusLabel,
    required this.onBlockToggle,
    required this.onManage,
  });

  final ApiUser user;
  final bool isBusy;
  final bool isCurrentUser;
  final String roleLabel;
  final String statusLabel;
  final VoidCallback onBlockToggle;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final isBlocked = !user.isActive && user.blockedAt != null;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (user.phone ?? '').trim().isNotEmpty
                          ? user.phone!.trim()
                          : '#${user.id ?? '-'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F6A63),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AdminChip(label: roleLabel, color: const Color(0xFFEAF4F1)),
                  _AdminChip(
                    label: statusLabel,
                    color: isBlocked
                        ? const Color(0xFFFCE8E5)
                        : const Color(0xFFE8F4EA),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if ((user.phone ?? '').trim().isNotEmpty)
            Text(
              '${context.l10n.phone}: ${user.phone!.trim()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if ((user.city ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              user.city!.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if ((user.blockedReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${context.l10n.blockReasonLabel}: ${user.blockedReason!.trim()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8A2D1F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onManage,
            icon: const Icon(Icons.manage_accounts_outlined),
            label: Text(context.l10n.adminManageUser),
          ),
          const SizedBox(height: 10),
          if (isCurrentUser)
            Text(
              context.l10n.adminCurrentAccount,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6F6A63),
                fontWeight: FontWeight.w700,
              ),
            )
          else if (isBlocked)
            FilledButton.tonalIcon(
              onPressed: isBusy ? null : onBlockToggle,
              icon: Icon(
                isBusy ? Icons.hourglass_top_rounded : Icons.lock_open_rounded,
              ),
              label: Text(context.l10n.unblockUserAction),
            )
          else
            FilledButton.icon(
              onPressed: isBusy ? null : onBlockToggle,
              icon: Icon(
                isBusy ? Icons.hourglass_top_rounded : Icons.block_rounded,
              ),
              label: Text(context.l10n.blockUserAction),
            ),
        ],
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({
    required this.report,
    required this.isBusy,
    required this.statusLabel,
    required this.onReview,
  });

  final UserReportEntry report;
  final bool isBusy;
  final String statusLabel;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final reportedName =
        report.reportedUserDetails?.name.trim().isNotEmpty == true
        ? report.reportedUserDetails!.name.trim()
        : '#${report.reportedUser}';
    final reporterName = report.reporterDetails?.name.trim().isNotEmpty == true
        ? report.reporterDetails!.name.trim()
        : '#${report.reporter}';

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.reportCardTitle(reportedName),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.reportedByLabel(reporterName),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F6A63),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AdminChip(label: statusLabel, color: const Color(0xFFF4EEE4)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            report.reason,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (report.details.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.details.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            context.l10n.reportCreatedAt(
              formatRelativeTime(report.createdAt, context.l10n),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F6A63)),
          ),
          if (report.reviewedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.reportReviewedAt(
                formatRelativeTime(report.reviewedAt, context.l10n),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F6A63)),
            ),
          ],
          if (report.adminNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${context.l10n.adminNotesLabel}: ${report.adminNotes.trim()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1E5E33),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: isBusy ? null : onReview,
            icon: Icon(
              isBusy ? Icons.hourglass_top_rounded : Icons.fact_check_outlined,
            ),
            label: Text(context.l10n.reviewReportAction),
          ),
        ],
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF2C2A26),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1E5E33)),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1C1B18),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6F6A63),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({
    required this.request,
    required this.statuses,
    required this.isBusy,
    required this.onStatusChanged,
    required this.onDelete,
    required this.onManageAccess,
  });

  final PartRequest request;
  final List<PartRequestStatus> statuses;
  final bool isBusy;
  final ValueChanged<int> onStatusChanged;
  final VoidCallback onDelete;
  final VoidCallback onManageAccess;

  @override
  Widget build(BuildContext context) {
    final requester = request.requesterDetails?.name.trim().isNotEmpty == true
        ? request.requesterDetails!.name.trim()
        : '#${request.requester}';
    final statusValue = statuses.any((status) => status.id == request.status)
        ? request.status
        : null;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: isBusy ? null : onDelete,
                tooltip: context.l10n.deleteRequest,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            requester,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F6A63)),
          ),
          if ((request.city ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(request.city!.trim()),
          ],
          const SizedBox(height: 14),
          if (statusValue != null && statuses.isNotEmpty)
            DropdownButtonFormField<int>(
              initialValue: statusValue,
              decoration: InputDecoration(
                labelText: context.l10n.currentStatus,
              ),
              items: [
                for (final status in statuses)
                  DropdownMenuItem<int>(
                    value: status.id,
                    child: Text(status.label),
                  ),
              ],
              onChanged: isBusy
                  ? null
                  : (value) {
                      if (value != null && value != statusValue) {
                        onStatusChanged(value);
                      }
                    },
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onManageAccess,
            icon: const Icon(Icons.people_outline_rounded),
            label: Text(context.l10n.expandRequestControl),
          ),
        ],
      ),
    );
  }
}

class _AdminCatalogMakeCard extends StatelessWidget {
  const _AdminCatalogMakeCard({
    required this.make,
    required this.onAddModel,
    required this.onEditMake,
    required this.onDeleteMake,
    required this.onEditModel,
    required this.onDeleteModel,
  });

  final CarMakeOption make;
  final VoidCallback onAddModel;
  final VoidCallback onEditMake;
  final VoidCallback onDeleteMake;
  final ValueChanged<CarModelOption> onEditModel;
  final ValueChanged<CarModelOption> onDeleteModel;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  make.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAddModel,
                tooltip: context.l10n.adminAddModel,
                icon: const Icon(Icons.add_rounded),
              ),
              IconButton(
                onPressed: onEditMake,
                tooltip: context.l10n.save,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDeleteMake,
                tooltip: context.l10n.delete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (make.models.isEmpty)
            Text(
              context.l10n.adminNoModels,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F6A63)),
            )
          else
            Column(
              children: [
                for (final model in make.models)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(model.name ?? model.displayName ?? ''),
                    subtitle: (model.isActive ?? true)
                        ? null
                        : Text(context.l10n.userBlockedStatus),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          onPressed: () => onEditModel(model),
                          tooltip: context.l10n.save,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => onDeleteModel(model),
                          tooltip: context.l10n.delete,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AdminSparePartCard extends StatelessWidget {
  const _AdminSparePartCard({
    required this.part,
    required this.onEdit,
    required this.onDelete,
  });

  final SparePart part;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (part.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    part.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  part.price,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1E5E33),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: context.l10n.edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: context.l10n.delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _AdminAccessCard extends StatelessWidget {
  const _AdminAccessCard({
    required this.access,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final PartRequestAccess access;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final name = access.userDetails?.name.trim().isNotEmpty == true
        ? access.userDetails!.name.trim()
        : '#${access.user}';
    final statusColor = access.isAccepted
        ? const Color(0xFFE8F4EA)
        : access.isRejected
        ? const Color(0xFFFCE8E5)
        : const Color(0xFFFFF3E7);

    return AppPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _AdminChip(label: access.status, color: statusColor),
            ],
          ),
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(context.l10n.approveAccess),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(context.l10n.rejectAccess),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportReviewDraft {
  const _ReportReviewDraft({required this.status, required this.notes});

  final String status;
  final String notes;
}

class _AdminConversationSheet extends StatelessWidget {
  const _AdminConversationSheet({
    required this.conversation,
    required this.messages,
    required this.onDeleteMessage,
  });

  final ConversationListItem conversation;
  final List<MessageModel> messages;
  final Future<void> Function(MessageModel message) onDeleteMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.title.trim().isEmpty
                          ? '#${conversation.id}'
                          : conversation.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: messages.isEmpty
                  ? Center(child: Text(context.l10n.chats))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return AppPanel(
                          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.sender.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message.isDeleted
                                          ? context.l10n.deletedMessage
                                          : message.displayText.isEmpty
                                          ? message.messageType
                                          : message.displayText,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: context.l10n.delete,
                                onPressed: message.isDeleted
                                    ? null
                                    : () => onDeleteMessage(message),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
