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

  Future<ApiPage<SparePart>> getSpareParts({String? pageUrl}) async {
    try {
      final response = pageUrl == null
          ? await _dio.get(ApiEndpoints.spareParts)
          : await _dio.get(pageUrl);
      return ApiPage<SparePart>.fromJson(
        _asMap(response.data),
        SparePart.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<SparePart>> getAllSpareParts() async {
    final parts = <SparePart>[];
    String? nextPageUrl;
    do {
      final page = await getSpareParts(pageUrl: nextPageUrl);
      parts.addAll(page.results);
      nextPageUrl = page.next;
    } while (nextPageUrl != null && nextPageUrl.isNotEmpty);
    return parts;
  }

  Future<SparePart> createSparePart({
    required String name,
    required String description,
    required String price,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.spareParts,
        data: {
          'name': name.trim(),
          'description': description.trim(),
          'price': price.trim(),
        },
      );
      return SparePart.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<SparePart> updateSparePart(SparePart part) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.spareParts}${part.id}/',
        data: {
          'name': part.name.trim(),
          'description': part.description.trim(),
          'price': part.price.trim(),
        },
      );
      return SparePart.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deleteSparePart(int partId) async {
    try {
      await _dio.delete('${ApiEndpoints.spareParts}$partId/');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<CarMakeOption> createCarMake(String name) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.carMakes,
        data: {'name': name.trim()},
      );
      return CarMakeOption.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<CarMakeOption> updateCarMake({
    required int makeId,
    required String name,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.carMakes}$makeId/',
        data: {'name': name.trim()},
      );
      return CarMakeOption.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deleteCarMake(int makeId) async {
    try {
      await _dio.delete('${ApiEndpoints.carMakes}$makeId/');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<CarModelOption> createCarModel({
    required int makeId,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.carModels,
        data: {'make_id': makeId, 'name': name.trim()},
      );
      return CarModelOption.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<CarModelOption> updateCarModel({
    required int modelId,
    required String name,
    required bool isActive,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.carModels}$modelId/',
        data: {'name': name.trim(), 'is_active': isActive},
      );
      return CarModelOption.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deleteCarModel(int modelId) async {
    try {
      await _dio.delete('${ApiEndpoints.carModels}$modelId/');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
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
