import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mta_auto_spare/api/api_exception.dart';
import 'package:mta_auto_spare/api/chat_api.dart';
import 'package:mta_auto_spare/constants/api_constants.dart';
import 'package:mta_auto_spare/controllers/providers/api_provider.dart';
import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/session/session_notifier.dart';

void main() {
  test(
    'chat send refreshes the access token and retries without clearing the session',
    () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      final adapter = _FakeHttpClientAdapter([
        (options, _) async {
          expect(options.path, ApiEndpoints.messages);
          expect(
            options.headers['Authorization'],
            'Bearer expired-access-token',
          );
          expect(options.headers['Accept-Language'], 'en');
          return _jsonResponse({'detail': 'Unauthorized'}, 401);
        },
        (options, _) async {
          expect(options.path, ApiEndpoints.refresh);
          return _jsonResponse({'access': 'fresh-access-token'}, 200);
        },
        (options, _) async {
          expect(options.path, ApiEndpoints.messages);
          expect(options.headers['Authorization'], 'Bearer fresh-access-token');
          expect(options.headers['Accept-Language'], 'en');
          return _jsonResponse(_messagePayload(), 201);
        },
      ]);
      dio.httpClientAdapter = adapter;

      final api = ChatApi(dio);
      final message = await api.createMessage(_textMessageRequest());

      expect(message.id, 91);
      expect(adapter.requestPaths, [
        ApiEndpoints.messages,
        ApiEndpoints.refresh,
        ApiEndpoints.messages,
      ]);

      final session = container.read(sessionNotifierProvider);
      expect(session.accessToken, 'fresh-access-token');
      expect(session.refreshToken, 'persisted-refresh-token');
    },
  );

  test(
    'replay failures after a successful refresh keep the user logged in',
    () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      dio.httpClientAdapter = _FakeHttpClientAdapter([
        (options, _) async {
          expect(options.path, ApiEndpoints.messages);
          expect(options.headers['Accept-Language'], 'en');
          return _jsonResponse({'detail': 'Unauthorized'}, 401);
        },
        (options, _) async {
          expect(options.path, ApiEndpoints.refresh);
          return _jsonResponse({'access': 'fresh-access-token'}, 200);
        },
        (options, _) async {
          expect(options.path, ApiEndpoints.messages);
          expect(options.headers['Authorization'], 'Bearer fresh-access-token');
          expect(options.headers['Accept-Language'], 'en');
          return _jsonResponse({'detail': 'Server error'}, 500);
        },
      ]);

      final api = ChatApi(dio);

      await expectLater(
        () => api.createMessage(_textMessageRequest()),
        throwsA(isA<ApiException>()),
      );

      final session = container.read(sessionNotifierProvider);
      expect(session.accessToken, 'fresh-access-token');
      expect(session.refreshToken, 'persisted-refresh-token');
    },
  );

  test(
    'multipart chat sends rebuild their payload before retrying after refresh',
    () async {
      final container = await _createContainer();
      addTearDown(container.dispose);

      final tempDirectory = await Directory.systemTemp.createTemp(
        'mta-auto-spare-dio-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          try {
            await tempDirectory.delete(recursive: true);
          } on PathAccessException {
            // Windows can keep multipart temp files locked briefly after the test.
          }
        }
      });

      final voiceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}clip.m4a',
      );
      await voiceFile.writeAsBytes(const [1, 2, 3, 4]);

      final dio = container.read(dioProvider);
      FormData? firstPayload;
      FormData? retriedPayload;
      dio.httpClientAdapter = _FakeHttpClientAdapter([
        (options, _) async {
          expect(options.path, ApiEndpoints.messages);
          expect(options.data, isA<FormData>());
          expect(options.headers['Accept-Language'], 'en');
          firstPayload = options.data as FormData;
          expect(
            firstPayload!.fields.any((field) => field.key == 'message_type'),
            isTrue,
          );
          return _jsonResponse({'detail': 'Unauthorized'}, 401);
        },
        (options, _) async {
          expect(options.path, ApiEndpoints.refresh);
          return _jsonResponse({'access': 'fresh-access-token'}, 200);
        },
        (options, _) async {
          expect(options.path, ApiEndpoints.messages);
          expect(options.data, isA<FormData>());
          expect(options.headers['Accept-Language'], 'en');
          retriedPayload = options.data as FormData;
          expect(identical(retriedPayload, firstPayload), isFalse);
          expect(
            retriedPayload!.fields.any((field) => field.key == 'message_type'),
            isTrue,
          );
          return _jsonResponse(
            _messagePayload(
              messageType: 'media',
              media: [
                {
                  'id': 7,
                  'file_url':
                      'https://polishedly-bouncy-jerry.ngrok-free.dev/media/voice/clip.m4a',
                  'content_type': 'audio/mp4',
                  'size': 4,
                },
              ],
            ),
            201,
          );
        },
      ]);

      final api = ChatApi(dio);
      final message = await api.createMessage(
        MessageCreateRequest(
          conversation: 2,
          messageType: 'media',
          clientTimestamp: DateTime.parse('2026-03-30T21:51:18Z'),
          attachments: [
            ChatUploadImage(
              path: voiceFile.path,
              fileName: 'clip.m4a',
              contentType: 'audio/mp4',
              size: 4,
            ),
          ],
        ),
      );

      expect(message.messageType, 'media');
      expect(message.media, isNotEmpty);
    },
  );
}

Future<ProviderContainer> _createContainer() async {
  SharedPreferences.setMockInitialValues({
    'access_token': 'expired-access-token',
    'refresh_token': 'persisted-refresh-token',
    'app_locale_mode': 'en',
  });
  final preferences = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWith((ref) => preferences)],
  );
}

MessageCreateRequest _textMessageRequest() {
  return MessageCreateRequest(
    conversation: 2,
    messageType: 'text',
    text: 'Hello',
    clientTimestamp: DateTime.parse('2026-03-30T21:51:18Z'),
  );
}

Map<String, dynamic> _messagePayload({
  int id = 91,
  String messageType = 'text',
  List<Map<String, dynamic>> media = const [],
}) {
  return {
    'id': id,
    'conversation_id': 2,
    'sender': {'id': 1, 'name': 'Needf'},
    'message_type': messageType,
    'text': messageType == 'text' ? 'Hello' : '',
    'media': media,
    'statuses': const [],
    'client_timestamp': '2026-03-30T21:51:18Z',
    'server_timestamp': '2026-03-30T21:51:19Z',
  };
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
  final List<String> requestPaths = <String>[];
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

    requestPaths.add(options.path);
    final handler = _handlers[_nextHandlerIndex];
    _nextHandlerIndex += 1;
    return handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}
