import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokenPair> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );
      return AuthTokenPair.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AuthTokenPair> refresh({required String refreshToken}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refresh': refreshToken},
        options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
      );
      final payload = _asMap(response.data);
      return AuthTokenPair(
        refresh: payload['refresh']?.toString().trim().isNotEmpty == true
            ? payload['refresh'].toString()
            : refreshToken,
        access: payload['access']?.toString() ?? '',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiUser> register(ApiUser user) async {
    try {
      final response = await _dio.post(ApiEndpoints.users, data: user.toJson());
      return ApiUser.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<MeProfile> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      return MeProfile.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<MeProfile> updateProfile({
    required String name,
    required String? phone,
    required String? city,
    required bool chatPushEnabled,
    required bool chatMessagePreviewEnabled,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.me,
        data: {
          'name': name.trim(),
          'phone': phone?.trim() ?? '',
          'city': city?.trim() ?? '',
          'chat_push_enabled': chatPushEnabled,
          'chat_message_preview_enabled': chatMessagePreviewEnabled,
        },
      );
      return MeProfile.fromJson(_asMap(response.data));
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
