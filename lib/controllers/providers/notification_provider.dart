import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/chat_notification_service.dart';
import '../../localization/app_locale.dart';
import '../../localization/app_locale_notifier.dart';
import '../../session/session_notifier.dart';
import 'api_provider.dart';
import 'chat_provider.dart';
import 'request_provider.dart';

final chatNotificationNavigationRequestProvider =
    StateProvider<ChatNotificationNavigationRequest?>((ref) => null);

final pushMessagingClientProvider = Provider<PushMessagingClient>((ref) {
  return FirebasePushMessagingClient();
});

final localNotificationsClientProvider = Provider<LocalNotificationsClient>((
  ref,
) {
  return FlutterLocalNotificationsClient();
});

final chatNotificationServiceProvider = Provider<ChatNotificationService>((
  ref,
) {
  final notificationsSupported =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  final service = ChatNotificationService(
    userApi: ref.read(userApiProvider),
    preferences: ref.read(sharedPreferencesProvider),
    messagingClient: notificationsSupported
        ? ref.read(pushMessagingClientProvider)
        : const NoopPushMessagingClient(),
    localNotificationsClient: notificationsSupported
        ? ref.read(localNotificationsClientProvider)
        : const NoopLocalNotificationsClient(),
    notificationsSupported: notificationsSupported,
    devicePlatform: Platform.isIOS ? 'ios' : 'android',
    onNavigationRequest: (request) {
      ref.read(chatNotificationNavigationRequestProvider.notifier).state =
          request;
    },
    onConversationMessageReceived: (conversationId) async {
      await ref
          .read(conversationsNotifierProvider.notifier)
          .load(forceRefresh: true);
    },
    onRequestCreatedReceived: (requestId) async {
      await ref.read(requestsNotifierProvider.notifier).load();
    },
    resolveVisibleConversationId: () {
      return ref.read(messagesNotifierProvider).conversationId;
    },
    resolveNotificationLanguage: () {
      final mode = ref.read(appLocaleProvider);
      return resolveEffectiveAppLocale(
        mode: mode,
        deviceLocale: currentDeviceLocale(),
      ).languageCode;
    },
  );
  ref.listen(appLocaleProvider, (previous, next) {
    unawaited(service.syncWithSession(ref.read(sessionNotifierProvider)));
  });
  ref.onDispose(service.dispose);
  return service;
});
