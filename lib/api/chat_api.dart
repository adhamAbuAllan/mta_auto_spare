import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';
import 'dio_client.dart';

int? _intFromDynamic(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '');
}

class DeleteMessageResponse {
  const DeleteMessageResponse({
    required this.scope,
    required this.messageId,
    required this.conversationId,
    this.message,
  });

  final String scope;
  final int messageId;
  final int conversationId;
  final MessageModel? message;

  factory DeleteMessageResponse.fromJson(Map<String, dynamic> json) {
    final messageJson = json['message'];
    return DeleteMessageResponse(
      scope: (json['scope'] ?? '').toString(),
      messageId: _intFromDynamic(json['message_id']) ?? 0,
      conversationId: _intFromDynamic(json['conversation_id']) ?? 0,
      message: messageJson is Map<String, dynamic>
          ? MessageModel.fromJson(messageJson)
          : messageJson is Map
          ? MessageModel.fromJson(Map<String, dynamic>.from(messageJson))
          : null,
    );
  }
}

class ChatApi {
  const ChatApi(this._dio);

  final Dio _dio;

  Future<ApiPage<ConversationListItem>> getConversations({
    String? pageUrl,
  }) async {
    try {
      final response = pageUrl == null
          ? await _dio.get(ApiEndpoints.conversations)
          : await _dio.get(pageUrl);
      return ApiPage<ConversationListItem>.fromJson(
        _asMap(response.data),
        ConversationListItem.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<ConversationListItem>> getAllConversations() async {
    final conversations = <ConversationListItem>[];
    String? nextPageUrl;

    do {
      final page = await getConversations(pageUrl: nextPageUrl);
      conversations.addAll(page.results);
      nextPageUrl = page.next;
    } while (nextPageUrl != null && nextPageUrl.isNotEmpty);

    return conversations;
  }

  Future<ConversationModel> createConversation({required String title}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.conversations,
        data: {'title': title},
      );
      return ConversationModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ConversationParticipantModel> addParticipant({
    required int conversationId,
    required int userId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.conversationParticipants,
        data: {'conversation': conversationId, 'user': userId},
      );
      return ConversationParticipantModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiPage<MessageModel>> getMessages({
    required int conversationId,
    String? pageUrl,
  }) async {
    try {
      final response = pageUrl == null
          ? await _dio.get(
              ApiEndpoints.messages,
              queryParameters: {'conversation_id': conversationId},
            )
          : await _dio.get(pageUrl);
      return ApiPage<MessageModel>.fromJson(
        _asMap(response.data),
        MessageModel.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<MessageModel> createMessage(MessageCreateRequest request) async {
    try {
      final retryDataBuilder = request.attachments.isEmpty
          ? null
          : () => _buildMultipartPayload(request);
      final payload = retryDataBuilder == null
          ? request.toJson()
          : await retryDataBuilder();
      final response = await _dio.post(
        ApiEndpoints.messages,
        data: payload,
        options: retryDataBuilder == null
            ? null
            : Options(
                extra: {
                  AppDioClient.retryDataBuilderExtraKey: retryDataBuilder,
                },
              ),
      );
      return MessageModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<MessageModel> editMessage({
    required int messageId,
    required String text,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.messages}$messageId/',
        data: {'text': text.trim()},
      );
      return MessageModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<DeleteMessageResponse> deleteMessage({
    required int messageId,
    required String scope,
  }) async {
    try {
      final response = await _dio.delete(
        '${ApiEndpoints.messages}$messageId/',
        queryParameters: {'scope': scope},
      );
      return DeleteMessageResponse.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<FormData> _buildMultipartPayload(MessageCreateRequest request) async {
    final data = <String, dynamic>{
      'conversation': request.conversation.toString(),
      'message_type': request.messageType,
      'client_timestamp': request.clientTimestamp.toIso8601String(),
      'files': await Future.wait(
        request.attachments.map(
          (attachment) => MultipartFile.fromFile(
            attachment.path,
            filename: attachment.fileName,
            contentType: MediaType.parse(attachment.contentType),
          ),
        ),
      ),
    };
    if (request.text != null && request.text!.trim().isNotEmpty) {
      data['text'] = request.text!.trim();
    }
    if (request.product != null) {
      data['product'] = request.product.toString();
    }
    if (request.replyTo != null) {
      data['reply_to'] = request.replyTo.toString();
    }
    return FormData.fromMap(data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw ApiException('Unexpected response format.');
  }
}
