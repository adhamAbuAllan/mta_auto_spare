import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/system_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../notifications/app_update_service.dart';

class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate>
    with WidgetsBindingObserver {
  String? _shownUpdateKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdate());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForUpdate());
    }
  }

  Future<void> _checkForUpdate() async {
    final update = await ref.read(appUpdateServiceProvider).checkForUpdate();
    if (!mounted ||
        update == null ||
        _shownUpdateKey == update.notificationKey) {
      return;
    }
    _shownUpdateKey = update.notificationKey;
    _showUpdateBanner(update);
  }

  void _showUpdateBanner(ResolvedAppUpdate update) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.system_update_rounded),
        content: Text(
          update.info.message?.trim().isNotEmpty == true
              ? update.info.message!.trim()
              : l10n.appUpdateAvailableMessage,
        ),
        actions: [
          if (!update.info.updateRequired)
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: Text(l10n.later),
            ),
          FilledButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              unawaited(_openStore(update));
            },
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore(ResolvedAppUpdate update) async {
    try {
      await ref.read(appUpdateServiceProvider).openStore(update);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenAppStore)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
