import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../methods/api_methods/load_conversations_notifier.dart';
import '../methods/api_methods/ensure_conversation_notifier.dart';
import '../methods/api_methods/load_messages_notifier.dart';
import '../statuses/conversation_state.dart';
import '../statuses/message_state.dart';
import 'api_provider.dart';

final selectedConversationIdProvider = StateProvider<int?>((ref) => null);

final conversationsNotifierProvider =
    StateNotifierProvider<LoadConversationsNotifier, ConversationState>((ref) {
      return LoadConversationsNotifier(ref.read(chatApiProvider));
    });

final messagesNotifierProvider =
    StateNotifierProvider<LoadMessagesNotifier, MessageState>((ref) {
      return LoadMessagesNotifier(ref.read(chatApiProvider));
    });

final ensureConversationNotifierProvider =
    StateNotifierProvider<EnsureConversationNotifier, EnsureConversationState>((
      ref,
    ) {
      return EnsureConversationNotifier(ref.read(chatApiProvider));
    });
