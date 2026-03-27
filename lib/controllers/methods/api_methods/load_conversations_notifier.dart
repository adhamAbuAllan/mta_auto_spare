import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/chat_api.dart';
import '../../statuses/conversation_state.dart';

class LoadConversationsNotifier extends StateNotifier<ConversationState> {
  LoadConversationsNotifier(this._chatApi) : super(const ConversationState());

  final ChatApi _chatApi;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      nextPageUrl: null,
      conversations: const [],
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
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
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
      state = state.copyWith(isLoadingMore: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }
}
