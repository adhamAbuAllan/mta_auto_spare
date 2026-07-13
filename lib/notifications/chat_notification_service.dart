import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../api/user_api.dart';
import '../constants/api_constants.dart';
import '../firebase/firebase_bootstrap.dart';
import '../localization/notification_strings.dart';
import '../models/models.dart';
import '../session/session_state.dart';

const _chatNotificationDeviceIdKey = 'chat_notification_device_id';

Future<void> showChatNotificationFromFirebaseMessage(
  RemoteMessage message,
) async {
  final strings = await loadNotificationStrings();
  final notification = _notificationFromRemoteMessage(
    ChatRemoteMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    ),
    strings,
  );
  if (notification == null) {
    return;
  }

  final client = FlutterLocalNotificationsClient();
  await client.initialize(onPayloadTap: (_) async {});
  await client.createChannel(_chatMessageChannel(strings));
  await client.createChannel(_marketplaceActivityChannel(strings));
  await client.show(notification: notification);
}

class ChatNotificationNavigationRequest {
  const ChatNotificationNavigationRequest({
    required this.eventType,
    required this.nonce,
    this.conversationId,
    this.requestId,
    this.requesterId,
    this.requestTitle,
    this.sellerName,
  });

  final int? conversationId;
  final String eventType;
  final int nonce;
  final int? requestId;
  final int? requesterId;
  final String? requestTitle;
  final String? sellerName;
}

class ChatNotificationChannel {
  const ChatNotificationChannel({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

class ChatRemoteMessage {
  const ChatRemoteMessage({required this.data, this.title, this.body});

  final Map<String, String> data;
  final String? title;
  final String? body;
}

class ChatLocalNotification {
  const ChatLocalNotification({
    required this.id,
    required this.eventType,
    required this.channel,
    required this.data,
    required this.appName,
    required this.senderName,
    required this.body,
    required this.timestamp,
    this.senderAvatarUrl,
  });

  final int id;
  final String eventType;
  final ChatNotificationChannel channel;
  final Map<String, String> data;
  final String appName;
  final String senderName;
  final String body;
  final DateTime timestamp;
  final String? senderAvatarUrl;
}

class _ParsedChatNotification {
  const _ParsedChatNotification({
    required this.eventType,
    required this.data,
    required this.appName,
    required this.senderName,
    required this.body,
    required this.timestamp,
    this.senderAvatarUrl,
  });

  final String eventType;
  final Map<String, String> data;
  final String appName;
  final String senderName;
  final String body;
  final DateTime timestamp;
  final String? senderAvatarUrl;
}

abstract class PushMessagingClient {
  Future<void> initialize();

  Future<void> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<ChatRemoteMessage> get onForegroundMessage;

  Stream<ChatRemoteMessage> get onMessageOpenedApp;

  Future<ChatRemoteMessage?> getInitialMessage();
}

abstract class LocalNotificationsClient {
  Future<void> initialize({
    required Future<void> Function(Map<String, String> data) onPayloadTap,
  });

  Future<void> createChannel(ChatNotificationChannel channel);

  Future<Map<String, String>?> getLaunchPayload();

  Future<void> show({required ChatLocalNotification notification});
}

class NoopPushMessagingClient implements PushMessagingClient {
  const NoopPushMessagingClient();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermission() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<ChatRemoteMessage> get onForegroundMessage =>
      const Stream<ChatRemoteMessage>.empty();

  @override
  Stream<ChatRemoteMessage> get onMessageOpenedApp =>
      const Stream<ChatRemoteMessage>.empty();

  @override
  Future<ChatRemoteMessage?> getInitialMessage() async => null;
}

class NoopLocalNotificationsClient implements LocalNotificationsClient {
  const NoopLocalNotificationsClient();

  @override
  Future<void> initialize({
    required Future<void> Function(Map<String, String> data) onPayloadTap,
  }) async {}

  @override
  Future<void> createChannel(ChatNotificationChannel channel) async {}

  @override
  Future<Map<String, String>?> getLaunchPayload() async => null;

  @override
  Future<void> show({required ChatLocalNotification notification}) async {}
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({FirebaseMessaging? messaging})
    : _messaging = messaging;

  FirebaseMessaging? _messaging;

  FirebaseMessaging get _resolvedMessaging {
    return _messaging ??= FirebaseMessaging.instance;
  }

  @override
  Future<void> initialize() async {
    await ensureFirebaseInitialized(throwOnError: true);

    await _resolvedMessaging.setAutoInitEnabled(true);
  }

  @override
  Future<void> requestPermission() async {
    await _resolvedMessaging.requestPermission();
  }

  @override
  Future<String?> getToken() {
    return _resolvedMessaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => _resolvedMessaging.onTokenRefresh;

  @override
  Stream<ChatRemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_mapRemoteMessage);

  @override
  Stream<ChatRemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_mapRemoteMessage);

  @override
  Future<ChatRemoteMessage?> getInitialMessage() async {
    final message = await _resolvedMessaging.getInitialMessage();
    if (message == null) {
      return null;
    }
    return _mapRemoteMessage(message);
  }

  ChatRemoteMessage _mapRemoteMessage(RemoteMessage message) {
    return ChatRemoteMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }
}

class FlutterLocalNotificationsClient implements LocalNotificationsClient {
  FlutterLocalNotificationsClient({
    FlutterLocalNotificationsPlugin? plugin,
    Future<Uint8List?> Function(String url)? loadAvatarBytes,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _loadAvatarBytes = loadAvatarBytes ?? _downloadAvatarBytes;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<Uint8List?> Function(String url) _loadAvatarBytes;

  @override
  Future<void> initialize({
    required Future<void> Function(Map<String, String> data) onPayloadTap,
  }) async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        final decoded = _decodePayload(payload);
        if (decoded.isEmpty) {
          return;
        }
        unawaited(onPayloadTap(decoded));
      },
    );
  }

  @override
  Future<void> createChannel(ChatNotificationChannel channel) async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        channel.id,
        channel.name,
        description: channel.description,
        importance: Importance.high,
      ),
    );
  }

  @override
  Future<Map<String, String>?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      return null;
    }

    final response = details?.notificationResponse;
    final payload = response?.payload;
    if (payload == null || payload.isEmpty) {
      return null;
    }

    final decoded = _decodePayload(payload);
    return decoded.isEmpty ? null : decoded;
  }

  @override
  Future<void> show({required ChatLocalNotification notification}) async {
    if (notification.eventType == 'request_created') {
      final sellerName = (notification.data['seller_name'] ?? '').trim();
      await _plugin.show(
        id: notification.id,
        title: notification.senderName,
        body: sellerName.isEmpty
            ? notification.body
            : '$sellerName: ${notification.body}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            notification.channel.id,
            notification.channel.name,
            channelDescription: notification.channel.description,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.recommendation,
            subText: notification.appName,
            tag:
                'request-${notification.data['request_id'] ?? notification.id}',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier:
                'request-${notification.data['request_id'] ?? notification.id}',
          ),
        ),
        payload: jsonEncode(notification.data),
      );
      return;
    }

    final avatarUrl = notification.senderAvatarUrl;
    final avatarBytes = avatarUrl == null || avatarUrl.isEmpty
        ? null
        : await _loadAvatarBytes(avatarUrl);
    final senderPerson = Person(
      key: notification.data['actor_user_id'] ?? notification.senderName,
      name: notification.senderName,
      important: true,
      icon: avatarBytes == null ? null : ByteArrayAndroidIcon(avatarBytes),
    );
    final messagingStyle = MessagingStyleInformation(
      const Person(name: 'You'),
      conversationTitle: notification.appName,
      groupConversation: false,
      messages: <Message>[
        Message(notification.body, notification.timestamp, senderPerson),
      ],
    );

    await _plugin.show(
      id: notification.id,
      title: notification.appName,
      body: '${notification.senderName}: ${notification.body}',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          notification.channel.id,
          notification.channel.name,
          channelDescription: notification.channel.description,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          styleInformation: messagingStyle,
          largeIcon: avatarBytes == null
              ? null
              : ByteArrayAndroidBitmap(avatarBytes),
          subText: notification.senderName,
          tag:
              'chat-${notification.data['conversation_id'] ?? notification.id}',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier:
              'chat-${notification.data['conversation_id'] ?? notification.id}',
        ),
      ),
      payload: jsonEncode(notification.data),
    );
  }
}

class ChatNotificationService {
  ChatNotificationService({
    required UserApi userApi,
    required SharedPreferences preferences,
    required PushMessagingClient messagingClient,
    required LocalNotificationsClient localNotificationsClient,
    required bool notificationsSupported,
    String devicePlatform = 'android',
    required void Function(ChatNotificationNavigationRequest request)
    onNavigationRequest,
    Future<void> Function(int conversationId)? onConversationMessageReceived,
    Future<void> Function(int requestId)? onRequestCreatedReceived,
    int? Function()? resolveVisibleConversationId,
    String Function()? resolveNotificationLanguage,
    String Function()? createDeviceId,
    Duration tokenRetryDelay = const Duration(seconds: 12),
    Duration tokenRequestRetryDelay = const Duration(seconds: 2),
  }) : _userApi = userApi,
       _preferences = preferences,
       _messagingClient = messagingClient,
       _localNotificationsClient = localNotificationsClient,
       _notificationsSupported = notificationsSupported,
       _devicePlatform = devicePlatform,
       _onNavigationRequest = onNavigationRequest,
       _onConversationMessageReceived = onConversationMessageReceived,
       _onRequestCreatedReceived = onRequestCreatedReceived,
       _resolveVisibleConversationId = resolveVisibleConversationId,
       _resolveNotificationLanguage =
           resolveNotificationLanguage ?? (() => 'en'),
       _createDeviceId = createDeviceId ?? Uuid().v4,
       _tokenRetryDelay = tokenRetryDelay,
       _tokenRequestRetryDelay = tokenRequestRetryDelay;

  final UserApi _userApi;
  final SharedPreferences _preferences;
  final PushMessagingClient _messagingClient;
  final LocalNotificationsClient _localNotificationsClient;
  final bool _notificationsSupported;
  final String _devicePlatform;
  final void Function(ChatNotificationNavigationRequest request)
  _onNavigationRequest;
  final Future<void> Function(int conversationId)?
  _onConversationMessageReceived;
  final Future<void> Function(int requestId)? _onRequestCreatedReceived;
  final int? Function()? _resolveVisibleConversationId;
  final String Function() _resolveNotificationLanguage;
  final String Function() _createDeviceId;
  final Duration _tokenRetryDelay;
  final Duration _tokenRequestRetryDelay;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<ChatRemoteMessage>? _foregroundSubscription;
  StreamSubscription<ChatRemoteMessage>? _openedSubscription;
  Timer? _registrationRetryTimer;
  Future<void>? _initializationFuture;
  SessionState _currentSession = const SessionState();
  String? _lastKnownPushToken;
  String? _lastRegistrationFingerprint;
  DateTime? _lastPushTokenUnavailableAt;

  Future<void> initialize() {
    if (!_notificationsSupported) {
      return Future.value();
    }
    final inFlightInitialization = _initializationFuture;
    if (inFlightInitialization != null) {
      return inFlightInitialization;
    }

    final initialization = _initializeInternal();
    _initializationFuture = initialization;
    return initialization.catchError((error) {
      _initializationFuture = null;
      throw error;
    });
  }

  Future<void> syncWithSession(SessionState session) async {
    _currentSession = session;
    if (!_notificationsSupported) {
      return;
    }

    await initialize();
    if (!session.isAuthenticated) {
      _cancelRegistrationRetry();
      _lastRegistrationFingerprint = null;
      _lastPushTokenUnavailableAt = null;
      return;
    }

    final deviceId = await _ensureDeviceId();
    final pushToken = await _resolvePushToken();
    final notificationLanguage = _resolveNotificationLanguage();
    _lastKnownPushToken = pushToken;

    if (pushToken == null || pushToken.isEmpty) {
      final inactiveFingerprint = '${session.profile?.id}|$deviceId|inactive';
      debugPrint(
        'Chat notifications: FCM token is not available yet for device '
        '$deviceId. Will retry in ${_tokenRetryDelay.inSeconds}s.',
      );
      if (_lastRegistrationFingerprint != inactiveFingerprint) {
        await _setCurrentDeviceActive(
          isActive: false,
          session: session,
          deviceId: deviceId,
        );
        _lastRegistrationFingerprint = inactiveFingerprint;
      }
      _scheduleRegistrationRetry();
      return;
    }

    _cancelRegistrationRetry();
    final nextFingerprint =
        '${session.profile?.id}|$deviceId|$pushToken|$notificationLanguage|active';
    if (_lastRegistrationFingerprint == nextFingerprint) {
      return;
    }

    await _userApi.upsertMobileDevice(
      MobileDevice(
        deviceId: deviceId,
        platform: _devicePlatform,
        pushToken: pushToken,
        notificationLanguage: notificationLanguage,
        isActive: true,
      ),
    );
    debugPrint(
      'Chat notifications: registered $_devicePlatform device $deviceId for user '
      '${session.profile?.id} with token ${_maskPushToken(pushToken)}.',
    );
    _lastRegistrationFingerprint = nextFingerprint;
  }

  Future<void> deactivateCurrentDevice() async {
    if (!_notificationsSupported || !_currentSession.isAuthenticated) {
      _lastRegistrationFingerprint = null;
      return;
    }

    await initialize();
    _cancelRegistrationRetry();
    final deviceId = await _ensureDeviceId();
    await _setCurrentDeviceActive(
      isActive: false,
      session: _currentSession,
      deviceId: deviceId,
    );
    _lastRegistrationFingerprint = null;
  }

  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel() ?? Future<void>.value());
    unawaited(_foregroundSubscription?.cancel() ?? Future<void>.value());
    unawaited(_openedSubscription?.cancel() ?? Future<void>.value());
    _cancelRegistrationRetry();
  }

  Future<void> _initializeInternal() async {
    await _messagingClient.initialize();
    await _localNotificationsClient.initialize(onPayloadTap: _handlePayloadTap);
    final notificationStrings = await loadNotificationStrings(
      preferences: _preferences,
    );
    await _localNotificationsClient.createChannel(
      _chatMessageChannel(notificationStrings),
    );
    await _localNotificationsClient.createChannel(
      _marketplaceActivityChannel(notificationStrings),
    );
    await _messagingClient.requestPermission();

    _foregroundSubscription = _messagingClient.onForegroundMessage.listen((
      message,
    ) {
      unawaited(_handleForegroundMessage(message));
    });
    _openedSubscription = _messagingClient.onMessageOpenedApp.listen((message) {
      _handleNavigation(message.data);
    });
    _tokenRefreshSubscription = _messagingClient.onTokenRefresh.listen((token) {
      unawaited(_handleTokenRefresh(token));
    });

    final launchedFromLocalNotification = await _localNotificationsClient
        .getLaunchPayload();
    if (launchedFromLocalNotification != null) {
      _handleNavigation(launchedFromLocalNotification);
    } else {
      final initialMessage = await _messagingClient.getInitialMessage();
      if (initialMessage != null) {
        _handleNavigation(initialMessage.data);
      }
    }

    debugPrint('Chat notifications: Firebase messaging initialized.');
  }

  Future<void> _handleForegroundMessage(ChatRemoteMessage message) async {
    try {
      final notificationStrings = await loadNotificationStrings(
        preferences: _preferences,
      );
      final notification = _notificationFromRemoteMessage(
        message,
        notificationStrings,
      );
      if (notification == null) {
        return;
      }
      final eventType = notification.eventType;
      final incomingConversationId = int.tryParse(
        notification.data['conversation_id'] ?? '',
      );
      final incomingRequestId = int.tryParse(
        notification.data['request_id'] ?? '',
      );
      if (eventType == 'chat_message') {
        final visibleConversationId = _resolveVisibleConversationId?.call();
        if (visibleConversationId != null &&
            incomingConversationId != null &&
            visibleConversationId == incomingConversationId) {
          return;
        }
        unawaited(_notifyConversationMessageReceived(incomingConversationId));
      } else if (eventType == 'request_created') {
        unawaited(_notifyRequestCreatedReceived(incomingRequestId));
      }
      await _localNotificationsClient.show(notification: notification);
    } catch (error, stackTrace) {
      debugPrint('Unable to show foreground chat notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _handleTokenRefresh(String pushToken) async {
    try {
      final normalizedToken = pushToken.trim();
      if (normalizedToken.isEmpty) {
        debugPrint(
          'Chat notifications: received an empty token refresh event.',
        );
        return;
      }

      _cancelRegistrationRetry();
      _lastKnownPushToken = normalizedToken;
      _lastPushTokenUnavailableAt = null;
      if (!_currentSession.isAuthenticated) {
        return;
      }

      final deviceId = await _ensureDeviceId();
      final notificationLanguage = _resolveNotificationLanguage();
      await _userApi.upsertMobileDevice(
        MobileDevice(
          deviceId: deviceId,
          platform: _devicePlatform,
          pushToken: normalizedToken,
          notificationLanguage: notificationLanguage,
          isActive: true,
        ),
      );
      _lastRegistrationFingerprint =
          '${_currentSession.profile?.id}|$deviceId|$normalizedToken|$notificationLanguage|active';
      debugPrint(
        'Chat notifications: refreshed $_devicePlatform device token for user '
        '${_currentSession.profile?.id} (${_maskPushToken(normalizedToken)}).',
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to refresh chat notification device token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _handlePayloadTap(Map<String, String> data) async {
    _handleNavigation(data);
  }

  void _handleNavigation(Map<String, String> data) {
    final request = _navigationRequestFromData(data);
    if (request == null) {
      return;
    }
    if (request.eventType == 'chat_message') {
      unawaited(_notifyConversationMessageReceived(request.conversationId));
    } else if (request.eventType == 'request_created') {
      unawaited(_notifyRequestCreatedReceived(request.requestId));
    }
    _onNavigationRequest(request);
  }

  Future<void> _notifyConversationMessageReceived(int? conversationId) async {
    if (conversationId == null) {
      return;
    }

    try {
      await _onConversationMessageReceived?.call(conversationId);
    } catch (error, stackTrace) {
      debugPrint('Unable to refresh conversations after chat message: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _notifyRequestCreatedReceived(int? requestId) async {
    if (requestId == null) {
      return;
    }

    try {
      await _onRequestCreatedReceived?.call(requestId);
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to refresh requests after request notification: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _setCurrentDeviceActive({
    required bool isActive,
    required SessionState session,
    required String deviceId,
  }) async {
    if (!session.isAuthenticated) {
      return;
    }

    await _userApi.upsertMobileDevice(
      MobileDevice(
        deviceId: deviceId,
        platform: _devicePlatform,
        pushToken: isActive ? _lastKnownPushToken : null,
        isActive: isActive,
      ),
    );
    debugPrint(
      'Chat notifications: marked device $deviceId as '
      '${isActive ? 'active' : 'inactive'}.',
    );
  }

  Future<String> _ensureDeviceId() async {
    final existing = _preferences.getString(_chatNotificationDeviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _createDeviceId();
    await _preferences.setString(_chatNotificationDeviceIdKey, created);
    return created;
  }

  Future<String?> _resolvePushToken() async {
    final cachedToken = _lastKnownPushToken?.trim();
    if (cachedToken != null && cachedToken.isNotEmpty) {
      _lastPushTokenUnavailableAt = null;
      return cachedToken;
    }

    final unavailableAt = _lastPushTokenUnavailableAt;
    if (unavailableAt != null &&
        DateTime.now().difference(unavailableAt) < _tokenRetryDelay) {
      return null;
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      String? token;
      try {
        token = (await _messagingClient.getToken())?.trim();
      } catch (error) {
        _lastPushTokenUnavailableAt = DateTime.now();
        debugPrint(
          'Chat notifications: FCM token retrieval failed ($error). '
          'Push registration will stay inactive and retry later.',
        );
        return null;
      }
      if (token != null && token.isNotEmpty) {
        _lastPushTokenUnavailableAt = null;
        return token;
      }
      if (attempt < 2) {
        await Future<void>.delayed(_tokenRequestRetryDelay);
      }
    }
    _lastPushTokenUnavailableAt = DateTime.now();
    return null;
  }

  void _scheduleRegistrationRetry() {
    if (!_currentSession.isAuthenticated ||
        _registrationRetryTimer?.isActive == true) {
      return;
    }

    _registrationRetryTimer = Timer(_tokenRetryDelay, () {
      _registrationRetryTimer = null;
      unawaited(_retryRegistration());
    });
  }

  Future<void> _retryRegistration() async {
    try {
      if (!_currentSession.isAuthenticated) {
        return;
      }
      debugPrint('Chat notifications: retrying device registration.');
      await syncWithSession(_currentSession);
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to retry chat notification device registration: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _cancelRegistrationRetry() {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = null;
  }

  String _maskPushToken(String token) {
    if (token.length <= 12) {
      return token;
    }
    return '${token.substring(0, 8)}...${token.substring(token.length - 4)}';
  }

  ChatNotificationNavigationRequest? _navigationRequestFromData(
    Map<String, String> data,
  ) {
    final eventType = data['event_type'] ?? 'chat_message';
    final requestId = int.tryParse(data['request_id'] ?? '');
    if (eventType == 'request_created' && requestId != null) {
      return ChatNotificationNavigationRequest(
        eventType: eventType,
        nonce: DateTime.now().microsecondsSinceEpoch,
        requestId: requestId,
        requesterId: int.tryParse(data['requester_id'] ?? ''),
        requestTitle: _firstNonEmpty(data['request_title'], data['title']),
        sellerName: _firstNonEmpty(data['seller_name']),
      );
    }

    final conversationId = int.tryParse(data['conversation_id'] ?? '');
    if (conversationId == null) {
      return null;
    }

    return ChatNotificationNavigationRequest(
      conversationId: conversationId,
      eventType: eventType,
      nonce: DateTime.now().microsecondsSinceEpoch,
    );
  }
}

ChatLocalNotification? _notificationFromRemoteMessage(
  ChatRemoteMessage message,
  NotificationStrings strings,
) {
  final parsed = _parseNotification(
    message.data,
    strings,
    fallbackTitle: message.title,
    fallbackBody: message.body,
  );
  if (parsed == null) {
    return null;
  }

  return ChatLocalNotification(
    id: _resolveNotificationId(parsed.data),
    eventType: parsed.eventType,
    channel: parsed.eventType == 'request_created'
        ? _marketplaceActivityChannel(strings)
        : _chatMessageChannel(strings),
    data: parsed.data,
    appName: parsed.appName,
    senderName: parsed.senderName,
    body: parsed.body,
    timestamp: parsed.timestamp,
    senderAvatarUrl: parsed.senderAvatarUrl,
  );
}

_ParsedChatNotification? _parseNotification(
  Map<String, String> data,
  NotificationStrings strings, {
  String? fallbackTitle,
  String? fallbackBody,
}) {
  final normalizedEventType = (data['event_type'] ?? '').trim().toLowerCase();
  if (normalizedEventType == 'request_created') {
    return _parseRequestNotification(
      data,
      strings,
      fallbackTitle: fallbackTitle,
      fallbackBody: fallbackBody,
    );
  }

  return _parseChatNotification(
    data,
    strings,
    fallbackTitle: fallbackTitle,
    fallbackBody: fallbackBody,
  );
}

_ParsedChatNotification? _parseChatNotification(
  Map<String, String> data,
  NotificationStrings strings, {
  String? fallbackTitle,
  String? fallbackBody,
}) {
  final normalizedEventType = (data['event_type'] ?? '').trim().toLowerCase();
  final conversationId = int.tryParse(data['conversation_id'] ?? '');
  if (normalizedEventType != 'chat_message' || conversationId == null) {
    return null;
  }

  final senderName = _firstNonEmpty(
    data['sender_name'],
    data['title'],
    fallbackTitle,
    strings.newMessageTitle,
  );
  final body = _firstNonEmpty(
    data['body'],
    fallbackBody,
    strings.defaultChatMessageBody,
  );
  final appName = _firstNonEmpty(data['app_name'], strings.appName);
  final senderAvatarUrl = _resolveOptionalUrl(data['sender_avatar']);
  final timestamp = _parseTimestamp(data['server_timestamp']) ?? DateTime.now();

  return _ParsedChatNotification(
    eventType: normalizedEventType,
    data: Map<String, String>.from(data),
    appName: appName,
    senderName: senderName,
    body: body,
    timestamp: timestamp,
    senderAvatarUrl: senderAvatarUrl,
  );
}

_ParsedChatNotification? _parseRequestNotification(
  Map<String, String> data,
  NotificationStrings strings, {
  String? fallbackTitle,
  String? fallbackBody,
}) {
  final requestId = int.tryParse(data['request_id'] ?? '');
  if (requestId == null) {
    return null;
  }

  final requestTitle = _firstNonEmpty(
    data['request_title'],
    data['title'],
    fallbackTitle,
    strings.newSellerRequestTitle,
  );
  final sellerName = _firstNonEmpty(
    data['seller_name'],
    data['requester_name'],
    strings.supplierFallbackName,
  );
  final body = _firstNonEmpty(
    data['body'],
    data['request_description'],
    fallbackBody,
    strings.requestCreatedFallbackBody,
  );

  return _ParsedChatNotification(
    eventType: 'request_created',
    data: Map<String, String>.from(data),
    appName: sellerName,
    senderName: requestTitle,
    body: body,
    timestamp: _parseTimestamp(data['server_timestamp']) ?? DateTime.now(),
  );
}

int _resolveNotificationId(Map<String, String> data) {
  final requestId = int.tryParse(data['request_id'] ?? '');
  if (requestId != null) {
    return requestId;
  }

  final conversationId = int.tryParse(data['conversation_id'] ?? '');
  if (conversationId != null) {
    return conversationId;
  }

  final messageId = int.tryParse(data['message_id'] ?? '');
  if (messageId != null) {
    return messageId;
  }

  return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
}

String _firstNonEmpty(
  String? first, [
  String? second,
  String? third,
  String? fourth,
]) {
  for (final candidate in <String?>[first, second, third, fourth]) {
    final normalized = (candidate ?? '').trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return '';
}

DateTime? _parseTimestamp(String? raw) {
  final normalized = (raw ?? '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  return DateTime.tryParse(normalized);
}

String? _resolveOptionalUrl(String? rawUrl) {
  final normalized = (rawUrl ?? '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  return ApiConstants.resolveUrl(normalized);
}

Map<String, String> _decodePayload(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return const {};
    }
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  } catch (_) {
    return const {};
  }
}

Future<Uint8List?> _downloadAvatarBytes(String url) async {
  try {
    final response = await Dio(
      _notificationBaseOptions(),
    ).get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final data = response.data;
    if (data == null || data.isEmpty) {
      return null;
    }
    return Uint8List.fromList(data);
  } catch (_) {
    return null;
  }
}

BaseOptions _notificationBaseOptions() {
  return BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    sendTimeout: ApiConstants.sendTimeout,
    headers: const {
      'Accept': ApiConstants.acceptHeader,
      ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
    },
  );
}

ChatNotificationChannel _chatMessageChannel(NotificationStrings strings) {
  return ChatNotificationChannel(
    id: ApiConstants.chatMessageNotificationChannelId,
    name: strings.chatMessagesChannel.name,
    description: strings.chatMessagesChannel.description,
  );
}

ChatNotificationChannel _marketplaceActivityChannel(
  NotificationStrings strings,
) {
  return ChatNotificationChannel(
    id: ApiConstants.chatActivityNotificationChannelId,
    name: strings.chatActivityChannel.name,
    description: strings.chatActivityChannel.description,
  );
}
