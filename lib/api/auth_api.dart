import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';
import 'dio_client.dart';

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokenPair> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
        options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
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

  Future<AuthenticatedSession> registerVerifiedPhone({
    required String firebaseIdToken,
    required String phone,
    required String password,
    required String name,
    required String role,
    String? city,
    List<int>? supportedCarModelIds,
  }) async {
    try {
      final payload = <String, dynamic>{
        'firebase_id_token': firebaseIdToken,
        'phone': phone.trim(),
        'password': password,
        'name': name.trim(),
        'role': role,
      };
      final normalizedCity = city?.trim() ?? '';
      if (normalizedCity.isNotEmpty) {
        payload['city'] = normalizedCity;
      }
      if (supportedCarModelIds != null) {
        payload['supported_car_model_ids'] = supportedCarModelIds;
      }
      final response = await _dio.post(
        ApiEndpoints.register,
        data: payload,
        options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
      );
      return AuthenticatedSession.fromJson(_asMap(response.data));
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
    List<int>? supportedCarModelIds,
    RequestUploadImage? avatarImage,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'phone': phone?.trim() ?? '',
        'city': city?.trim() ?? '',
        'chat_push_enabled': chatPushEnabled,
        'chat_message_preview_enabled': chatMessagePreviewEnabled,
      };
      if (supportedCarModelIds != null) {
        payload['supported_car_model_ids'] = supportedCarModelIds;
      }
      final shouldUseMultipart = avatarImage != null;

      Future<FormData> buildRetryData() async {
        final formData = <String, dynamic>{
          'name': name.trim(),
          'phone': phone?.trim() ?? '',
          'city': city?.trim() ?? '',
          'chat_push_enabled': chatPushEnabled.toString(),
          'chat_message_preview_enabled': chatMessagePreviewEnabled.toString(),
        };
        if (supportedCarModelIds != null) {
          formData['supported_car_model_ids'] = supportedCarModelIds
              .map((item) => item.toString())
              .toList(growable: false);
        }
        if (avatarImage != null) {
          formData['avatar'] = await MultipartFile.fromFile(
            avatarImage.path,
            filename: avatarImage.fileName,
            contentType: MediaType.parse(avatarImage.contentType),
          );
        }
        return FormData.fromMap(formData);
      }

      final response = await _dio.patch(
        ApiEndpoints.me,
        data: shouldUseMultipart ? await buildRetryData() : payload,
        options: shouldUseMultipart
            ? Options(
                sendTimeout: ApiConstants.requestUploadSendTimeout,
                extra: {AppDioClient.retryDataBuilderExtraKey: buildRetryData},
              )
            : null,
      );
      return MeProfile.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete(ApiEndpoints.me);
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
