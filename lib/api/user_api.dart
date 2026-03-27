import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';

class UserApi {
  const UserApi(this._dio);

  final Dio _dio;

  Future<ApiPage<ApiUser>> getUsers({String? pageUrl}) async {
    try {
      final response = pageUrl == null
          ? await _dio.get(ApiEndpoints.users)
          : await _dio.get(pageUrl);
      return ApiPage<ApiUser>.fromJson(_asMap(response.data), ApiUser.fromJson);
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
