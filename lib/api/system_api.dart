import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';

class SystemApi {
  const SystemApi(this._dio);

  final Dio _dio;

  Future<HealthStatus> health() async {
    try {
      final response = await _dio.get(ApiEndpoints.health);
      return HealthStatus.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<AppUpdateInfo> appUpdate({
    required String platform,
    required String version,
    required String buildNumber,
    required String packageName,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.appUpdate,
        queryParameters: {
          'platform': platform,
          'version': version,
          'build': buildNumber,
          'package': packageName,
        },
      );
      return AppUpdateInfo.fromJson(_asMap(response.data));
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
