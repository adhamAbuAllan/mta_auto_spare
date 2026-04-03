import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';

class RequestApi {
  const RequestApi(this._dio);

  final Dio _dio;

  Future<ApiPage<PartRequest>> getRequests({String? pageUrl}) async {
    try {
      final response = pageUrl == null
          ? await _dio.get(ApiEndpoints.partRequests)
          : await _dio.get(pageUrl);
      return ApiPage<PartRequest>.fromJson(
        _asMap(response.data),
        PartRequest.fromJson,
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<PartRequest>> getAllRequests() async {
    final requests = <PartRequest>[];
    String? nextPageUrl;

    do {
      final page = await getRequests(pageUrl: nextPageUrl);
      requests.addAll(page.results);
      nextPageUrl = page.next;
    } while (nextPageUrl != null && nextPageUrl.isNotEmpty);

    return requests;
  }

  Future<List<PartRequestStatus>> getAllRequestStatuses() async {
    final statuses = <PartRequestStatus>[];
    String? nextPageUrl;

    do {
      try {
        final response = nextPageUrl == null
            ? await _dio.get(ApiEndpoints.partRequestStatuses)
            : await _dio.get(nextPageUrl);
        final page = ApiPage<PartRequestStatus>.fromJson(
          _asMap(response.data),
          PartRequestStatus.fromJson,
        );
        statuses.addAll(page.results);
        nextPageUrl = page.next;
      } on DioException catch (error) {
        throw ApiException.fromDioException(error);
      }
    } while (nextPageUrl != null && nextPageUrl.isNotEmpty);

    return statuses;
  }

  Future<PartRequest> createRequest(
    PartRequest request, {
    List<RequestUploadImage> images = const [],
  }) async {
    try {
      final payload = images.isEmpty
          ? request.toJson()
          : await _buildMultipartPayload(request, images);
      final response = await _dio.post(
        ApiEndpoints.partRequests,
        data: payload,
      );
      return PartRequest.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<FormData> _buildMultipartPayload(
    PartRequest request,
    List<RequestUploadImage> images,
  ) async {
    final data = <String, dynamic>{
      'requester': request.requester.toString(),
      'title': request.title,
      'description': request.description,
      'status': request.status.toString(),
      'images': await Future.wait(
        images.map(
          (image) => MultipartFile.fromFile(
            image.path,
            filename: image.fileName,
            contentType: MediaType.parse(image.contentType),
          ),
        ),
      ),
    };
    if (request.minPrice != null && request.minPrice!.trim().isNotEmpty) {
      data['min_price'] = request.minPrice!.trim();
    }
    if (request.maxPrice != null && request.maxPrice!.trim().isNotEmpty) {
      data['max_price'] = request.maxPrice!.trim();
    }
    if (request.city != null && request.city!.trim().isNotEmpty) {
      data['city'] = request.city!.trim();
    }
    return FormData.fromMap(data);
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
