import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers/auth_provider.dart';
import '../controllers/providers/chat_provider.dart';
import '../view/chat/chat_detail_page.dart';
import '../view/chat/conversations_view.dart';
import '../view/common_widgets/app_panel.dart';
import '../view/requests/requests_view.dart';

class MarketplaceShellPage extends ConsumerStatefulWidget {
  const MarketplaceShellPage({super.key});

  @override
  ConsumerState<MarketplaceShellPage> createState() =>
      _MarketplaceShellPageState();
}

class _MarketplaceShellPageState extends ConsumerState<MarketplaceShellPage> {
  int _mobileIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        return isWide
            ? _WideMarketplaceLayout(userName: session.profile?.name ?? 'User')
            : _MobileMarketplaceLayout(
                index: _mobileIndex,
                userName: session.profile?.name ?? 'User',
                onDestinationSelected: (index) {
                  setState(() => _mobileIndex = index);
                },
              );
      },
    );
  }
}

class _WideMarketplaceLayout extends ConsumerWidget {
  const _WideMarketplaceLayout({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversationId = ref.watch(selectedConversationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Spare Hub'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                userName,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(logoutNotifierProvider.notifier).logout(),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Logout'),
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
}

class _MobileMarketplaceLayout extends ConsumerWidget {
  const _MobileMarketplaceLayout({
    required this.index,
    required this.userName,
    required this.onDestinationSelected,
  });

  final int index;
  final String userName;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Spare Hub'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                userName,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}
