import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mta_auto_spare/api/user_api.dart';
import 'package:mta_auto_spare/constants/api_constants.dart';
import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/notifications/chat_notification_service.dart';
import 'package:mta_auto_spare/session/session_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late FakePushMessagingClient messagingClient;
  late FakeLocalNotificationsClient localNotificationsClient;
  late FakeUserApi userApi;
  late List<ChatNotificationNavigationRequest> navigationRequests;
  late List<int> refreshedConversationIds;
  late List<int> refreshedRequestIds;
  late ChatNotificationService service;
  int? visibleConversationId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    messagingClient = FakePushMessagingClient(initialToken: 'push-token-1');
    localNotificationsClient = FakeLocalNotificationsClient();
    userApi = FakeUserApi();
    navigationRequests = <ChatNotificationNavigationRequest>[];
    refreshedConversationIds = <int>[];
    refreshedRequestIds = <int>[];
    visibleConversationId = null;
    service = ChatNotificationService(
      userApi: userApi,
      preferences: preferences,
      messagingClient: messagingClient,
      localNotificationsClient: localNotificationsClient,
      notificationsSupported: true,
      onNavigationRequest: navigationRequests.add,
      onConversationMessageReceived: (conversationId) async {
        refreshedConversationIds.add(conversationId);
      },
      onRequestCreatedReceived: (requestId) async {
        refreshedRequestIds.add(requestId);
      },
      resolveVisibleConversationId: () => visibleConversationId,
      createDeviceId: () => 'device-123',
      tokenRetryDelay: const Duration(milliseconds: 10),
      tokenRequestRetryDelay: const Duration(milliseconds: 1),
    );
  });

  tearDown(() async {
    service.dispose();
    await messagingClient.dispose();
  });

  test('registers the current Android device after session restore', () async {
    await service.syncWithSession(_signedInSession());

    expect(messagingClient.initialized, isTrue);
    expect(messagingClient.permissionRequests, 1);
    expect(
      localNotificationsClient.channels.map((channel) => channel.id),
      <String>[
        ApiConstants.chatMessageNotificationChannelId,
        ApiConstants.chatActivityNotificationChannelId,
      ],
    );
    expect(userApi.upserts, hasLength(1));
    expect(userApi.upserts.single.deviceId, 'device-123');
    expect(userApi.upserts.single.platform, 'android');
    expect(userApi.upserts.single.pushToken, 'push-token-1');
    expect(userApi.upserts.single.isActive, isTrue);
    expect(preferences.getString('chat_notification_device_id'), 'device-123');

    await service.syncWithSession(_signedInSession());
    expect(userApi.upserts, hasLength(1));
  });

  test('re-registers on token refresh and deactivates on logout', () async {
    await service.syncWithSession(_signedInSession());
    await messagingClient.emitTokenRefresh('push-token-2');

    expect(userApi.upserts, hasLength(2));
    expect(userApi.upserts.last.pushToken, 'push-token-2');
    expect(userApi.upserts.last.isActive, isTrue);

    await service.deactivateCurrentDevice();

    expect(userApi.upserts, hasLength(3));
    expect(userApi.upserts.last.deviceId, 'device-123');
    expect(userApi.upserts.last.isActive, isFalse);
  });

  test(
    'retries device registration when the initial token is unavailable',
    () async {
      messagingClient.token = null;

      await service.syncWithSession(_signedInSession());

      expect(userApi.upserts, hasLength(1));
      expect(userApi.upserts.single.isActive, isFalse);

      messagingClient.token = 'push-token-3';
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await _pumpEventQueue();

      expect(userApi.upserts, hasLength(2));
      expect(userApi.upserts.last.pushToken, 'push-token-3');
      expect(userApi.upserts.last.isActive, isTrue);
    },
  );

  test(
    'treats token lookup failures as retryable and keeps the app running',
    () async {
      messagingClient.tokenError = Exception(
        'java.io.IOException: SERVICE_NOT_AVAILABLE',
      );

      await service.syncWithSession(_signedInSession());

      expect(userApi.upserts, hasLength(1));
      expect(userApi.upserts.single.isActive, isFalse);

      messagingClient.tokenError = null;
      messagingClient.token = 'push-token-4';

      await Future<void>.delayed(const Duration(milliseconds: 30));
      await _pumpEventQueue();

      expect(userApi.upserts, hasLength(2));
      expect(userApi.upserts.last.pushToken, 'push-token-4');
      expect(userApi.upserts.last.isActive, isTrue);
    },
  );

  test('shows a local notification for foreground chat messages', () async {
    await service.initialize();
    await messagingClient.emitForegroundMessage(
      const ChatRemoteMessage(
        data: <String, String>{
          'event_type': 'chat_message',
          'conversation_id': '77',
          'message_id': '501',
          'actor_user_id': '2',
          'app_name': 'MTA Auto Spare',
          'sender_name': 'Seller User',
          'body': 'Sent you a new message.',
        },
      ),
    );

    expect(localNotificationsClient.shownNotifications, hasLength(1));
    expect(refreshedConversationIds, <int>[77]);
    final shown = localNotificationsClient.shownNotifications.single;
    expect(shown.id, 77);
    expect(shown.appName, 'MTA Auto Spare');
    expect(shown.senderName, 'Seller User');
    expect(shown.body, 'Sent you a new message.');
    expect(shown.channel.id, ApiConstants.chatMessageNotificationChannelId);
  });

  test('shows a local notification for foreground request alerts', () async {
    await service.initialize();
    await messagingClient.emitForegroundMessage(
      const ChatRemoteMessage(
        data: <String, String>{
          'event_type': 'request_created',
          'request_id': '15',
          'requester_id': '3',
          'seller_name': 'Seller User',
          'request_title': 'Front bumper for Camry',
          'request_description': 'OEM preferred and ready for pickup.',
          'body': 'OEM preferred and ready for pickup.',
        },
      ),
    );

    expect(localNotificationsClient.shownNotifications, hasLength(1));
    expect(refreshedRequestIds, <int>[15]);
    final shown = localNotificationsClient.shownNotifications.single;
    expect(shown.eventType, 'request_created');
    expect(shown.senderName, 'Front bumper for Camry');
    expect(shown.body, 'OEM preferred and ready for pickup.');
    expect(shown.channel.id, ApiConstants.chatActivityNotificationChannelId);
  });

  test('ignores non-message activity notifications', () async {
    await service.initialize();
    await messagingClient.emitForegroundMessage(
      const ChatRemoteMessage(
        data: <String, String>{'event_type': 'typing', 'conversation_id': '77'},
      ),
    );

    expect(localNotificationsClient.shownNotifications, isEmpty);
  });

  test(
    'does not show a foreground notification for the currently open conversation',
    () async {
      visibleConversationId = 77;

      await service.initialize();
      await messagingClient.emitForegroundMessage(
        const ChatRemoteMessage(
          data: <String, String>{
            'event_type': 'chat_message',
            'conversation_id': '77',
            'message_id': '501',
            'actor_user_id': '2',
            'app_name': 'MTA Auto Spare',
            'sender_name': 'Seller User',
            'body': 'Sent you a new message.',
          },
        ),
      );

      expect(localNotificationsClient.shownNotifications, isEmpty);
      expect(refreshedConversationIds, isEmpty);
    },
  );

  test(
    'refreshes conversations when a chat notification opens the app',
    () async {
      localNotificationsClient.launchPayload = const <String, String>{
        'event_type': 'chat_message',
        'conversation_id': '91',
      };

      await service.initialize();

      expect(refreshedConversationIds, <int>[91]);
      expect(
        navigationRequests.map((request) => request.conversationId),
        <int?>[91],
      );
    },
  );

  test('routes request notifications to the target request post', () async {
    localNotificationsClient.launchPayload = const <String, String>{
      'event_type': 'request_created',
      'request_id': '25',
      'requester_id': '3',
      'seller_name': 'Seller User',
      'request_title': 'Door mirror',
    };

    await service.initialize();

    expect(refreshedRequestIds, <int>[25]);
    expect(navigationRequests.single.requestId, 25);
    expect(navigationRequests.single.sellerName, 'Seller User');
    expect(navigationRequests.single.requestTitle, 'Door mirror');
  });

  test('routes notification taps to the target conversation', () async {
    messagingClient.initialMessage = const ChatRemoteMessage(
      data: <String, String>{
        'event_type': 'chat_message',
        'conversation_id': '41',
      },
    );
    localNotificationsClient.launchPayload = const <String, String>{
      'event_type': 'chat_message',
      'conversation_id': '33',
    };

    await service.initialize();
    await messagingClient.emitOpenedMessage(
      const ChatRemoteMessage(
        data: <String, String>{
          'event_type': 'message_status',
          'conversation_id': '77',
        },
      ),
    );
    await localNotificationsClient.tap(const <String, String>{
      'event_type': 'typing',
      'conversation_id': '88',
    });

    expect(navigationRequests.map((request) => request.conversationId), <int?>[
      33,
      77,
      88,
    ]);
    expect(navigationRequests.map((request) => request.eventType), <String>[
      'chat_message',
      'message_status',
      'typing',
    ]);
    expect(refreshedConversationIds, <int>[33]);
  });
}

SessionState _signedInSession() {
  return SessionState(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    profile: MeProfile(
      id: 1,
      email: 'buyer@example.com',
      username: 'buyer',
      name: 'Buyer User',
      role: 'user',
      isActive: true,
      isAdmin: false,
      chatPushEnabled: true,
      chatMessagePreviewEnabled: true,
      createdAt: DateTime.utc(2026, 4, 1),
    ),
  );
}

class FakeUserApi extends UserApi {
  FakeUserApi() : super(Dio());

  final List<MobileDevice> upserts = <MobileDevice>[];

  @override
  Future<MobileDevice> upsertMobileDevice(MobileDevice device) async {
    upserts.add(device);
    return device;
  }
}

class FakePushMessagingClient implements PushMessagingClient {
  FakePushMessagingClient({String? initialToken}) : _token = initialToken;

  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();
  final StreamController<ChatRemoteMessage> _foregroundController =
      StreamController<ChatRemoteMessage>.broadcast();
  final StreamController<ChatRemoteMessage> _openedController =
      StreamController<ChatRemoteMessage>.broadcast();

  String? _token;
  Object? tokenError;
  bool initialized = false;
  int permissionRequests = 0;
  ChatRemoteMessage? initialMessage;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> requestPermission() async {
    permissionRequests += 1;
  }

  @override
  Future<String?> getToken() async {
    if (tokenError != null) {
      throw tokenError!;
    }
    return _token;
  }

  set token(String? value) {
    _token = value;
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Stream<ChatRemoteMessage> get onForegroundMessage =>
      _foregroundController.stream;

  @override
  Stream<ChatRemoteMessage> get onMessageOpenedApp => _openedController.stream;

  @override
  Future<ChatRemoteMessage?> getInitialMessage() async {
    return initialMessage;
  }

  Future<void> emitTokenRefresh(String token) async {
    _token = token;
    _tokenRefreshController.add(token);
    await _pumpEventQueue();
  }

  Future<void> emitForegroundMessage(ChatRemoteMessage message) async {
    _foregroundController.add(message);
    await _pumpEventQueue();
  }

  Future<void> emitOpenedMessage(ChatRemoteMessage message) async {
    _openedController.add(message);
    await _pumpEventQueue();
  }

  Future<void> dispose() async {
    await _tokenRefreshController.close();
    await _foregroundController.close();
    await _openedController.close();
  }
}

class FakeLocalNotificationsClient implements LocalNotificationsClient {
  final List<ChatNotificationChannel> channels = <ChatNotificationChannel>[];
  final List<ChatLocalNotification> shownNotifications =
      <ChatLocalNotification>[];

  Future<void> Function(Map<String, String> data)? _onPayloadTap;
  Map<String, String>? launchPayload;

  @override
  Future<void> initialize({
    required Future<void> Function(Map<String, String> data) onPayloadTap,
  }) async {
    _onPayloadTap = onPayloadTap;
  }

  @override
  Future<void> createChannel(ChatNotificationChannel channel) async {
    channels.add(channel);
  }

  @override
  Future<Map<String, String>?> getLaunchPayload() async {
    return launchPayload;
  }

  @override
  Future<void> show({required ChatLocalNotification notification}) async {
    shownNotifications.add(notification);
  }

  Future<void> tap(Map<String, String> data) async {
    await _onPayloadTap?.call(data);
    await _pumpEventQueue();
  }
}

Future<void> _pumpEventQueue([int turns = 3]) async {
  for (var index = 0; index < turns; index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
