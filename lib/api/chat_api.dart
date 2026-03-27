import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';

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
      final response = await _dio.post(
        ApiEndpoints.messages,
        data: request.toJson(),
      );
      return MessageModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
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
