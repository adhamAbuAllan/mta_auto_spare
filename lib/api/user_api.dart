import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';

class UserApi {
  const UserApi(this._dio);

  final Dio _dio;

  Future<AdminDashboardSummary> getAdminDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminDashboard);
      return AdminDashboardSummary.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiPage<ApiUser>> getUsers({
    String? pageUrl,
    String? search,
    String? role,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (search?.trim().isNotEmpty == true) {
        queryParameters['search'] = search!.trim();
      }
      if (role?.trim().isNotEmpty == true) {
        queryParameters['role'] = role!.trim();
      }
      if (status?.trim().isNotEmpty == true) {
        queryParameters['status'] = status!.trim();
      }
      final response = pageUrl == null
          ? await _dio.get(ApiEndpoints.users, queryParameters: queryParameters)
          : await _dio.get(ApiConstants.resolveBackendUrl(pageUrl));
      return ApiPage<ApiUser>.fromJson(_asMap(response.data), ApiUser.fromJson);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PublicUserProfile> getUserById(int userId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.users}$userId/');
      return PublicUserProfile.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiPage<UserReportEntry>> getUserReports({
    String? pageUrl,
    int? reporterId,
    int? reportedUserId,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (reporterId != null) {
        queryParameters['reporter'] = reporterId;
      }
      if (reportedUserId != null) {
        queryParameters['reported_user'] = reportedUserId;
      }
      final normalizedStatus = status?.trim() ?? '';
      if (normalizedStatus.isNotEmpty) {
        queryParameters['status'] = normalizedStatus;
      }

      final response = pageUrl == null
          ? await _dio.get(
              ApiEndpoints.userReports,
              queryParameters: queryParameters,
            )
          : await _dio.get(ApiConstants.resolveBackendUrl(pageUrl));
      return ApiPage<UserReportEntry>.fromJson(
        _asMap(response.data),
        UserReportEntry.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<UserReportEntry> createUserReport({
    required int reportedUserId,
    required String reason,
    String? details,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.userReports,
        data: {
          'reported_user': reportedUserId,
          'reason': reason.trim(),
          'details': details?.trim() ?? '',
        },
      );
      return UserReportEntry.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<UserReportEntry> reviewUserReport({
    required int reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.userReports}$reportId/',
        data: {
          'status': status.trim(),
          'admin_notes': adminNotes?.trim() ?? '',
        },
      );
      return UserReportEntry.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiUser> blockUser({required int userId, String? reason}) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.users}$userId/block/',
        data: {'reason': reason?.trim() ?? ''},
      );
      return ApiUser.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiUser> unblockUser(int userId) async {
    try {
      final response = await _dio.post('${ApiEndpoints.users}$userId/unblock/');
      return ApiUser.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiUser> setUserRole({
    required int userId,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.users}$userId/set-role/',
        data: {'role': role.trim()},
      );
      return ApiUser.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiUser> resetUserPassword({
    required int userId,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.users}$userId/reset-password/',
        data: {'password': password},
      );
      return ApiUser.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiUser> verifyUserPhone(int userId) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.users}$userId/verify-phone/',
      );
      return ApiUser.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<MobileDevice> upsertMobileDevice(MobileDevice device) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.mobileDevices,
        data: device.toJson(),
      );
      return MobileDevice.fromJson(_asMap(response.data));
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
