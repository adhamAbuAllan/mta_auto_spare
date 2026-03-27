import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/providers/auth_provider.dart';
import '../view/auth/login_page.dart';
import 'marketplace_shell.dart';

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session.isAuthenticated) {
      return const MarketplaceShellPage();
    }
    return const LoginPage();
  }
}
