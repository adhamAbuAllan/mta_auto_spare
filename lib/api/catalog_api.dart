import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';

class CatalogApi {
  const CatalogApi(this._dio);

  final Dio _dio;

  Future<ApiPage<CarMakeOption>> getCarMakes({String? pageUrl}) async {
    try {
      final response = pageUrl == null
          ? await _dio.get(ApiEndpoints.carMakes)
          : await _dio.get(pageUrl);
      return ApiPage<CarMakeOption>.fromJson(
        _asMap(response.data),
        CarMakeOption.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<CarMakeOption>> getAllCarMakes() async {
    final makes = <CarMakeOption>[];
    String? nextPageUrl;

    do {
      final page = await getCarMakes(pageUrl: nextPageUrl);
      makes.addAll(page.results);
      nextPageUrl = page.next;
    } while (nextPageUrl != null && nextPageUrl.isNotEmpty);

    return makes;
  }

  Future<List<CarModelOption>> searchCarModels({
    required String query,
    int? makeId,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    try {
      final queryParameters = <String, dynamic>{'search': normalizedQuery};
      if (makeId != null) {
        queryParameters['make_id'] = makeId;
      }
      final response = await _dio.get(
        ApiEndpoints.carModels,
        queryParameters: queryParameters,
      );
      final page = ApiPage<CarModelOption>.fromJson(
        _asMap(response.data),
        CarModelOption.fromJson,
      );
      return page.results;
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
