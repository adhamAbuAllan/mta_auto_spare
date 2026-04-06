import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mta_auto_spare/api/auth_api.dart';
import 'package:mta_auto_spare/constants/api_constants.dart';
import 'package:mta_auto_spare/controllers/methods/api_methods/session_bootstrapper.dart';
import 'package:mta_auto_spare/session/session_notifier.dart';

void main() {
  test(
    'restore refreshes tokens and keeps the signed-in session on cold start',
    () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'expired-access-token',
        'refresh_token': 'persisted-refresh-token',
        'profile_json': jsonEncode({
          'id': 8,
          'email': 'user@example.com',
          'username': 'userg',
          'name': 'User G',
          'role': 'buyer',
          'chat_push_enabled': true,
          'chat_message_preview_enabled': true,
          'created_at': '2026-04-01T00:00:00Z',
        }),
      });
      final preferences = await SharedPreferences.getInstance();
      final sessionNotifier = SessionNotifier(preferences);
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter([
        (options, _) async {
          expect(options.path, ApiEndpoints.refresh);
          return _jsonResponse({'access': 'fresh-access-token'}, 200);
        },
        (options, _) async {
          expect(options.path, ApiEndpoints.me);
          expect(options.headers['Authorization'], 'Bearer fresh-access-token');
          return _jsonResponse({
            'id': 8,
            'email': 'user@example.com',
            'username': 'userg',
            'name': 'User G',
            'role': 'buyer',
            'chat_push_enabled': true,
            'chat_message_preview_enabled': true,
            'created_at': '2026-04-01T00:00:00Z',
          }, 200);
        },
      ]);

      final bootstrapper = SessionBootstrapper(
        authApi: AuthApi(dio),
        sessionNotifier: sessionNotifier,
      );

      await bootstrapper.restore();

      expect(sessionNotifier.state.accessToken, 'fresh-access-token');
      expect(sessionNotifier.state.refreshToken, 'persisted-refresh-token');
      expect(sessionNotifier.state.profile?.id, 8);
      expect(sessionNotifier.state.profile?.name, 'User G');
    },
  );

  test(
    'restore clears the session when the refresh token is no longer valid',
    () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'expired-access-token',
        'refresh_token': 'expired-refresh-token',
        'profile_json': jsonEncode({
          'id': 8,
          'email': 'user@example.com',
          'username': 'userg',
          'name': 'User G',
          'role': 'buyer',
          'chat_push_enabled': true,
          'chat_message_preview_enabled': true,
          'created_at': '2026-04-01T00:00:00Z',
        }),
      });
      final preferences = await SharedPreferences.getInstance();
      final sessionNotifier = SessionNotifier(preferences);
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter([
        (options, _) async {
          expect(options.path, ApiEndpoints.refresh);
          return _jsonResponse({'detail': 'Token is invalid'}, 401);
        },
      ]);

      final bootstrapper = SessionBootstrapper(
        authApi: AuthApi(dio),
        sessionNotifier: sessionNotifier,
      );

      await bootstrapper.restore();

      expect(sessionNotifier.state.accessToken, isNull);
      expect(sessionNotifier.state.refreshToken, isNull);
      expect(sessionNotifier.state.profile, isNull);
    },
  );
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

typedef _AdapterHandler =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
    );

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handlers);

  final List<_AdapterHandler> _handlers;
  int _nextHandlerIndex = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_nextHandlerIndex >= _handlers.length) {
      throw StateError(
        'No handler registered for ${options.method} ${options.path}',
      );
    }

    final handler = _handlers[_nextHandlerIndex];
    _nextHandlerIndex += 1;
    return handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}
