import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/providers/auth_provider.dart';
import 'controllers/providers/notification_provider.dart';
import 'notifications/chat_notification_service.dart';
import 'routing/app_router.dart';
import 'session/session_notifier.dart';
import 'session/session_state.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await showChatNotificationFromFirebaseMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
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
    return MaterialApp(
      title: 'MTA Auto Spare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF116466),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F0E8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0C4A63),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9CFBF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9CFBF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF116466), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF116466),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0C4A63),
            side: const BorderSide(color: Color(0xFFB7C8C9)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AppRouter(),
    );
  }
}
