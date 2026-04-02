import '../../api/chat_socket_service.dart';
import '../../models/models.dart';

class MessageState {
  const MessageState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.pendingMessageCount = 0,
    this.errorMessage,
    this.conversationId,
    this.messages = const [],
    this.nextPageUrl,
    this.connectionStatus = ChatConnectionStatus.disconnected,
    this.connectedUserIds = const [],
    this.typingUserIds = const [],
    this.onlineUserIds = const [],
    this.lastSeenByUserId = const {},
    this.presenceLastSeenByUserId = const {},
  });

  final bool isLoading;
  final bool isLoadingMore;
  final int pendingMessageCount;
  final String? errorMessage;
  final int? conversationId;
  final List<MessageModel> messages;
  final String? nextPageUrl;
  final ChatConnectionStatus connectionStatus;
  final List<int> connectedUserIds;
  final List<int> typingUserIds;
  final List<int> onlineUserIds;
  final Map<int, DateTime?> lastSeenByUserId;
  final Map<int, DateTime?> presenceLastSeenByUserId;

  //  bool get hasMore => nextPageUrl != null && nextPageUrl!.isNotEmpty;
  bool get isSending => pendingMessageCount > 0;
  bool get isLive => connectionStatus == ChatConnectionStatus.connected;

  MessageState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    int? pendingMessageCount,
    Object? errorMessage = _messageUnset,
    Object? conversationId = _messageUnset,
    List<MessageModel>? messages,
    Object? nextPageUrl = _messageUnset,
    ChatConnectionStatus? connectionStatus,
    List<int>? connectedUserIds,
    List<int>? typingUserIds,
    List<int>? onlineUserIds,
    Map<int, DateTime?>? lastSeenByUserId,
    Map<int, DateTime?>? presenceLastSeenByUserId,
  }) {
    return MessageState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pendingMessageCount: pendingMessageCount ?? this.pendingMessageCount,
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
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectedUserIds: connectedUserIds ?? this.connectedUserIds,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
      lastSeenByUserId: lastSeenByUserId ?? this.lastSeenByUserId,
      presenceLastSeenByUserId:
          presenceLastSeenByUserId ?? this.presenceLastSeenByUserId,
    );
  }
}

const _messageUnset = Object();
