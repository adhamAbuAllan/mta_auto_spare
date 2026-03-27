import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import '../session/session_notifier.dart';

class AppDioClient {
  AppDioClient(this.ref);

  final Ref ref;
  Future<AuthTokenPair?>? _refreshFuture;

  Dio build() {
    final dio = Dio(_baseOptions());

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final skipAuth = options.extra['skipAuth'] == true;
          final session = ref.read(sessionNotifierProvider);
          final token = session.accessToken;
          if (!skipAuth && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (!_shouldAttemptRefresh(error)) {
            handler.next(error);
            return;
          }

          final refreshToken = ref.read(sessionNotifierProvider).refreshToken;
          if (refreshToken == null || refreshToken.isEmpty) {
            handler.next(error);
            return;
          }

          try {
            final future = _refreshFuture ?? _refreshAccessToken(refreshToken);
            _refreshFuture = future;
            final tokens = await future;
            _refreshFuture = null;

            if (tokens == null || tokens.access.isEmpty) {
              await ref.read(sessionNotifierProvider.notifier).clear();
              handler.next(error);
              return;
            }

            await ref.read(sessionNotifierProvider.notifier).saveTokens(tokens);

            final requestOptions = error.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer ${tokens.access}';
            requestOptions.extra['hasRetried'] = true;

            final response = await dio.fetch(requestOptions);
            handler.resolve(response);
          } catch (_) {
            _refreshFuture = null;
            await ref.read(sessionNotifierProvider.notifier).clear();
            handler.next(error);
          }
        },
      ),
    );

    return dio;
  }

  BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: const {
        'Accept': ApiConstants.acceptHeader,
        ApiConstants.ngrokHeaderKey: ApiConstants.ngrokHeaderValue,
      },
    );
  }

  bool _shouldAttemptRefresh(DioException error) {
    if (error.response?.statusCode != 401) {
      return false;
    }

    final requestOptions = error.requestOptions;
    if (requestOptions.extra['hasRetried'] == true ||
        requestOptions.extra['skipRefresh'] == true) {
      return false;
    }

    final path = requestOptions.path;
    if (path.endsWith(ApiEndpoints.login) ||
        path.endsWith(ApiEndpoints.refresh)) {
      return false;
    }

    return true;
  }

  Future<AuthTokenPair?> _refreshAccessToken(String refreshToken) async {
    final refreshDio = Dio(_baseOptions());
    final response = await refreshDio.post(
      ApiEndpoints.refresh,
      data: {'refresh': refreshToken},
    );

    final data = response.data;
    if (data is! Map) {
      return null;
    }

    final payload = Map<String, dynamic>.from(data);
    return AuthTokenPair(
      refresh: payload['refresh']?.toString().trim().isNotEmpty == true
          ? payload['refresh'].toString()
          : refreshToken,
      access: payload['access']?.toString() ?? '',
    );
  }
}
