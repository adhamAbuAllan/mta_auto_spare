import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mta_auto_spare/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/providers/auth_provider.dart';
import 'controllers/providers/notification_provider.dart';
import 'firebase/firebase_bootstrap.dart';
import 'localization/app_locale.dart';
import 'localization/app_locale_notifier.dart';
import 'localization/app_localizations_x.dart';
import 'notifications/chat_notification_service.dart';
import 'routing/app_router.dart';
import 'session/session_notifier.dart';
import 'session/session_state.dart';
import 'view/common_widgets/app_update_gate.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFirebaseInitialized();
  await showChatNotificationFromFirebaseMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await ensureFirebaseInitialized();
  if (firebaseReady &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const AutoSpareApp(),
    ),
  );
}

class AutoSpareApp extends ConsumerStatefulWidget {
  const AutoSpareApp({super.key});

  @override
  ConsumerState<AutoSpareApp> createState() => _AutoSpareAppState();
}

class _AutoSpareAppState extends ConsumerState<AutoSpareApp>
    with WidgetsBindingObserver {
  ProviderSubscription<SessionState>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionSubscription = ref.listenManual<SessionState>(
      currentSessionProvider,
      (previous, next) {
        unawaited(_syncNotifications(next));
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncNotifications(ref.read(currentSessionProvider)));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSubscription?.close();
    _sessionSubscription = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNotifications(ref.read(currentSessionProvider)));
    }
  }

  Future<void> _syncNotifications(SessionState session) async {
    try {
      await ref.read(chatNotificationServiceProvider).syncWithSession(session);
    } catch (error, stackTrace) {
      debugPrint('Chat notification setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialAppLocale = ref.watch(materialAppLocaleProvider);
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: materialAppLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (deviceLocales, supportedLocales) {
        return resolveEffectiveAppLocale(
          mode: ref.read(appLocaleProvider),
          deviceLocale: deviceLocales?.isNotEmpty == true
              ? deviceLocales!.first
              : null,
          deviceLocales: deviceLocales,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6FEB),
          brightness: Brightness.light,
          primary: const Color(0xFF1F6FEB),
          secondary: const Color(0xFFF59E0B),
          surface: Colors.white,
          error: const Color(0xFFB42318),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1F6FEB), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1F6FEB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1F2937),
            side: const BorderSide(color: Color(0xFFD0D5DD)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE8F1FF),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF1F6FEB)
                  : const Color(0xFF475467),
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AppUpdateGate(child: AppRouter()),
    );
  }
}
