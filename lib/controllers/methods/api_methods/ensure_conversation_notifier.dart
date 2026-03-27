import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/chat_api.dart';
import '../../../models/models.dart';
import '../../statuses/conversation_state.dart';

class EnsureConversationNotifier
    extends StateNotifier<EnsureConversationState> {
  EnsureConversationNotifier(this._chatApi)
    : super(const EnsureConversationState());

  final ChatApi _chatApi;

  Future<int?> ensureConversation({
    required int currentUserId,
    required int ownerUserId,
    required String requestTitle,
    List<ConversationListItem>? currentConversations,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      conversationId: null,
      wasCreated: false,
    );

    try {
      var conversations =
          currentConversations ?? const <ConversationListItem>[];

      var existingConversation = _findExistingConversation(
        conversations: conversations,
        currentUserId: currentUserId,
        ownerUserId: ownerUserId,
      );

      if (existingConversation == null &&
          currentConversations != null &&
          currentConversations.isNotEmpty) {
        conversations = await _chatApi.getAllConversations();
        existingConversation = _findExistingConversation(
          conversations: conversations,
          currentUserId: currentUserId,
          ownerUserId: ownerUserId,
        );
      } else if (existingConversation == null && currentConversations == null) {
        conversations = await _chatApi.getAllConversations();
        existingConversation = _findExistingConversation(
          conversations: conversations,
          currentUserId: currentUserId,
          ownerUserId: ownerUserId,
        );
      }

      if (existingConversation != null) {
        state = state.copyWith(
          isLoading: false,
          conversationId: existingConversation.id,
          wasCreated: false,
        );
        return existingConversation.id;
      }

      final conversation = await _chatApi.createConversation(
        title: 'Chat about $requestTitle',
      );
      await _chatApi.addParticipant(
        conversationId: conversation.id!,
        userId: ownerUserId,
      );

      state = state.copyWith(
        isLoading: false,
        conversationId: conversation.id,
        wasCreated: true,
      );
      return conversation.id;
    } on ApiException catch (error) {
      debugPrint(
        '[Chat][EnsureConversation][owner=$ownerUserId][current=$currentUserId] ${error.message}',
      );
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      debugPrint(
        '[Chat][EnsureConversation][owner=$ownerUserId][current=$currentUserId][Unexpected] ${error.toString()}',
      );
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }

    return null;
  }

  ConversationListItem? _findExistingConversation({
    required List<ConversationListItem> conversations,
    required int currentUserId,
    required int ownerUserId,
  }) {
    for (final conversation in conversations) {
      final participantIds = conversation.participants
          .map((participant) => participant.user.id)
          .toSet();
      if (participantIds.length == 2 &&
          participantIds.contains(currentUserId) &&
          participantIds.contains(ownerUserId)) {
        return conversation;
      }
    }
    return null;
  }
}
