import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import '../session/session_notifier.dart';

typedef RetryRequestDataBuilder = FutureOr<dynamic> Function();

class AppDioClient {
  AppDioClient(this.ref);

  static const String retryDataBuilderExtraKey = 'retryDataBuilder';

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
            final tokens = await _refreshTokens(
              refreshToken,
              httpClientAdapter: dio.httpClientAdapter,
            );

            if (tokens == null || tokens.access.isEmpty) {
              await ref.read(sessionNotifierProvider.notifier).clear();
              handler.next(error);
              return;
            }

            await ref.read(sessionNotifierProvider.notifier).saveTokens(tokens);
            try {
              final response = await _retryRequest(
                dio: dio,
                requestOptions: error.requestOptions,
                accessToken: tokens.access,
              );
              handler.resolve(response);
            } on DioException catch (retryError) {
              if (_shouldClearSessionAfterRetryFailure(retryError)) {
                await ref.read(sessionNotifierProvider.notifier).clear();
              }
              handler.next(retryError);
            } catch (retryError, stackTrace) {
              handler.next(
                DioException(
                  requestOptions: error.requestOptions,
                  error: retryError,
                  stackTrace: stackTrace,
                ),
              );
            }
          } on DioException catch (refreshError) {
            if (_shouldClearSessionAfterRefreshFailure(refreshError)) {
              await ref.read(sessionNotifierProvider.notifier).clear();
            }
            handler.next(error);
          } catch (_) {
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

  Future<AuthTokenPair?> _refreshTokens(
    String refreshToken, {
    required HttpClientAdapter httpClientAdapter,
  }) async {
    final activeRefresh =
        _refreshFuture ??
        _refreshAccessToken(refreshToken, httpClientAdapter: httpClientAdapter);
    _refreshFuture = activeRefresh;
    try {
      return await activeRefresh;
    } finally {
      if (identical(_refreshFuture, activeRefresh)) {
        _refreshFuture = null;
      }
    }
  }

  Future<Response<dynamic>> _retryRequest({
    required Dio dio,
    required RequestOptions requestOptions,
    required String accessToken,
  }) async {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    final extra = Map<String, dynamic>.from(requestOptions.extra);
    extra['hasRetried'] = true;

    final retryData = await _buildRetryData(requestOptions);
    final retryOptions = requestOptions.copyWith(
      data: retryData,
      headers: headers,
      extra: extra,
    );
    return dio.fetch<dynamic>(retryOptions);
  }

  Future<dynamic> _buildRetryData(RequestOptions requestOptions) async {
    final builder = requestOptions.extra[retryDataBuilderExtraKey];
    if (builder is RetryRequestDataBuilder) {
      return await Future<dynamic>.value(builder());
    }
    return requestOptions.data;
  }

  bool _shouldClearSessionAfterRefreshFailure(DioException error) {
    return switch (error.response?.statusCode) {
      400 || 401 || 403 => true,
      _ => false,
    };
  }

  bool _shouldClearSessionAfterRetryFailure(DioException error) {
    return error.response?.statusCode == 401;
  }

  Future<AuthTokenPair?> _refreshAccessToken(
    String refreshToken, {
    required HttpClientAdapter httpClientAdapter,
  }) async {
    final refreshDio = Dio(_baseOptions());
    refreshDio.httpClientAdapter = httpClientAdapter;
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
