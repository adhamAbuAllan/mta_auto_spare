import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/chat_api.dart';
import '../../../models/models.dart';
import '../../statuses/message_state.dart';

class LoadMessagesNotifier extends StateNotifier<MessageState> {
  LoadMessagesNotifier(this._chatApi) : super(const MessageState());

  final ChatApi _chatApi;

  Future<void> load(int conversationId) async {
    state = state.copyWith(
      isLoading: true,
      conversationId: conversationId,
      messages: const [],
      nextPageUrl: null,
      errorMessage: null,
    );

    try {
      final page = await _chatApi.getMessages(conversationId: conversationId);
      state = state.copyWith(
        isLoading: false,
        messages: page.results,
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
    final conversationId = state.conversationId;
    if (conversationId == null || !state.hasMore || state.isLoadingMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final page = await _chatApi.getMessages(
        conversationId: conversationId,
        pageUrl: state.nextPageUrl,
      );
      state = state.copyWith(
        isLoadingMore: false,
        messages: [...state.messages, ...page.results],
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

  Future<bool> send(MessageCreateRequest request) async {
    state = state.copyWith(isSending: true, errorMessage: null);

    try {
      final createdMessage = await _chatApi.createMessage(request);
      state = state.copyWith(
        isSending: false,
        messages: [...state.messages, createdMessage],
        errorMessage: null,
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isSending: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isSending: false, errorMessage: error.toString());
    }

    return false;
  }
}
