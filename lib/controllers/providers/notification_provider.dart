import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/chat_notification_service.dart';
import '../../session/session_notifier.dart';
import 'api_provider.dart';
import 'chat_provider.dart';

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
  final notificationsSupported = !kIsWeb && Platform.isAndroid;
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
    onNavigationRequest: (request) {
      ref.read(chatNotificationNavigationRequestProvider.notifier).state =
          request;
    },
    onConversationMessageReceived: (conversationId) async {
      await ref
          .read(conversationsNotifierProvider.notifier)
          .load(forceRefresh: true);
    },
    resolveVisibleConversationId: () {
      return ref.read(messagesNotifierProvider).conversationId;
    },
  );
  ref.onDispose(service.dispose);
  return service;
});
