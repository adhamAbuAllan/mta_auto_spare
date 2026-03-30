import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/models.dart';
import '../../../models/src/json_utils.dart';
import '../../statuses/message_state.dart';

class ChatMessageCacheStore {
  ChatMessageCacheStore(this._preferences);

  static const _cacheKeyPrefix = 'chat_message_cache_v1';
  static const _maxStoredMessages = 120;

  final SharedPreferences _preferences;

  MessageState? readConversationState({
    required int userId,
    required int conversationId,
  }) {
    final raw = _preferences.getString(_cacheKey(userId, conversationId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final payload = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return MessageState(
        conversationId: conversationId,
        messages: listFromJson(payload['messages'], MessageModel.fromJson),
        nextPageUrl: stringFromJson(payload['next_page_url']),
        lastSeenByUserId: dateTimeMapByIntKeyFromJson(
          payload['last_seen_by_user_id'],
        ),
        presenceLastSeenByUserId: dateTimeMapByIntKeyFromJson(
          payload['presence_last_seen_at_by_user_id'],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeConversationState({
    required int userId,
    required int conversationId,
    required MessageState state,
  }) async {
    final messages = state.messages.length <= _maxStoredMessages
        ? state.messages
        : state.messages.sublist(state.messages.length - _maxStoredMessages);

    final payload = <String, dynamic>{
      'conversation_id': conversationId,
      'messages': messages.map((message) => message.toJson()).toList(growable: false),
      'next_page_url': state.nextPageUrl,
      'last_seen_by_user_id': _serializeDateMap(state.lastSeenByUserId),
      'presence_last_seen_at_by_user_id': _serializeDateMap(
        state.presenceLastSeenByUserId,
      ),
    };

    await _preferences.setString(
      _cacheKey(userId, conversationId),
      jsonEncode(payload),
    );
  }

  Future<void> removeConversationState({
    required int userId,
    required int conversationId,
  }) async {
    await _preferences.remove(_cacheKey(userId, conversationId));
  }

  String _cacheKey(int userId, int conversationId) {
    return '$_cacheKeyPrefix:$userId:$conversationId';
  }

  Map<String, String?> _serializeDateMap(Map<int, DateTime?> values) {
    return {
      for (final entry in values.entries)
        entry.key.toString(): entry.value?.toIso8601String(),
    };
  }
}
