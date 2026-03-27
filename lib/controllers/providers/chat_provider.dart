import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/chat_socket_service.dart';
import '../../models/models.dart';
import '../methods/api_methods/load_conversations_notifier.dart';
import '../methods/api_methods/ensure_conversation_notifier.dart';
import '../methods/api_methods/load_messages_notifier.dart';
import '../statuses/conversation_state.dart';
import '../statuses/message_state.dart';
import 'api_provider.dart';

final selectedConversationIdProvider = StateProvider<int?>((ref) => null);
final pendingSharedProductProvider = StateProvider<PartRequestBrief?>(
  (ref) => null,
);

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final conversationsNotifierProvider =
    StateNotifierProvider<LoadConversationsNotifier, ConversationState>((ref) {
      return LoadConversationsNotifier(ref.read(chatApiProvider));
    });

final messagesNotifierProvider =
    StateNotifierProvider<LoadMessagesNotifier, MessageState>((ref) {
      return LoadMessagesNotifier(
        ref.read(chatApiProvider),
        ref.read(chatSocketServiceProvider),
        onMessagePreviewChanged: ({
          required conversationId,
          required message,
          required isActiveConversation,
          required currentUserId,
        }) {
          ref
              .read(conversationsNotifierProvider.notifier)
              .touchConversationFromMessage(
                conversationId: conversationId,
                message: message,
                isActiveConversation: isActiveConversation,
                currentUserId: currentUserId,
              );
        },
        onConversationReadChanged: (conversationId) {
          ref.read(conversationsNotifierProvider.notifier).markConversationRead(
            conversationId,
          );
        },
      );
    });

final ensureConversationNotifierProvider =
    StateNotifierProvider<EnsureConversationNotifier, EnsureConversationState>((
      ref,
    ) {
      return EnsureConversationNotifier(ref.read(chatApiProvider));
    });
