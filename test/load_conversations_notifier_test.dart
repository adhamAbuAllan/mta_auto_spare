import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/api/chat_socket_service.dart';
import 'package:mta_auto_spare/api/chat_api.dart';
import 'package:mta_auto_spare/api/inbox_socket_service.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/load_conversations_notifier.dart';
import 'package:mta_auto_spare/controllers/statuses/conversation_state.dart';
import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/session/session_state.dart';

void main() {
  test(
    'incoming messages move the conversation to the top and increment unread count',
    () {
      final notifier = TestLoadConversationsNotifier(
        ConversationState(
          conversations: [
            _conversation(id: 1, title: 'Chat A', unreadCount: 0),
            _conversation(id: 2, title: 'Chat B', unreadCount: 1),
          ],
        ),
      );

      notifier.touchConversationFromMessage(
        conversationId: 2,
        currentUserId: 1,
        message: MessageModel(
          id: 501,
          conversationId: 2,
          sender: const UserBrief(id: 2, name: 'Seller User'),
          messageType: 'text',
          text: 'Newest incoming message',
          media: const [],
          clientTimestamp: DateTime.utc(2026, 4, 5, 10, 0),
          serverTimestamp: DateTime.utc(2026, 4, 5, 10, 0),
          statuses: const [],
        ),
      );

      expect(notifier.state.conversations.first.id, 2);
      expect(notifier.state.conversations.first.unreadCount, 2);
      expect(
        notifier.state.conversations.first.lastMessage?.text,
        'Newest incoming message',
      );
    },
  );

  test(
    'outgoing messages move the conversation to the top and keep unread count cleared',
    () {
      final notifier = TestLoadConversationsNotifier(
        ConversationState(
          conversations: [
            _conversation(id: 1, title: 'Chat A', unreadCount: 3),
            _conversation(id: 2, title: 'Chat B', unreadCount: 0),
          ],
        ),
      );

      notifier.touchConversationFromMessage(
        conversationId: 1,
        currentUserId: 1,
        message: MessageModel(
          id: 777,
          conversationId: 1,
          sender: const UserBrief(id: 1, name: 'Buyer User'),
          messageType: 'text',
          text: 'Newest outgoing message',
          media: const [],
          clientTimestamp: DateTime.utc(2026, 4, 5, 10, 5),
          serverTimestamp: DateTime.utc(2026, 4, 5, 10, 5),
          statuses: const [],
        ),
      );

      expect(notifier.state.conversations.first.id, 1);
      expect(notifier.state.conversations.first.unreadCount, 0);
      expect(
        notifier.state.conversations.first.lastMessage?.text,
        'Newest outgoing message',
      );
    },
  );

  test(
    'inbox socket messages update the conversations list immediately',
    () async {
      final inboxSocketService = FakeInboxSocketService();
      final notifier = TestLoadConversationsNotifier(
        ConversationState(
          conversations: [
            _conversation(id: 1, title: 'Chat A', unreadCount: 0),
            _conversation(id: 2, title: 'Chat B', unreadCount: 0),
          ],
        ),
        inboxSocketService: inboxSocketService,
      );

      await notifier.syncWithSession(
        SessionState(
          accessToken: 'live-token',
          profile: MeProfile(
            id: 1,
            email: 'buyer@example.com',
            username: 'buyer',
            name: 'Buyer User',
            role: 'user',
            chatPushEnabled: true,
            chatMessagePreviewEnabled: true,
            createdAt: DateTime.utc(2026, 4, 5),
          ),
        ),
      );
      inboxSocketService.emitMessage(
        MessageModel(
          id: 901,
          conversationId: 2,
          sender: const UserBrief(id: 2, name: 'Seller User'),
          messageType: 'text',
          text: 'Fresh inbox event',
          media: const [],
          clientTimestamp: DateTime.utc(2026, 4, 5, 12, 0),
          serverTimestamp: DateTime.utc(2026, 4, 5, 12, 0),
          statuses: const [],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(inboxSocketService.lastConnectedToken, 'live-token');
      expect(notifier.state.conversations.first.id, 2);
      expect(notifier.state.conversations.first.unreadCount, 1);
      expect(
        notifier.state.conversations.first.lastMessage?.text,
        'Fresh inbox event',
      );

      notifier.dispose();
      await inboxSocketService.dispose();
    },
  );

  test(
    'older inbox messages do not replace a newer conversation preview or reorder the list incorrectly',
    () async {
      final inboxSocketService = FakeInboxSocketService();
      final notifier = TestLoadConversationsNotifier(
        ConversationState(
          conversations: [
            _conversation(
              id: 1,
              title: 'Newest chat',
              unreadCount: 0,
              lastMessage: ConversationLastMessagePreview(
                id: 801,
                messageType: 'text',
                text: 'Latest preview',
                senderId: 2,
                senderName: 'Seller User',
                timestamp: DateTime.utc(2026, 4, 5, 12, 0),
              ),
            ),
            _conversation(
              id: 2,
              title: 'Older chat',
              unreadCount: 0,
              lastMessage: ConversationLastMessagePreview(
                id: 601,
                messageType: 'text',
                text: 'Current preview',
                senderId: 2,
                senderName: 'Seller User',
                timestamp: DateTime.utc(2026, 4, 5, 11, 0),
              ),
            ),
          ],
        ),
        inboxSocketService: inboxSocketService,
      );

      await notifier.syncWithSession(
        SessionState(
          accessToken: 'live-token',
          profile: MeProfile(
            id: 1,
            email: 'buyer@example.com',
            username: 'buyer',
            name: 'Buyer User',
            role: 'user',
            chatPushEnabled: true,
            chatMessagePreviewEnabled: true,
            createdAt: DateTime.utc(2026, 4, 5),
          ),
        ),
      );
      inboxSocketService.emitMessage(
        MessageModel(
          id: 550,
          conversationId: 2,
          sender: const UserBrief(id: 2, name: 'Seller User'),
          messageType: 'text',
          text: 'Delayed older message',
          media: const [],
          clientTimestamp: DateTime.utc(2026, 4, 5, 10, 0),
          serverTimestamp: DateTime.utc(2026, 4, 5, 10, 0),
          statuses: const [],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.conversations.first.id, 1);
      expect(notifier.state.conversations[1].id, 2);
      expect(notifier.state.conversations[1].unreadCount, 1);
      expect(
        notifier.state.conversations[1].lastMessage?.text,
        'Current preview',
      );

      notifier.dispose();
      await inboxSocketService.dispose();
    },
  );

  test(
    'syncing from visible messages clears the last preview when none remain',
    () {
      final notifier = TestLoadConversationsNotifier(
        ConversationState(
          conversations: [
            _conversation(
              id: 1,
              title: 'Chat A',
              unreadCount: 2,
              lastMessage: const ConversationLastMessagePreview(
                id: 501,
                messageType: 'text',
                text: 'Hidden later',
                senderId: 2,
                senderName: 'Seller User',
              ),
            ),
          ],
        ),
      );

      notifier.syncConversationFromMessages(
        conversationId: 1,
        messages: const [],
        currentUserId: 1,
        isActiveConversation: true,
      );

      expect(notifier.state.conversations.single.lastMessage, isNull);
      expect(notifier.state.conversations.single.unreadCount, 0);
    },
  );

  test('deleted messages use a deleted preview label', () {
    final notifier = TestLoadConversationsNotifier(
      ConversationState(
        conversations: [_conversation(id: 1, title: 'Chat A', unreadCount: 0)],
      ),
    );

    notifier.touchConversationFromMessage(
      conversationId: 1,
      currentUserId: 1,
      message: MessageModel(
        id: 900,
        conversationId: 1,
        sender: const UserBrief(id: 1, name: 'Buyer User'),
        messageType: 'text',
        text: '',
        media: const [],
        clientTimestamp: DateTime.utc(2026, 4, 5, 13, 0),
        serverTimestamp: DateTime.utc(2026, 4, 5, 13, 0),
        isDeleted: true,
        statuses: const [],
      ),
    );

    expect(
      notifier.state.conversations.single.lastMessage?.text,
      'This message was deleted',
    );
  });
}

class TestLoadConversationsNotifier extends LoadConversationsNotifier {
  TestLoadConversationsNotifier(
    ConversationState initialState, {
    InboxSocketService? inboxSocketService,
  }) : super(ChatApi(Dio()), inboxSocketService ?? FakeInboxSocketService()) {
    state = initialState;
  }
}

class FakeInboxSocketService extends InboxSocketService {
  final StreamController<MessageModel> _messagesController =
      StreamController<MessageModel>.broadcast();
  final StreamController<ChatConnectionStatus> _statusController =
      StreamController<ChatConnectionStatus>.broadcast();
  String? lastConnectedToken;

  @override
  Stream<MessageModel> get messages => _messagesController.stream;

  @override
  Stream<ChatConnectionStatus> get statuses => _statusController.stream;

  void emitMessage(MessageModel message) {
    _messagesController.add(message);
  }

  @override
  Future<void> connect({required String token}) async {
    lastConnectedToken = token;
    _statusController.add(ChatConnectionStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    lastConnectedToken = null;
    _statusController.add(ChatConnectionStatus.disconnected);
  }

  @override
  Future<void> dispose() async {
    await _messagesController.close();
    await _statusController.close();
  }
}

ConversationListItem _conversation({
  required int id,
  required String title,
  required int unreadCount,
  ConversationLastMessagePreview? lastMessage,
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
