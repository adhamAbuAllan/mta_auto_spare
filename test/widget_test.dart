import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mta_auto_spare/api/chat_api.dart';
import 'package:mta_auto_spare/api/request_api.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/ensure_conversation_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_conversations_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_requests_notifier.dart';
import 'package:mta_auto_spare/controllers/providers/auth_provider.dart';
import 'package:mta_auto_spare/controllers/providers/chat_provider.dart';
import 'package:mta_auto_spare/controllers/providers/request_provider.dart';
import 'package:mta_auto_spare/controllers/statuses/conversation_state.dart';
import 'package:mta_auto_spare/controllers/statuses/request_state.dart';
import 'package:mta_auto_spare/main.dart';
import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/session/session_notifier.dart';
import 'package:mta_auto_spare/session/session_state.dart';
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

Future<Widget> _buildRequestsHarness({
  required RequestState requestState,
  TestEnsureConversationNotifier? ensureConversationNotifier,
  ValueChanged<int>? onOpenConversation,
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
    : super(ChatApi(Dio())) {
    state = initialState;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> loadMore() async {}
}

class TestEnsureConversationNotifier extends EnsureConversationNotifier {
  TestEnsureConversationNotifier(this.resultConversationId)
    : super(ChatApi(Dio()));

  final int resultConversationId;

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
      wasCreated: true,
    );
    return resultConversationId;
  }
}
