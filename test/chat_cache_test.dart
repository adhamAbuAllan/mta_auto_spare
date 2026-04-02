import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mta_auto_spare/api/chat_api.dart';
import 'package:mta_auto_spare/api/chat_socket_service.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_conversations_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_messages_notifier.dart';
import 'package:mta_auto_spare/controllers/methods/local_methods/chat_message_cache_store.dart';
import 'package:mta_auto_spare/models/models.dart';

void main() {
  test(
    'messages refresh from the API and stay cached by conversation',
    () async {
      final api = FakeChatApi(
        messagesByConversation: {
          4: [_message(id: 11, conversationId: 4, text: 'Cached hello')],
        },
      );
      final notifier = await _createMessagesNotifier(api);

      await notifier.load(4);
      expect(api.messagesCalls, 1);
      expect(notifier.state.messages.single.text, 'Cached hello');
      expect(notifier.peek(4)?.messages.single.text, 'Cached hello');

      await notifier.load(4);
      expect(api.messagesCalls, 2);
      expect(notifier.peek(4)?.messages.single.text, 'Cached hello');
    },
  );

  test('conversations are reused until a force refresh is requested', () async {
    final api = FakeChatApi(
      conversations: [_conversation(id: 1, title: 'Chat A')],
    );
    final notifier = LoadConversationsNotifier(api);

    await notifier.load();
    expect(api.conversationsCalls, 1);

    await notifier.load();
    expect(api.conversationsCalls, 1);

    await notifier.load(forceRefresh: true);
    expect(api.conversationsCalls, 2);
  });

  test(
    'sending a message updates the cached conversation preview locally',
    () async {
      final api = FakeChatApi(
        conversations: [
          _conversation(id: 1, title: 'Chat A'),
          _conversation(id: 2, title: 'Chat B'),
        ],
      );
      final notifier = LoadConversationsNotifier(api);

      await notifier.load();

      notifier.touchConversationFromMessage(
        conversationId: 2,
        message: _message(
          id: 99,
          conversationId: 2,
          text: 'Newest message',
          senderId: 7,
          senderName: 'Buyer User',
        ),
        currentUserId: 1,
      );

      expect(notifier.state.conversations.first.id, 2);
      expect(
        notifier.state.conversations.first.lastMessage?.text,
        'Newest message',
      );
    },
  );

  test(
    'conversation preview keeps receipt state for the current user last message',
    () async {
      final api = FakeChatApi(
        conversations: [_conversation(id: 2, title: 'Chat B')],
      );
      final notifier = LoadConversationsNotifier(api);

      await notifier.load();

      notifier.touchConversationFromMessage(
        conversationId: 2,
        message: _message(
          id: 111,
          conversationId: 2,
          text: 'Seen by seller',
          senderId: 1,
          senderName: 'User A',
          statuses: [
            _status(
              conversationId: 2,
              messageId: 111,
              userId: 1,
              status: 'sent',
            ),
            _status(
              conversationId: 2,
              messageId: 111,
              userId: 2,
              status: 'seen',
            ),
          ],
        ),
        currentUserId: 1,
      );

      final preview = notifier.state.conversations.single.lastMessage;
      expect(preview?.receiptStateFor(1), MessageReceiptState.seen);
    },
  );

  test(
    'send adds a local message immediately and replaces it on success',
    () async {
      final completer = Completer<MessageModel>();
      final api = FakeChatApi(createMessageHandler: (_) => completer.future);
      final notifier = await _createMessagesNotifier(api);
      await notifier.load(4);

      final sendFuture = notifier.send(
        request: MessageCreateRequest(
          conversation: 4,
          messageType: 'text',
          text: 'Instant hello',
          clientTimestamp: DateTime.utc(2026, 3, 27, 13),
        ),
        sender: const UserBrief(id: 1, name: 'User A'),
      );

      expect(notifier.state.messages, hasLength(1));
      expect(notifier.state.messages.single.text, 'Instant hello');
      expect(notifier.state.messages.single.isOptimistic, isTrue);
      expect(
        notifier.state.messages.single.receiptStateFor(1),
        MessageReceiptState.pending,
      );
      expect(notifier.state.pendingMessageCount, 1);

      completer.complete(
        _message(
          id: 42,
          conversationId: 4,
          text: 'Instant hello',
          clientTimestamp: DateTime.utc(2026, 3, 27, 13),
          statuses: [
            _status(
              conversationId: 4,
              messageId: 42,
              userId: 1,
              status: 'sent',
            ),
          ],
        ),
      );

      expect(await sendFuture, isTrue);
      expect(notifier.state.messages, hasLength(1));
      expect(notifier.state.messages.single.id, 42);
      expect(notifier.state.messages.single.isOptimistic, isFalse);
      expect(
        notifier.state.messages.single.receiptStateFor(1),
        MessageReceiptState.sent,
      );
      expect(notifier.state.pendingMessageCount, 0);
    },
  );

  test('message receipt state maps delivered and seen statuses', () {
    final deliveredMessage = _message(
      id: 5,
      conversationId: 4,
      text: 'Delivered',
      statuses: [
        _status(conversationId: 4, messageId: 5, userId: 1, status: 'sent'),
        _status(
          conversationId: 4,
          messageId: 5,
          userId: 2,
          status: 'delivered',
        ),
      ],
    );
    final seenMessage = _message(
      id: 6,
      conversationId: 4,
      text: 'Seen',
      statuses: [
        _status(conversationId: 4, messageId: 6, userId: 1, status: 'sent'),
        _status(conversationId: 4, messageId: 6, userId: 2, status: 'seen'),
      ],
    );

    expect(deliveredMessage.receiptStateFor(1), MessageReceiptState.delivered);
    expect(seenMessage.receiptStateFor(1), MessageReceiptState.seen);
  });
}

Future<TestLoadMessagesNotifier> _createMessagesNotifier(
  FakeChatApi api,
) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return TestLoadMessagesNotifier(api, preferences);
}

class FakeChatApi extends ChatApi {
  FakeChatApi({
    Map<int, List<MessageModel>>? messagesByConversation,
    List<ConversationListItem>? conversations,
    Future<MessageModel> Function(MessageCreateRequest request)?
    createMessageHandler,
  }) : _messagesByConversation = messagesByConversation ?? const {},
       conversations = conversations ?? const [],
       _createMessageHandler = createMessageHandler,
       super(Dio());

  final Map<int, List<MessageModel>> _messagesByConversation;
  final List<ConversationListItem> conversations;
  final Future<MessageModel> Function(MessageCreateRequest request)?
  _createMessageHandler;
  int messagesCalls = 0;
  int conversationsCalls = 0;

  @override
  Future<ApiPage<MessageModel>> getMessages({
    required int conversationId,
    String? pageUrl,
  }) async {
    messagesCalls += 1;
    final results =
        _messagesByConversation[conversationId] ?? const <MessageModel>[];
    return ApiPage<MessageModel>(
      count: results.length,
      next: null,
      previous: null,
      results: results,
    );
  }

  @override
  Future<ApiPage<ConversationListItem>> getConversations({
    String? pageUrl,
  }) async {
    conversationsCalls += 1;
    return ApiPage<ConversationListItem>(
      count: conversations.length,
      next: null,
      previous: null,
      results: conversations,
    );
  }

  @override
  Future<MessageModel> createMessage(MessageCreateRequest request) async {
    if (_createMessageHandler != null) {
      return _createMessageHandler(request);
    }
    return _message(
      id: 100,
      conversationId: request.conversation,
      text: request.text ?? '',
      statuses: [
        _status(
          conversationId: request.conversation,
          messageId: 100,
          userId: 1,
          status: 'sent',
        ),
      ],
    );
  }
}

class TestLoadMessagesNotifier extends LoadMessagesNotifier {
  TestLoadMessagesNotifier(ChatApi chatApi, SharedPreferences preferences)
    : super(
        chatApi,
        ChatSocketService(),
        cacheStore: ChatMessageCacheStore(preferences),
        resolveLiveAccessToken: () async => 'access-token',
        resolveCacheUserId: () => 1,
      );

  @override
  Future<void> activateConversation({
    required int conversationId,
    required int currentUserId,
    required String accessToken,
  }) async {}

  @override
  Future<void> deactivateConversation([int? conversationId]) async {}

  @override
  Future<void> pauseLiveSync() async {}

  @override
  Future<void> resumeLiveSync() async {}

  @override
  Future<void> refreshConnectionWithToken(String? accessToken) async {}
}

ConversationListItem _conversation({required int id, required String title}) {
  return ConversationListItem(
    id: id,
    title: title,
    participants: [
      const ConversationParticipantRead(
        id: 1,
        user: UserBrief(id: 1, name: 'User A'),
      ),
      const ConversationParticipantRead(
        id: 2,
        user: UserBrief(id: 2, name: 'User B'),
      ),
    ],
    unreadCount: 0,
  );
}

MessageModel _message({
  required int id,
  required int conversationId,
  required String text,
  DateTime? clientTimestamp,
  DateTime? serverTimestamp,
  int senderId = 1,
  String senderName = 'User A',
  List<MessageStatusModel> statuses = const [],
  bool isOptimistic = false,
  bool hasSendError = false,
}) {
  return MessageModel(
    id: id,
    conversationId: conversationId,
    sender: UserBrief(id: senderId, name: senderName),
    messageType: 'text',
    text: text,
    media: const [],
    clientTimestamp: clientTimestamp ?? DateTime.utc(2026, 3, 27, 12),
    serverTimestamp: serverTimestamp ?? DateTime.utc(2026, 3, 27, 12),
    statuses: statuses,
    isOptimistic: isOptimistic,
    hasSendError: hasSendError,
  );
}

MessageStatusModel _status({
  required int conversationId,
  required int messageId,
  required int userId,
  required String status,
}) {
  return MessageStatusModel(
    conversationId: conversationId,
    messageId: messageId,
    userId: userId,
    status: status,
    updatedAt: DateTime.utc(2026, 3, 27, 12),
  );
}
