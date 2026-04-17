import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

class NotificationChannelStrings {
  const NotificationChannelStrings({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

class NotificationStrings {
  const NotificationStrings({
    required this.appName,
    required this.defaultChatMessageBody,
    required this.newMessageTitle,
    required this.newSellerRequestTitle,
    required this.supplierFallbackName,
    required this.requestCreatedFallbackBody,
    required this.chatMessagesChannel,
    required this.chatActivityChannel,
  });

  final String appName;
  final String defaultChatMessageBody;
  final String newMessageTitle;
  final String newSellerRequestTitle;
  final String supplierFallbackName;
  final String requestCreatedFallbackBody;
  final NotificationChannelStrings chatMessagesChannel;
  final NotificationChannelStrings chatActivityChannel;
}

Future<NotificationStrings> loadNotificationStrings({
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final mode = AppLocaleMode.fromStorage(
    prefs.getString(appLocalePreferenceKey),
  );
  final locale = resolveEffectiveAppLocale(
    mode: mode,
    deviceLocale: PlatformDispatcher.instance.locale,
    deviceLocales: PlatformDispatcher.instance.locales,
  );
  return notificationStringsForLocale(locale);
}

NotificationStrings notificationStringsForLocale(Locale locale) {
  return notificationStringsForLanguageCode(locale.languageCode);
}

NotificationStrings notificationStringsForLanguageCode(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'ar':
      return const NotificationStrings(
        appName: 'قطع غيار السيارات MTA',
        defaultChatMessageBody: 'لديك رسالة جديدة.',
        newMessageTitle: 'رسالة جديدة',
        newSellerRequestTitle: 'طلب جديد من البائع',
        supplierFallbackName: 'البائع',
        requestCreatedFallbackBody: 'قام بائع بنشر طلب جديد.',
        chatMessagesChannel: NotificationChannelStrings(
          name: 'رسائل الدردشة',
          description: 'رسائل جديدة من محادثات التطبيق',
        ),
        chatActivityChannel: NotificationChannelStrings(
          name: 'تحديثات السوق',
          description: 'طلبات جديدة وتحديثات نشاط السوق',
        ),
      );
    case 'he':
      return const NotificationStrings(
        appName: 'MTA חלקי חילוף לרכב',
        defaultChatMessageBody: 'נשלחה אליך הודעה חדשה.',
        newMessageTitle: 'הודעה חדשה',
        newSellerRequestTitle: 'בקשת מוכר חדשה',
        supplierFallbackName: 'מוכר',
        requestCreatedFallbackBody: 'מוכר פרסם בקשה חדשה.',
        chatMessagesChannel: NotificationChannelStrings(
          name: 'הודעות צ׳אט',
          description: 'הודעות חדשות משיחות הצ׳אט',
        ),
        chatActivityChannel: NotificationChannelStrings(
          name: 'עדכוני שוק',
          description: 'בקשות חדשות ועדכוני פעילות בשוק',
        ),
      );
    default:
      return const NotificationStrings(
        appName: 'MTA Auto Spare',
        defaultChatMessageBody: 'Sent you a new message.',
        newMessageTitle: 'New message',
        newSellerRequestTitle: 'New seller request',
        supplierFallbackName: 'Supplier',
        requestCreatedFallbackBody: 'A supplier posted a new request.',
        chatMessagesChannel: NotificationChannelStrings(
          name: 'Chat Messages',
          description: 'New messages from chat conversations',
        ),
        chatActivityChannel: NotificationChannelStrings(
          name: 'Marketplace Updates',
          description: 'New supplier requests and marketplace activity',
        ),
      );
  }
}
