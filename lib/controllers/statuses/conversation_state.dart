import '../../models/models.dart';

class ConversationState {
  const ConversationState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.conversations = const [],
    this.nextPageUrl,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<ConversationListItem> conversations;
  final String? nextPageUrl;

  bool get hasMore => nextPageUrl != null && nextPageUrl!.isNotEmpty;

  ConversationState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    Object? errorMessage = _conversationUnset,
    List<ConversationListItem>? conversations,
    Object? nextPageUrl = _conversationUnset,
  }) {
    return ConversationState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _conversationUnset)
          ? this.errorMessage
          : errorMessage as String?,
      conversations: conversations ?? this.conversations,
      nextPageUrl: identical(nextPageUrl, _conversationUnset)
          ? this.nextPageUrl
          : nextPageUrl as String?,
    );
  }
}

const _conversationUnset = Object();

class EnsureConversationState {
  const EnsureConversationState({
    this.isLoading = false,
    this.errorMessage,
    this.conversationId,
    this.wasCreated = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final int? conversationId;
  final bool wasCreated;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  EnsureConversationState copyWith({
    bool? isLoading,
    Object? errorMessage = _ensureConversationUnset,
    Object? conversationId = _ensureConversationUnset,
    bool? wasCreated,
  }) {
    return EnsureConversationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _ensureConversationUnset)
          ? this.errorMessage
          : errorMessage as String?,
      conversationId: identical(conversationId, _ensureConversationUnset)
          ? this.conversationId
          : conversationId as int?,
      wasCreated: wasCreated ?? this.wasCreated,
    );
  }
}

const _ensureConversationUnset = Object();
