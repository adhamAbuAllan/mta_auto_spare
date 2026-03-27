import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/chat_api.dart';
import '../../../models/models.dart';
import '../../statuses/conversation_state.dart';

class LoadConversationsNotifier extends StateNotifier<ConversationState> {
  LoadConversationsNotifier(this._chatApi) : super(const ConversationState());

  final ChatApi _chatApi;

  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh && state.conversations.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      nextPageUrl: forceRefresh ? state.nextPageUrl : null,
      conversations: forceRefresh ? state.conversations : const [],
    );

    try {
      final page = await _chatApi.getConversations();
      state = state.copyWith(
        isLoading: false,
        conversations: page.results,
        nextPageUrl: page.next,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      debugPrint('[Chat][Conversations][Load] ${error.message}');
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      debugPrint('[Chat][Conversations][Load][Unexpected] ${error.toString()}');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final page = await _chatApi.getConversations(pageUrl: state.nextPageUrl);
      state = state.copyWith(
        isLoadingMore: false,
        conversations: [...state.conversations, ...page.results],
        nextPageUrl: page.next,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      debugPrint('[Chat][Conversations][LoadMore] ${error.message}');
      state = state.copyWith(isLoadingMore: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      debugPrint(
        '[Chat][Conversations][LoadMore][Unexpected] ${error.toString()}',
      );
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  void touchConversationFromMessage({
    required int conversationId,
    required MessageModel message,
    required int currentUserId,
    bool isActiveConversation = false,
  }) {
    final index = state.conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index == -1) {
      return;
    }

    final currentConversation = state.conversations[index];
    final nextUnreadCount = isActiveConversation || message.sender.id == currentUserId
        ? 0
        : currentConversation.unreadCount + 1;
    final updatedConversation = currentConversation.copyWith(
      lastMessage: ConversationLastMessagePreview(
        id: message.id,
        text: message.text,
        senderId: message.sender.id,
        senderName: message.sender.name,
        timestamp: message.serverTimestamp ?? message.clientTimestamp,
      ),
      unreadCount: nextUnreadCount,
    );

    final updatedList = [...state.conversations];
    updatedList.removeAt(index);
    updatedList.insert(0, updatedConversation);

    state = state.copyWith(conversations: updatedList);
  }

  void markConversationRead(int conversationId) {
    final index = state.conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index == -1) {
      return;
    }
    final updatedList = [...state.conversations];
    updatedList[index] = updatedList[index].copyWith(unreadCount: 0);
    state = state.copyWith(conversations: updatedList);
  }
}
