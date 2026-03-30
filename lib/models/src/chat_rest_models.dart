import 'json_utils.dart';
import 'market_models.dart';
import 'user_models.dart';

class ConversationModel {
  const ConversationModel({
    this.id,
    required this.title,
    this.lastMessage,
    this.lastMessageTime,
    this.createdAt,
  });

  final int? id;
  final String title;
  final int? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;

  factory ConversationModel.fromJson(JsonMap json) {
    return ConversationModel(
      id: intFromJson(json['id']),
      title: stringFromJson(json['title']) ?? '',
      lastMessage: intFromJson(json['last_message']),
      lastMessageTime: dateTimeFromJson(json['last_message_time']),
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ConversationParticipantModel {
  const ConversationParticipantModel({
    this.id,
    required this.conversation,
    required this.user,
    this.joinedAt,
    this.lastReadAt,
  });

  final int? id;
  final int conversation;
  final int user;
  final DateTime? joinedAt;
  final DateTime? lastReadAt;

  factory ConversationParticipantModel.fromJson(JsonMap json) {
    return ConversationParticipantModel(
      id: intFromJson(json['id']),
      conversation: intFromJson(json['conversation']) ?? 0,
      user: intFromJson(json['user']) ?? 0,
      joinedAt: dateTimeFromJson(json['joined_at']),
      lastReadAt: dateTimeFromJson(json['last_read_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'conversation': conversation,
      'user': user,
      'joined_at': joinedAt?.toIso8601String(),
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }
}

class ConversationParticipantRead {
  const ConversationParticipantRead({
    required this.id,
    required this.user,
    this.joinedAt,
    this.lastReadAt,
  });

  final int id;
  final UserBrief user;
  final DateTime? joinedAt;
  final DateTime? lastReadAt;

  factory ConversationParticipantRead.fromJson(JsonMap json) {
    return ConversationParticipantRead(
      id: intFromJson(json['id']) ?? 0,
      user: UserBrief.fromJson(mapFromJson(json['user']) ?? const {}),
      joinedAt: dateTimeFromJson(json['joined_at']),
      lastReadAt: dateTimeFromJson(json['last_read_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'joined_at': joinedAt?.toIso8601String(),
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }

  ConversationParticipantRead copyWith({
    int? id,
    UserBrief? user,
    Object? joinedAt = _conversationParticipantReadUnset,
    Object? lastReadAt = _conversationParticipantReadUnset,
  }) {
    return ConversationParticipantRead(
      id: id ?? this.id,
      user: user ?? this.user,
      joinedAt: identical(joinedAt, _conversationParticipantReadUnset)
          ? this.joinedAt
          : joinedAt as DateTime?,
      lastReadAt: identical(lastReadAt, _conversationParticipantReadUnset)
          ? this.lastReadAt
          : lastReadAt as DateTime?,
    );
  }
}

const _conversationParticipantReadUnset = Object();

class ConversationLastMessagePreview {
  const ConversationLastMessagePreview({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.timestamp,
  });

  final int id;
  final String text;
  final int senderId;
  final String senderName;
  final DateTime? timestamp;

  factory ConversationLastMessagePreview.fromJson(JsonMap json) {
    final senderJson = mapFromJson(json['sender']) ?? const {};
    return ConversationLastMessagePreview(
      id: intFromJson(json['id']) ?? 0,
      text: stringFromJson(json['text']) ?? '',
      senderId: intFromJson(senderJson['id']) ?? 0,
      senderName: stringFromJson(senderJson['name']) ?? '',
      timestamp: dateTimeFromJson(json['timestamp']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'text': text,
      'sender': {'id': senderId, 'name': senderName},
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  ConversationLastMessagePreview copyWith({
    int? id,
    String? text,
    int? senderId,
    String? senderName,
    DateTime? timestamp,
  }) {
    return ConversationLastMessagePreview(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class ConversationListItem {
  const ConversationListItem({
    required this.id,
    required this.title,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
  });

  final int id;
  final String title;
  final List<ConversationParticipantRead> participants;
  final ConversationLastMessagePreview? lastMessage;
  final int unreadCount;

  factory ConversationListItem.fromJson(JsonMap json) {
    return ConversationListItem(
      id: intFromJson(json['id']) ?? 0,
      title: stringFromJson(json['title']) ?? '',
      participants: listFromJson(
        json['participants'],
        ConversationParticipantRead.fromJson,
      ),
      lastMessage: mapFromJson(json['last_message']) == null
          ? null
          : ConversationLastMessagePreview.fromJson(
              mapFromJson(json['last_message'])!,
            ),
      unreadCount: intFromJson(json['unread_count']) ?? 0,
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'participants': participants
          .map((participant) => participant.toJson())
          .toList(growable: false),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
    };
  }

  ConversationListItem copyWith({
    int? id,
    String? title,
    List<ConversationParticipantRead>? participants,
    Object? lastMessage = _conversationListItemUnset,
    int? unreadCount,
  }) {
    return ConversationListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      lastMessage: identical(lastMessage, _conversationListItemUnset)
          ? this.lastMessage
          : lastMessage as ConversationLastMessagePreview?,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

const _conversationListItemUnset = Object();

class MessageAttachmentModel {
  const MessageAttachmentModel({
    required this.id,
    this.fileUrl,
    this.localPath,
    this.contentType,
    required this.size,
    this.createdAt,
  });

  final int id;
  final String? fileUrl;
  final String? localPath;
  final String? contentType;
  final int size;
  final DateTime? createdAt;

  bool get isImage => (contentType ?? '').toLowerCase().startsWith('image/');

  factory MessageAttachmentModel.fromJson(JsonMap json) {
    return MessageAttachmentModel(
      id: intFromJson(json['id']) ?? 0,
      fileUrl: stringFromJson(json['file_url']),
      localPath: stringFromJson(json['local_path']),
      contentType: stringFromJson(json['content_type']),
      size: intFromJson(json['size']) ?? 0,
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'file_url': fileUrl,
      'local_path': localPath,
      'content_type': contentType,
      'size': size,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  MessageAttachmentModel copyWith({
    int? id,
    Object? fileUrl = _messageAttachmentUnset,
    Object? localPath = _messageAttachmentUnset,
    Object? contentType = _messageAttachmentUnset,
    int? size,
    Object? createdAt = _messageAttachmentUnset,
  }) {
    return MessageAttachmentModel(
      id: id ?? this.id,
      fileUrl: identical(fileUrl, _messageAttachmentUnset)
          ? this.fileUrl
          : fileUrl as String?,
      localPath: identical(localPath, _messageAttachmentUnset)
          ? this.localPath
          : localPath as String?,
      contentType: identical(contentType, _messageAttachmentUnset)
          ? this.contentType
          : contentType as String?,
      size: size ?? this.size,
      createdAt: identical(createdAt, _messageAttachmentUnset)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }
}

const _messageAttachmentUnset = Object();

class ChatUploadImage {
  const ChatUploadImage({
    required this.path,
    required this.fileName,
    required this.contentType,
    this.size = 0,
  });

  final String path;
  final String fileName;
  final String contentType;
  final int size;

  MessageAttachmentModel toOptimisticAttachment({required int id}) {
    return MessageAttachmentModel(
      id: id,
      localPath: path,
      contentType: contentType,
      size: size,
    );
  }
}

class MessageStatusModel {
  const MessageStatusModel({
    required this.conversationId,
    required this.messageId,
    required this.userId,
    required this.status,
    this.updatedAt,
  });

  final int conversationId;
  final int messageId;
  final int userId;
  final String status;
  final DateTime? updatedAt;

  factory MessageStatusModel.fromJson(JsonMap json) {
    return MessageStatusModel(
      conversationId: intFromJson(json['conversation_id']) ?? 0,
      messageId: intFromJson(json['message_id']) ?? 0,
      userId: intFromJson(json['user_id']) ?? 0,
      status: stringFromJson(json['status']) ?? '',
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  JsonMap toJson() {
    return {
      'conversation_id': conversationId,
      'message_id': messageId,
      'user_id': userId,
      'status': status,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

enum MessageReceiptState { pending, sent, delivered, seen, failed }

class MessageReplyModel {
  const MessageReplyModel({
    required this.id,
    required this.sender,
    required this.text,
    this.product,
    this.clientTimestamp,
    this.serverTimestamp,
  });

  final int id;
  final UserBrief sender;
  final String text;
  final PartRequestBrief? product;
  final DateTime? clientTimestamp;
  final DateTime? serverTimestamp;

  factory MessageReplyModel.fromJson(JsonMap json) {
    return MessageReplyModel(
      id: intFromJson(json['id']) ?? 0,
      sender: UserBrief.fromJson(mapFromJson(json['sender']) ?? const {}),
      text: stringFromJson(json['text']) ?? '',
      product: mapFromJson(json['product']) == null
          ? null
          : PartRequestBrief.fromJson(mapFromJson(json['product'])!),
      clientTimestamp: dateTimeFromJson(json['client_timestamp']),
      serverTimestamp: dateTimeFromJson(json['server_timestamp']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'text': text,
      'product': product?.toJson(),
      'client_timestamp': clientTimestamp?.toIso8601String(),
      'server_timestamp': serverTimestamp?.toIso8601String(),
    };
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.messageType,
    required this.text,
    required this.media,
    this.product,
    this.replyTo,
    this.clientTimestamp,
    this.serverTimestamp,
    required this.statuses,
    this.localMessageId,
    this.isOptimistic = false,
    this.hasSendError = false,
  });

  final int id;
  final int conversationId;
  final UserBrief sender;
  final String messageType;
  final String text;
  final List<MessageAttachmentModel> media;
  final PartRequestBrief? product;
  final MessageReplyModel? replyTo;
  final DateTime? clientTimestamp;
  final DateTime? serverTimestamp;
  final List<MessageStatusModel> statuses;
  final String? localMessageId;
  final bool isOptimistic;
  final bool hasSendError;

  factory MessageModel.fromJson(JsonMap json) {
    return MessageModel(
      id: intFromJson(json['id']) ?? 0,
      conversationId: intFromJson(json['conversation_id']) ?? 0,
      sender: UserBrief.fromJson(mapFromJson(json['sender']) ?? const {}),
      messageType: stringFromJson(json['message_type']) ?? 'text',
      text: stringFromJson(json['text']) ?? '',
      media: listFromJson(json['media'], MessageAttachmentModel.fromJson),
      product: mapFromJson(json['product']) == null
          ? null
          : PartRequestBrief.fromJson(mapFromJson(json['product'])!),
      replyTo: mapFromJson(json['reply_to']) == null
          ? null
          : MessageReplyModel.fromJson(mapFromJson(json['reply_to'])!),
      clientTimestamp: dateTimeFromJson(json['client_timestamp']),
      serverTimestamp: dateTimeFromJson(json['server_timestamp']),
      statuses: listFromJson(json['statuses'], MessageStatusModel.fromJson),
      localMessageId: stringFromJson(json['local_message_id']),
      isOptimistic: boolFromJson(json['is_optimistic']) ?? false,
      hasSendError: boolFromJson(json['has_send_error']) ?? false,
    );
  }

  JsonMap toJson() {
    final json = <String, dynamic>{
      'id': id,
      'conversation_id': conversationId,
      'sender': sender.toJson(),
      'message_type': messageType,
      'text': text,
      'media': media.map((item) => item.toJson()).toList(growable: false),
      'product': product?.toJson(),
      'reply_to': replyTo?.toJson(),
      'client_timestamp': clientTimestamp?.toIso8601String(),
      'server_timestamp': serverTimestamp?.toIso8601String(),
      'statuses': statuses.map((item) => item.toJson()).toList(growable: false),
    };
    if (localMessageId != null && localMessageId!.isNotEmpty) {
      json['local_message_id'] = localMessageId;
    }
    if (isOptimistic) {
      json['is_optimistic'] = true;
    }
    if (hasSendError) {
      json['has_send_error'] = true;
    }
    return json;
  }

  MessageModel copyWith({
    int? id,
    int? conversationId,
    UserBrief? sender,
    String? messageType,
    String? text,
    List<MessageAttachmentModel>? media,
    Object? product = _messageModelUnset,
    Object? replyTo = _messageModelUnset,
    Object? clientTimestamp = _messageModelUnset,
    Object? serverTimestamp = _messageModelUnset,
    List<MessageStatusModel>? statuses,
    Object? localMessageId = _messageModelUnset,
    bool? isOptimistic,
    bool? hasSendError,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      messageType: messageType ?? this.messageType,
      text: text ?? this.text,
      media: media ?? this.media,
      product: identical(product, _messageModelUnset)
          ? this.product
          : product as PartRequestBrief?,
      replyTo: identical(replyTo, _messageModelUnset)
          ? this.replyTo
          : replyTo as MessageReplyModel?,
      clientTimestamp: identical(clientTimestamp, _messageModelUnset)
          ? this.clientTimestamp
          : clientTimestamp as DateTime?,
      serverTimestamp: identical(serverTimestamp, _messageModelUnset)
          ? this.serverTimestamp
          : serverTimestamp as DateTime?,
      statuses: statuses ?? this.statuses,
      localMessageId: identical(localMessageId, _messageModelUnset)
          ? this.localMessageId
          : localMessageId as String?,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      hasSendError: hasSendError ?? this.hasSendError,
    );
  }

  factory MessageModel.optimistic({
    required int tempId,
    required int conversationId,
    required UserBrief sender,
    required String messageType,
    required String text,
    required DateTime clientTimestamp,
    String? localMessageId,
    PartRequestBrief? product,
    MessageReplyModel? replyTo,
    List<MessageAttachmentModel> media = const [],
  }) {
    return MessageModel(
      id: tempId,
      conversationId: conversationId,
      sender: sender,
      messageType: messageType,
      text: text,
      media: media,
      product: product,
      replyTo: replyTo,
      clientTimestamp: clientTimestamp,
      serverTimestamp: null,
      statuses: const [],
      localMessageId: localMessageId,
      isOptimistic: true,
    );
  }

  MessageReceiptState receiptStateFor(int currentUserId) {
    if (hasSendError) {
      return MessageReceiptState.failed;
    }
    if (isOptimistic) {
      return MessageReceiptState.pending;
    }

    final participantStatuses = statuses
        .where((status) => status.userId != currentUserId)
        .map((status) => status.status)
        .toSet();

    if (participantStatuses.contains('seen')) {
      return MessageReceiptState.seen;
    }
    if (participantStatuses.contains('delivered')) {
      return MessageReceiptState.delivered;
    }
    return MessageReceiptState.sent;
  }
}

const _messageModelUnset = Object();

class MessageCreateRequest {
  const MessageCreateRequest({
    required this.conversation,
    required this.messageType,
    this.text,
    this.product,
    this.replyTo,
    required this.clientTimestamp,
    this.attachments = const [],
  });

  final int conversation;
  final String messageType;
  final String? text;
  final int? product;
  final int? replyTo;
  final DateTime clientTimestamp;
  final List<ChatUploadImage> attachments;

  JsonMap toJson() {
    return {
      'conversation': conversation,
      'message_type': messageType,
      'text': text,
      'product': product,
      'reply_to': replyTo,
      'client_timestamp': clientTimestamp.toIso8601String(),
    };
  }
}

class TypingStatusModel {
  const TypingStatusModel({
    this.id,
    required this.conversation,
    required this.user,
    required this.isTyping,
    this.updatedAt,
  });

  final int? id;
  final int conversation;
  final int user;
  final bool isTyping;
  final DateTime? updatedAt;

  factory TypingStatusModel.fromJson(JsonMap json) {
    return TypingStatusModel(
      id: intFromJson(json['id']),
      conversation: intFromJson(json['conversation']) ?? 0,
      user: intFromJson(json['user']) ?? 0,
      isTyping: boolFromJson(json['is_typing']) ?? false,
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'conversation': conversation,
      'user': user,
      'is_typing': isTyping,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class MessageReactionModel {
  const MessageReactionModel({
    this.id,
    required this.message,
    required this.user,
    required this.emoji,
    this.createdAt,
  });

  final int? id;
  final int message;
  final int user;
  final String emoji;
  final DateTime? createdAt;

  factory MessageReactionModel.fromJson(JsonMap json) {
    return MessageReactionModel(
      id: intFromJson(json['id']),
      message: intFromJson(json['message']) ?? 0,
      user: intFromJson(json['user']) ?? 0,
      emoji: stringFromJson(json['emoji']) ?? '',
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'message': message,
      'user': user,
      'emoji': emoji,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
