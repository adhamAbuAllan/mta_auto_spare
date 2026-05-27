import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mta_auto_spare/view/requests/create_request_page.dart';

import '../controllers/providers/auth_provider.dart';
import '../controllers/providers/chat_provider.dart';
import '../controllers/providers/notification_provider.dart';
import '../controllers/providers/request_provider.dart';
import '../controllers/statuses/request_state.dart';
import '../localization/app_localizations_x.dart';
import '../models/models.dart';
import '../notifications/chat_notification_service.dart';
import '../view/admin/admin_panel_page.dart';
import '../view/chat/chat_detail_page.dart';
import '../view/chat/conversations_view.dart';
import '../view/common_widgets/app_panel.dart';
import '../view/profile/edit_profile_page.dart';
import '../view/requests/request_post_page.dart';
import '../view/requests/requests_view.dart';

class MarketplaceShellPage extends ConsumerStatefulWidget {
  const MarketplaceShellPage({super.key});

  @override
  ConsumerState<MarketplaceShellPage> createState() =>
      _MarketplaceShellPageState();
}

class _MarketplaceShellPageState extends ConsumerState<MarketplaceShellPage> {
  int _mobileIndex = 0;
  ProviderSubscription<ChatNotificationNavigationRequest?>?
  _notificationSubscription;

  @override
  void initState() {
    super.initState();
    ref.read(conversationsNotifierProvider.notifier);
    _notificationSubscription = ref
        .listenManual<ChatNotificationNavigationRequest?>(
          chatNotificationNavigationRequestProvider,
          (previous, next) {
            if (next == null) {
              return;
            }
            _queueNotificationRoute(next);
          },
        );
    final pendingRequest = ref.read(chatNotificationNavigationRequestProvider);
    if (pendingRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _queueNotificationRoute(pendingRequest);
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.close();
    _notificationSubscription = null;
    super.dispose();
  }

  void _queueNotificationRoute(ChatNotificationNavigationRequest request) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(chatNotificationNavigationRequestProvider.notifier).state = null;
      final isWide = MediaQuery.sizeOf(context).width >= 980;
      final requestId = request.requestId;
      if (requestId != null) {
        if (!isWide) {
          setState(() => _mobileIndex = 0);
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RequestPostPage(
              requestId: requestId,
              initialRequest: _findRequestById(requestId),
              sellerName: request.sellerName,
            ),
          ),
        );
        return;
      }
      final conversationId = request.conversationId;
      if (conversationId == null) {
        return;
      }
      if (isWide) {
        ref.read(selectedConversationIdProvider.notifier).state =
            conversationId;
        return;
      }
      setState(() => _mobileIndex = 1);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatDetailPage(conversationId: conversationId),
        ),
      );
    });
  }

  PartRequest? _findRequestById(int requestId) {
    for (final request in ref.read(requestsNotifierProvider).requests) {
      if (request.id == requestId) {
        return request;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final isAdmin = session.profile?.isAdmin ?? false;
        return isWide
            ? _WideMarketplaceLayout(
                userName: session.profile?.name ?? context.l10n.userRole,
                isAdmin: isAdmin,
              )
            : _MobileMarketplaceLayout(
                index: _mobileIndex,
                userName: session.profile?.name ?? context.l10n.userRole,
                isAdmin: isAdmin,
                onDestinationSelected: (index) {
                  setState(() => _mobileIndex = index);
                },
              );
      },
    );
  }
}

class _WideMarketplaceLayout extends ConsumerWidget {
  const _WideMarketplaceLayout({required this.userName, required this.isAdmin});

  final String userName;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversationId = ref.watch(selectedConversationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle,style: TextStyle(fontWeight: FontWeight.w800),),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Center(
              child: Text(
                userName,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
            ),
          ),
          if (isAdmin)
            IconButton(
              tooltip: context.l10n.adminPanel,
              onPressed: () => _openAdminPanel(context),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: context.l10n.editProfile,
            onPressed: () => _openEditProfile(context),
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
          TextButton(
            onPressed: () => ref.read(logoutNotifierProvider.notifier).logout(),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(context.l10n.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: const Color(0xFFF6F0E8),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: RequestsView(
                wideMode: true,
                onOpenConversation: (conversationId) {
                  ref.read(selectedConversationIdProvider.notifier).state =
                      conversationId;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 9,
              child: AppPanel(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: selectedConversationId == null
                      ? ConversationsView(
                          key: const ValueKey('conversations-list'),
                          wideMode: true,
                          onOpenConversation: (conversationId) {
                            ref
                                    .read(
                                      selectedConversationIdProvider.notifier,
                                    )
                                    .state =
                                conversationId;
                          },
                        )
                      : ChatDetailPage(
                          key: ValueKey('chat-$selectedConversationId'),
                          conversationId: selectedConversationId,
                          onBack: () {
                            ref
                                    .read(
                                      selectedConversationIdProvider.notifier,
                                    )
                                    .state =
                                null;
                          },
                          wideMode: true,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfilePage()));
  }

  void _openAdminPanel(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminPanelPage()));
  }
}

class _MobileMarketplaceLayout extends ConsumerWidget {
  const _MobileMarketplaceLayout({
    required this.index,
    required this.userName,
    required this.isAdmin,
    required this.onDestinationSelected,
  });

  final int index;
  final String userName;
  final bool isAdmin;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Center(
              child: Text(
                userName,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
            ),
          ),
          if (isAdmin)
            IconButton(
              tooltip: context.l10n.adminPanel,
              onPressed: () => _openAdminPanel(context),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: context.l10n.editProfile,
            onPressed: () => _openEditProfile(context),
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
          IconButton(
            tooltip: context.l10n.logout,
            onPressed: () => ref.read(logoutNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF6F0E8),
        child: IndexedStack(
          index: index,
          children: [
            RequestsView(
              wideMode: false,
              onOpenConversation: (conversationId) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ChatDetailPage(conversationId: conversationId),
                  ),
                );
              },
            ),
            CreateRequestPage(
              onNavigateToMyRequests: () {
                ref
                    .read(requestsNotifierProvider.notifier)
                    .setSegment(RequestSegment.mine);
                onDestinationSelected(0);
              },
            ),
            ConversationsView(
              wideMode: false,
              onOpenConversation: (conversationId) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ChatDetailPage(conversationId: conversationId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: context.l10n.requests,
          ),
          NavigationDestination(icon: Icon(Icons.add),
              label: context.l10n.add),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),

            label: context.l10n.chats,
          ),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfilePage()));
  }

  void _openAdminPanel(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminPanelPage()));
  }
}
