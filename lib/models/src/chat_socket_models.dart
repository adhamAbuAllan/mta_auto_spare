import 'chat_rest_models.dart';
import 'json_utils.dart';

class ConversationRuntimeState {
  const ConversationRuntimeState({
    required this.conversationId,
    required this.connectedUserIds,
    required this.typingUserIds,
  });

  final int conversationId;
  final List<int> connectedUserIds;
  final List<int> typingUserIds;

  factory ConversationRuntimeState.fromJson(JsonMap json) {
    return ConversationRuntimeState(
      conversationId: intFromJson(json['conversation_id']) ?? 0,
      connectedUserIds: intListFromJson(json['connected_user_ids']),
      typingUserIds: intListFromJson(json['typing_user_ids']),
    );
  }

  JsonMap toJson() {
    return {
      'conversation_id': conversationId,
      'connected_user_ids': connectedUserIds,
      'typing_user_ids': typingUserIds,
    };
  }
}

abstract class ChatSocketEvent {
  const ChatSocketEvent(this.type);

  final String type;

  factory ChatSocketEvent.fromJson(JsonMap json) {
    final type = stringFromJson(json['type']) ?? '';
    switch (type) {
      case 'conversation.state':
        return ConversationStateSocketEvent.fromJson(json);
      case 'message.created':
        return MessageCreatedSocketEvent.fromJson(json);
      case 'conversation.typing':
        return ConversationTypingSocketEvent.fromJson(json);
      case 'conversation.seen':
        return ConversationSeenSocketEvent.fromJson(json);
      case 'message.status':
        return MessageStatusSocketEvent.fromJson(json);
      case 'pong':
        return PongSocketEvent.fromJson(json);
      case 'error':
        return ErrorSocketEvent.fromJson(json);
      default:
        return UnknownSocketEvent.fromJson(json);
    }
  }

  JsonMap toJson();
}

class ConversationStateSocketEvent extends ChatSocketEvent {
  ConversationStateSocketEvent({required this.state})
    : super('conversation.state');

  final ConversationRuntimeState state;

  factory ConversationStateSocketEvent.fromJson(JsonMap json) {
    return ConversationStateSocketEvent(
      state: ConversationRuntimeState.fromJson(json),
    );
  }

  @override
  JsonMap toJson() {
    return {'type': type, ...state.toJson()};
  }
}

class MessageCreatedSocketEvent extends ChatSocketEvent {
  MessageCreatedSocketEvent({required this.message}) : super('message.created');

  final MessageModel message;

  factory MessageCreatedSocketEvent.fromJson(JsonMap json) {
    return MessageCreatedSocketEvent(
      message: MessageModel.fromJson(mapFromJson(json['message']) ?? const {}),
    );
  }

  @override
  JsonMap toJson() {
    return {'type': type, 'message': message.toJson()};
  }
}

class ConversationTypingSocketEvent extends ChatSocketEvent {
  ConversationTypingSocketEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  }) : super('conversation.typing');

  final int conversationId;
  final int userId;
  final bool isTyping;

  factory ConversationTypingSocketEvent.fromJson(JsonMap json) {
    return ConversationTypingSocketEvent(
      conversationId: intFromJson(json['conversation_id']) ?? 0,
      userId: intFromJson(json['user_id']) ?? 0,
      isTyping: boolFromJson(json['is_typing']) ?? false,
    );
  }

  @override
  JsonMap toJson() {
    return {
      'type': type,
      'conversation_id': conversationId,
      'user_id': userId,
      'is_typing': isTyping,
    };
  }
}

class ConversationSeenSocketEvent extends ChatSocketEvent {
  ConversationSeenSocketEvent({
    required this.conversationId,
    required this.userId,
    this.seenAt,
  }) : super('conversation.seen');

  final int conversationId;
  final int userId;
  final DateTime? seenAt;

  factory ConversationSeenSocketEvent.fromJson(JsonMap json) {
    return ConversationSeenSocketEvent(
      conversationId: intFromJson(json['conversation_id']) ?? 0,
      userId: intFromJson(json['user_id']) ?? 0,
      seenAt: dateTimeFromJson(json['seen_at']),
    );
  }

  @override
  JsonMap toJson() {
    return {
      'type': type,
      'conversation_id': conversationId,
      'user_id': userId,
      'seen_at': seenAt?.toIso8601String(),
    };
  }
}

class MessageStatusSocketEvent extends ChatSocketEvent {
  MessageStatusSocketEvent({required this.status}) : super('message.status');

  final MessageStatusModel status;

  factory MessageStatusSocketEvent.fromJson(JsonMap json) {
    return MessageStatusSocketEvent(status: MessageStatusModel.fromJson(json));
  }

  @override
  JsonMap toJson() {
    return {'type': type, ...status.toJson()};
  }
}

class PongSocketEvent extends ChatSocketEvent {
  PongSocketEvent({required this.conversationId, this.serverTimestamp})
    : super('pong');

  final int conversationId;
  final DateTime? serverTimestamp;

  factory PongSocketEvent.fromJson(JsonMap json) {
    return PongSocketEvent(
      conversationId: intFromJson(json['conversation_id']) ?? 0,
      serverTimestamp: dateTimeFromJson(json['server_timestamp']),
    );
  }

  @override
  JsonMap toJson() {
    return {
      'type': type,
      'conversation_id': conversationId,
      'server_timestamp': serverTimestamp?.toIso8601String(),
    };
  }
}

class ErrorSocketEvent extends ChatSocketEvent {
  ErrorSocketEvent({required this.detail}) : super('error');

  final String detail;

  factory ErrorSocketEvent.fromJson(JsonMap json) {
    return ErrorSocketEvent(detail: stringFromJson(json['detail']) ?? '');
  }

  @override
  JsonMap toJson() {
    return {'type': type, 'detail': detail};
  }
}

class UnknownSocketEvent extends ChatSocketEvent {
  UnknownSocketEvent({required this.payload})
    : super(stringFromJson(payload['type']) ?? 'unknown');

  final JsonMap payload;

  factory UnknownSocketEvent.fromJson(JsonMap json) {
    return UnknownSocketEvent(payload: Map<String, dynamic>.from(json));
  }

  @override
  JsonMap toJson() {
    return payload;
  }
}

class SocketMediaFilePayload {
  const SocketMediaFilePayload({
    required this.name,
    required this.contentType,
    required this.dataBase64,
  });

  final String name;
  final String contentType;
  final String dataBase64;

  JsonMap toJson() {
    return {
      'name': name,
      'content_type': contentType,
      'data_base64': dataBase64,
    };
  }
}

class ChatMessageSocketRequest {
  const ChatMessageSocketRequest({
    this.text,
    this.messageType = 'text',
    this.clientTimestamp,
    this.productId,
    this.replyToId,
    this.mediaFiles = const [],
  });

  final String? text;
  final String messageType;
  final DateTime? clientTimestamp;
  final int? productId;
  final int? replyToId;
  final List<SocketMediaFilePayload> mediaFiles;

  JsonMap toJson() {
    return {
      'type': 'chat_message',
      'text': text,
      'message_type': messageType,
      'client_timestamp': clientTimestamp?.toIso8601String(),
      'product_id': productId,
      'reply_to_id': replyToId,
      'media_files': mediaFiles
          .map((file) => file.toJson())
          .toList(growable: false),
    };
  }
}

class TypingStartSocketRequest {
  const TypingStartSocketRequest();

  JsonMap toJson() => const {'type': 'typing_start'};
}

class TypingStopSocketRequest {
  const TypingStopSocketRequest();

  JsonMap toJson() => const {'type': 'typing_stop'};
}

class SeenSocketRequest {
  const SeenSocketRequest();

  JsonMap toJson() => const {'type': 'seen'};
}

class PingSocketRequest {
  const PingSocketRequest();

  JsonMap toJson() => const {'type': 'ping'};
}
