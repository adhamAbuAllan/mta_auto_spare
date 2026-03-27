import '../../models/models.dart';

class MessageState {
  const MessageState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.errorMessage,
    this.conversationId,
    this.messages = const [],
    this.nextPageUrl,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final String? errorMessage;
  final int? conversationId;
  final List<MessageModel> messages;
  final String? nextPageUrl;

  bool get hasMore => nextPageUrl != null && nextPageUrl!.isNotEmpty;

  MessageState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    Object? errorMessage = _messageUnset,
    Object? conversationId = _messageUnset,
    List<MessageModel>? messages,
    Object? nextPageUrl = _messageUnset,
  }) {
    return MessageState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      errorMessage: identical(errorMessage, _messageUnset)
          ? this.errorMessage
          : errorMessage as String?,
      conversationId: identical(conversationId, _messageUnset)
          ? this.conversationId
          : conversationId as int?,
      messages: messages ?? this.messages,
      nextPageUrl: identical(nextPageUrl, _messageUnset)
          ? this.nextPageUrl
          : nextPageUrl as String?,
    );
  }
}

const _messageUnset = Object();
