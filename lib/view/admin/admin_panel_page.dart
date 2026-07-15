import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../controllers/providers/api_provider.dart';
import '../../controllers/providers/auth_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../models/models.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/app_panel.dart';
import '../common_widgets/time_formatter.dart';

class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
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

  @override
  void initState() {
    super.initState();
    _refreshAll();
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.adminPanel),
          bottom: TabBar(
            unselectedLabelColor: Colors.grey,
            labelColor: Colors.white,
            tabs: [
              Tab(text: context.l10n.adminUsersTab),
              Tab(text: context.l10n.adminReportsTab),
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
            children: [_buildUsersTab(context), _buildReportsTab(context)],
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
    await Future.wait([_refreshUsers(), _refreshReports()]);
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
          .getUsers(pageUrl: reset ? null : _usersNextPage);
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
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
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
  });

  final ApiUser user;
  final bool isBusy;
  final bool isCurrentUser;
  final String roleLabel;
  final String statusLabel;
  final VoidCallback onBlockToggle;

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

class _ReportReviewDraft {
  const _ReportReviewDraft({required this.status, required this.notes});

  final String status;
  final String notes;
}
