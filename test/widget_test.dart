import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mta_auto_spare/api/api_exception.dart';
import 'package:mta_auto_spare/api/chat_api.dart';
import 'package:mta_auto_spare/api/chat_socket_service.dart';
import 'package:mta_auto_spare/api/inbox_socket_service.dart';
import 'package:mta_auto_spare/api/request_api.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/ensure_conversation_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_conversations_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_messages_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_requests_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/local_methods/chat_message_cache_store.dart';
import 'package:mta_auto_spare/controllers/providers/api_provider.dart';
import 'package:mta_auto_spare/controllers/providers/auth_provider.dart';
import 'package:mta_auto_spare/controllers/providers/chat_provider.dart';
import 'package:mta_auto_spare/controllers/providers/notification_provider.dart';
import 'package:mta_auto_spare/controllers/providers/request_provider.dart';
import 'package:mta_auto_spare/controllers/statuses/conversation_state.dart';
import 'package:mta_auto_spare/controllers/statuses/message_state.dart';
import 'package:mta_auto_spare/controllers/statuses/request_state.dart';
import 'package:mta_auto_spare/main.dart';
import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/notifications/chat_notification_service.dart';
import 'package:mta_auto_spare/routing/marketplace_shell.dart';
import 'package:mta_auto_spare/session/session_notifier.dart';
import 'package:mta_auto_spare/session/session_state.dart';
import 'package:mta_auto_spare/view/chat/chat_detail_page.dart';
import 'package:mta_auto_spare/view/chat/conversations_view.dart';
import 'package:mta_auto_spare/view/requests/requests_view.dart';

void main() {
  testWidgets('signed-out app shows the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Auto Spare Hub'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create a New Account'), findsOneWidget);
  });

  testWidgets('signed-in user lands on requests tab by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await _buildApp(
        overrides: [
          currentSessionProvider.overrideWithValue(_signedInSession()),
          requestsNotifierProvider.overrideWith(
            (ref) => TestLoadRequestsNotifier(
              const RequestState(
                requests: [
                  PartRequest(
                    id: 1,
                    requester: 2,
                    title: 'Front bumper',
                    description: 'Clean bumper needed for Camry.',
                    status: 1,
                    city: 'Riyadh',
                  ),
                ],
              ),
            ),
          ),
          conversationsNotifierProvider.overrideWith(
            (ref) => TestLoadConversationsNotifier(const ConversationState()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(navigationBar.selectedIndex, 0);
    expect(find.text('Browse Requests'), findsOneWidget);
  });

  testWidgets('my requests empty state shows create request CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await _buildRequestsHarness(
        requestState: const RequestState(
          segment: RequestSegment.mine,
          requests: [
            PartRequest(
              id: 1,
              requester: 2,
              title: 'Brake pads',
              description: 'Need original pads.',
              status: 1,
              city: 'Jeddah',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No requests yet'), findsOneWidget);
    expect(find.text('Create Request'), findsNWidgets(2));
  });

  testWidgets('own request cards hide the chat action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await _buildRequestsHarness(
        requestState: const RequestState(
          segment: RequestSegment.mine,
          requests: [
            PartRequest(
              id: 3,
              requester: 1,
              title: 'Oil filter',
              description: 'Looking for OEM filter.',
              status: 1,
              city: 'Dammam',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Oil filter'), findsOneWidget);
    expect(find.text('Chat Seller'), findsNothing);
  });

  testWidgets('own request cards show edit and delete actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await _buildRequestsHarness(
        requestState: const RequestState(
          segment: RequestSegment.mine,
          requests: [
            PartRequest(
              id: 3,
              requester: 1,
              title: 'Oil filter',
              description: 'Looking for OEM filter.',
              status: 1,
              city: 'Dammam',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
  });

  testWidgets('deleting a my request removes it from the list', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final requestApi = RecordingRequestApi();

    await tester.pumpWidget(
      await _buildRequestsHarness(
        requestState: const RequestState(
          segment: RequestSegment.mine,
          requests: [
            PartRequest(
              id: 3,
              requester: 1,
              title: 'Oil filter',
              description: 'Looking for OEM filter.',
              status: 1,
              city: 'Dammam',
            ),
          ],
        ),
        requestApi: requestApi,
      ),
    );
    await tester.pumpAndSettle();

    final deleteButton = find.widgetWithText(FilledButton, 'Delete').first;
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Delete'),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestApi.deletedRequestIds, [3]);
    expect(find.text('Oil filter'), findsNothing);
  });

  testWidgets('request cards render uploaded images in the list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await _buildRequestsHarness(
        requestState: const RequestState(
          requests: [
            PartRequest(
              id: 10,
              requester: 5,
              title: 'Door mirror',
              description: 'Need a clean side mirror.',
              status: 1,
              city: null,
              images: [
                PartImage(
                  id: 4,
                  partRequest: 10,
                  image: '/media/part_requests/sample_part.jpg',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Door mirror'), findsOneWidget);
    expect(find.text('City not set'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('request-image-skeleton-10-0')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url.contains(
              '/media/part_requests/sample_part.jpg',
            ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a request image opens a zoomable viewer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await _buildRequestsHarness(
        requestState: const RequestState(
          requests: [
            PartRequest(
              id: 10,
              requester: 5,
              title: 'Door mirror',
              description: 'Need a clean side mirror.',
              status: 1,
              city: null,
              images: [
                PartImage(
                  id: 4,
                  partRequest: 10,
                  image: '/media/part_requests/sample_part.jpg',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('request-image-thumbnail-10-0')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(
      find.byKey(const ValueKey('zoomable-image-viewer-close')),
      findsOneWidget,
    );
    expect(find.text('1 / 1'), findsOneWidget);

    final imageFinder = find.byKey(const ValueKey('zoomable-gallery-image-0'));
    final interactiveFinder = find.byKey(
      const ValueKey('zoomable-image-viewer-interactive'),
    );

    var interactiveViewer = tester.widget<InteractiveViewer>(interactiveFinder);
    expect(
      interactiveViewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1, 0.001),
    );
    expect(
      tester.widget<PageView>(find.byType(PageView)).physics,
      isA<BouncingScrollPhysics>(),
    );

    await _doubleTap(tester, imageFinder);
    await tester.pumpAndSettle();

    interactiveViewer = tester.widget<InteractiveViewer>(interactiveFinder);
    expect(
      interactiveViewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1.5),
    );
    expect(
      tester.widget<PageView>(find.byType(PageView)).physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    await _doubleTap(tester, imageFinder);
    await tester.pumpAndSettle();

    interactiveViewer = tester.widget<InteractiveViewer>(interactiveFinder);
    expect(
      interactiveViewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1, 0.001),
    );
    expect(
      tester.widget<PageView>(find.byType(PageView)).physics,
      isA<BouncingScrollPhysics>(),
    );
  });

  testWidgets('chat button opens a conversation for another user request', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int? openedConversationId;

    await tester.pumpWidget(
      await _buildRequestsHarness(
        requestState: const RequestState(
          requests: [
            PartRequest(
              id: 9,
              requester: 5,
              title: 'Headlight assembly',
              description: 'Need left side headlight for Elantra.',
              status: 1,
              city: 'Cairo',
            ),
          ],
        ),
        ensureConversationNotifier: TestEnsureConversationNotifier(77),
        onOpenConversation: (conversationId) {
          openedConversationId = conversationId;
        },
      ),
    );
    await tester.pumpAndSettle();

    final chatButton = find.widgetWithText(FilledButton, 'Chat Seller');
    await tester.tap(chatButton);
    await tester.pumpAndSettle();

    expect(openedConversationId, 77);
  });

  testWidgets(
    'chat button auto-sends the request for a newly created conversation',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final chatApi = RecordingChatApi();

      await tester.pumpWidget(
        await _buildRequestsHarness(
          requestState: const RequestState(
            requests: [
              PartRequest(
                id: 9,
                requester: 5,
                title: 'Headlight assembly',
                description: 'Need left side headlight for Elantra.',
                status: 1,
                city: 'Cairo',
              ),
            ],
          ),
          ensureConversationNotifier: TestEnsureConversationNotifier(
            77,
            wasCreated: true,
          ),
          chatApi: chatApi,
        ),
      );
      await tester.pumpAndSettle();

      final chatButton = find.widgetWithText(FilledButton, 'Chat Seller');
      await tester.ensureVisible(chatButton);
      await tester.tap(chatButton);
      await tester.pumpAndSettle();

      expect(chatApi.createdMessages, hasLength(1));
      expect(chatApi.createdMessages.single.conversation, 77);
      expect(chatApi.createdMessages.single.messageType, 'product');
      expect(chatApi.createdMessages.single.product, 9);
    },
  );

  testWidgets(
    'chat button does not auto-send again for an existing conversation',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final chatApi = RecordingChatApi();

      await tester.pumpWidget(
        await _buildRequestsHarness(
          requestState: const RequestState(
            requests: [
              PartRequest(
                id: 9,
                requester: 5,
                title: 'Headlight assembly',
                description: 'Need left side headlight for Elantra.',
                status: 1,
                city: 'Cairo',
              ),
            ],
          ),
          ensureConversationNotifier: TestEnsureConversationNotifier(
            77,
            wasCreated: false,
          ),
          chatApi: chatApi,
        ),
      );
      await tester.pumpAndSettle();

      final chatButton = find.widgetWithText(FilledButton, 'Chat Seller');
      await tester.ensureVisible(chatButton);
      await tester.tap(chatButton);
      await tester.pumpAndSettle();

      expect(chatApi.createdMessages, isEmpty);
    },
  );

  testWidgets('wide layout shows requests and conversations side by side', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      await _buildApp(
        overrides: [
          currentSessionProvider.overrideWithValue(_signedInSession()),
          requestsNotifierProvider.overrideWith(
            (ref) => TestLoadRequestsNotifier(const RequestState()),
          ),
          conversationsNotifierProvider.overrideWith(
            (ref) => TestLoadConversationsNotifier(const ConversationState()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
  });

  testWidgets('profile action opens the edit profile page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await _buildApp(
        overrides: [
          currentSessionProvider.overrideWithValue(_signedInSession()),
          requestsNotifierProvider.overrideWith(
            (ref) => TestLoadRequestsNotifier(const RequestState()),
          ),
          conversationsNotifierProvider.overrideWith(
            (ref) => TestLoadConversationsNotifier(const ConversationState()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Save Profile'), findsOneWidget);
  });

  testWidgets('notification request opens the target chat conversation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final messagesNotifier = TestLoadMessagesNotifier(preferences);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        currentSessionProvider.overrideWithValue(_signedInSession()),
        requestsNotifierProvider.overrideWith(
          (ref) => TestLoadRequestsNotifier(const RequestState()),
        ),
        conversationsNotifierProvider.overrideWith(
          (ref) => TestLoadConversationsNotifier(
            ConversationState(
              conversations: [_conversationListItem(id: 77, title: 'Chat A')],
            ),
          ),
        ),
        messagesNotifierProvider.overrideWith((ref) => messagesNotifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MarketplaceShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(chatNotificationNavigationRequestProvider.notifier)
        .state = const ChatNotificationNavigationRequest(
      conversationId: 77,
      eventType: 'chat_message',
      nonce: 1,
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailPage), findsOneWidget);
    expect(find.text('Loaded from backend'), findsOneWidget);
  });

  testWidgets('request notification opens the target request post', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        currentSessionProvider.overrideWithValue(_signedInSession()),
        requestsNotifierProvider.overrideWith(
          (ref) => TestLoadRequestsNotifier(
            const RequestState(
              requests: [
                PartRequest(
                  id: 15,
                  requester: 3,
                  title: 'Front bumper for Camry',
                  description: 'OEM preferred and ready for pickup.',
                  status: 1,
                  city: 'Riyadh',
                ),
              ],
            ),
          ),
        ),
        conversationsNotifierProvider.overrideWith(
          (ref) => TestLoadConversationsNotifier(const ConversationState()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MarketplaceShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(chatNotificationNavigationRequestProvider.notifier)
        .state = const ChatNotificationNavigationRequest(
      eventType: 'request_created',
      nonce: 2,
      requestId: 15,
      requesterId: 3,
      requestTitle: 'Front bumper for Camry',
      sellerName: 'Seller User',
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Request Post'), findsOneWidget);
    expect(find.text('Front bumper for Camry'), findsOneWidget);
    expect(find.text('Seller User'), findsOneWidget);
  });

  testWidgets(
    'conversation list shows own receipt checks and clears unread bubble on open',
    (WidgetTester tester) async {
      int? openedConversationId;

      await tester.pumpWidget(
        await _buildConversationsHarness(
          conversationState: ConversationState(
            conversations: [
              _conversationListItem(
                id: 77,
                title: 'Chat A',
                unreadCount: 3,
                lastMessage: const ConversationLastMessagePreview(
                  id: 501,
                  text: 'Ready for pickup',
                  senderId: 1,
                  senderName: 'Buyer User',
                  statuses: [
                    MessageStatusModel(
                      conversationId: 77,
                      messageId: 501,
                      userId: 1,
                      status: 'sent',
                    ),
                    MessageStatusModel(
                      conversationId: 77,
                      messageId: 501,
                      userId: 2,
                      status: 'seen',
                    ),
                  ],
                ),
              ),
            ],
          ),
          onOpenConversation: (conversationId) {
            openedConversationId = conversationId;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ready for pickup'), findsOneWidget);
      expect(find.text('Buyer User: Ready for pickup'), findsNothing);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Seller User'));
      await tester.pumpAndSettle();

      expect(openedConversationId, 77);
      expect(find.text('3'), findsNothing);
    },
  );

  testWidgets('chat detail loads messages and deactivates on dispose', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final messagesNotifier = TestLoadMessagesNotifier(preferences);
    final hostKey = GlobalKey<_ChatDetailToggleHostState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentSessionProvider.overrideWithValue(_signedInSession()),
          conversationsNotifierProvider.overrideWith(
            (ref) => TestLoadConversationsNotifier(
              ConversationState(
                conversations: [_conversationListItem(id: 77, title: 'Chat A')],
              ),
            ),
          ),
          messagesNotifierProvider.overrideWith((ref) => messagesNotifier),
        ],
        child: MaterialApp(home: _ChatDetailToggleHost(key: hostKey)),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Loaded from backend'), findsOneWidget);
    expect(messagesNotifier.loadedConversationIds, contains(77));
    expect(messagesNotifier.activatedConversationIds, contains(77));

    hostKey.currentState!.hideChat();
    await tester.pump();
    await tester.pump();

    expect(messagesNotifier.deactivatedConversationIds, contains(77));
    expect(tester.takeException(), isNull);
  });
}

Future<Widget> _buildApp({List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      ...overrides,
    ],
    child: const AutoSpareApp(),
  );
}

Future<Widget> _buildConversationsHarness({
  required ConversationState conversationState,
  ValueChanged<int>? onOpenConversation,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      currentSessionProvider.overrideWithValue(_signedInSession()),
      conversationsNotifierProvider.overrideWith(
        (ref) => TestLoadConversationsNotifier(conversationState),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ConversationsView(
          wideMode: false,
          onOpenConversation: onOpenConversation ?? (_) {},
        ),
      ),
    ),
  );
}

Future<Widget> _buildRequestsHarness({
  required RequestState requestState,
  TestEnsureConversationNotifier? ensureConversationNotifier,
  ValueChanged<int>? onOpenConversation,
  ChatApi? chatApi,
  RequestApi? requestApi,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      currentSessionProvider.overrideWithValue(_signedInSession()),
      requestsNotifierProvider.overrideWith(
        (ref) => TestLoadRequestsNotifier(requestState),
      ),
      conversationsNotifierProvider.overrideWith(
        (ref) => TestLoadConversationsNotifier(const ConversationState()),
      ),
      ensureConversationNotifierProvider.overrideWith(
        (ref) =>
            ensureConversationNotifier ?? TestEnsureConversationNotifier(44),
      ),
      if (chatApi != null) chatApiProvider.overrideWithValue(chatApi),
      if (requestApi != null) requestApiProvider.overrideWithValue(requestApi),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: RequestsView(
          wideMode: false,
          onOpenConversation: onOpenConversation ?? (_) {},
        ),
      ),
    ),
  );
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
      chatPushEnabled: true,
      chatMessagePreviewEnabled: true,
      createdAt: DateTime.utc(2026, 3, 27),
    ),
  );
}

class TestLoadRequestsNotifier extends LoadRequestsNotifier {
  TestLoadRequestsNotifier(RequestState initialState)
    : super(RequestApi(Dio())) {
    state = initialState;
  }

  @override
  Future<void> load() async {}
}

class TestLoadConversationsNotifier extends LoadConversationsNotifier {
  TestLoadConversationsNotifier(ConversationState initialState)
    : super(ChatApi(Dio()), _TestInboxSocketService()) {
    state = initialState;
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}

  @override
  Future<void> loadMore() async {}
}

class _TestInboxSocketService extends InboxSocketService {
  @override
  Future<void> connect({required String token}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {}
}

class TestEnsureConversationNotifier extends EnsureConversationNotifier {
  TestEnsureConversationNotifier(
    this.resultConversationId, {
    this.wasCreated = false,
  }) : super(ChatApi(Dio()));

  final int resultConversationId;
  final bool wasCreated;

  @override
  Future<int?> ensureConversation({
    required int currentUserId,
    required int ownerUserId,
    required String requestTitle,
    List<ConversationListItem>? currentConversations,
  }) async {
    state = EnsureConversationState(
      conversationId: resultConversationId,
      isLoading: false,
      wasCreated: wasCreated,
    );
    return resultConversationId;
  }
}

class RecordingChatApi extends ChatApi {
  RecordingChatApi({this.shouldFail = false}) : super(Dio());

  final bool shouldFail;
  final List<MessageCreateRequest> createdMessages = <MessageCreateRequest>[];

  @override
  Future<MessageModel> createMessage(MessageCreateRequest request) async {
    createdMessages.add(request);
    if (shouldFail) {
      throw ApiException('Automatic send failed.');
    }

    return MessageModel(
      id: 900 + createdMessages.length,
      conversationId: request.conversation,
      sender: const UserBrief(id: 1, name: 'Buyer User'),
      messageType: request.messageType,
      text: request.text ?? '',
      media: const [],
      product: request.product == null
          ? null
          : PartRequestBrief(id: request.product!, title: 'Shared request'),
      clientTimestamp: request.clientTimestamp,
      serverTimestamp: request.clientTimestamp,
      statuses: const [],
    );
  }
}

class RecordingRequestApi extends RequestApi {
  RecordingRequestApi() : super(Dio());

  final List<int> deletedRequestIds = <int>[];

  @override
  Future<void> deleteRequest(int requestId) async {
    deletedRequestIds.add(requestId);
  }
}

class TestLoadMessagesNotifier extends LoadMessagesNotifier {
  TestLoadMessagesNotifier(SharedPreferences preferences)
    : super(
        ChatApi(Dio()),
        ChatSocketService(),
        cacheStore: ChatMessageCacheStore(preferences),
        resolveLiveAccessToken: () async => 'access-token',
        resolveCacheUserId: () => 1,
      );

  final List<int> loadedConversationIds = [];
  final List<int> activatedConversationIds = [];
  final List<int> deactivatedConversationIds = [];

  @override
  Future<void> load(int conversationId, {bool forceRefresh = false}) async {
    loadedConversationIds.add(conversationId);
    state = MessageState(
      conversationId: conversationId,
      messages: [
        MessageModel(
          id: 501,
          conversationId: conversationId,
          sender: const UserBrief(id: 2, name: 'Seller User'),
          messageType: 'text',
          text: 'Loaded from backend',
          media: const [],
          clientTimestamp: DateTime.utc(2026, 3, 30, 8),
          serverTimestamp: DateTime.utc(2026, 3, 30, 8),
          statuses: const [],
        ),
      ],
    );
  }

  @override
  Future<void> activateConversation({
    required int conversationId,
    required int currentUserId,
    required String accessToken,
  }) async {
    activatedConversationIds.add(conversationId);
    state = state.copyWith(
      conversationId: conversationId,
      connectionStatus: ChatConnectionStatus.connected,
    );
  }

  @override
  Future<void> deactivateConversation([int? conversationId]) async {
    final targetConversationId = conversationId ?? state.conversationId;
    if (targetConversationId == null) {
      return;
    }
    deactivatedConversationIds.add(targetConversationId);
    state = state.copyWith(
      conversationId: null,
      connectionStatus: ChatConnectionStatus.disconnected,
    );
  }

  @override
  Future<void> pauseLiveSync() async {}

  @override
  Future<void> resumeLiveSync() async {}

  @override
  Future<void> refreshConnectionWithToken(String? accessToken) async {}
}

class _ChatDetailToggleHost extends StatefulWidget {
  const _ChatDetailToggleHost({super.key});

  @override
  State<_ChatDetailToggleHost> createState() => _ChatDetailToggleHostState();
}

class _ChatDetailToggleHostState extends State<_ChatDetailToggleHost> {
  bool _showChat = true;

  void hideChat() {
    setState(() => _showChat = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showChat) {
      return const SizedBox.shrink();
    }
    return const ChatDetailPage(conversationId: 77);
  }
}

ConversationListItem _conversationListItem({
  required int id,
  required String title,
  ConversationLastMessagePreview? lastMessage,
  int unreadCount = 0,
}) {
  return ConversationListItem(
    id: id,
    title: title,
    participants: const [
      ConversationParticipantRead(
        id: 1,
        user: UserBrief(id: 1, name: 'Buyer User'),
      ),
      ConversationParticipantRead(
        id: 2,
        user: UserBrief(id: 2, name: 'Seller User'),
      ),
    ],
    lastMessage: lastMessage,
    unreadCount: unreadCount,
  );
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  final center = tester.getCenter(finder);
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tapAt(center);
}
