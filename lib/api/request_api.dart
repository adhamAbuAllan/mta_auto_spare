import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'api_exception.dart';
import 'dio_client.dart';

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

  Future<PartRequest> getRequestById(int requestId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.partRequests}$requestId/',
      );
      return PartRequest.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<PartRequestAccess>> getRequestAccesses({
    required int partRequestId,
    int? conversationId,
  }) async {
    final accesses = <PartRequestAccess>[];
    String? nextPageUrl;
    final queryParameters = <String, dynamic>{'part_request': partRequestId};
    if (conversationId != null) {
      queryParameters['conversation'] = conversationId;
    }

    do {
      try {
        final response = nextPageUrl == null
            ? await _dio.get(
                ApiEndpoints.partRequestAccesses,
                queryParameters: queryParameters,
              )
            : await _dio.get(nextPageUrl);
        final page = ApiPage<PartRequestAccess>.fromJson(
          _asMap(response.data),
          PartRequestAccess.fromJson,
        );
        accesses.addAll(page.results);
        nextPageUrl = page.next;
      } on DioException catch (error) {
        throw ApiException.fromDioException(error);
      }
    } while (nextPageUrl != null && nextPageUrl.isNotEmpty);

    return accesses;
  }

  Future<PartRequestAccess> requestManagementAccess({
    required int partRequestId,
    required int conversationId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.partRequestAccesses,
        data: {'part_request': partRequestId, 'conversation': conversationId},
      );
      return PartRequestAccess.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PartRequestAccess> approveRequestAccess(int accessId) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.partRequestAccesses}$accessId/approve/',
      );
      return PartRequestAccess.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PartRequestAccess> rejectRequestAccess(int accessId) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.partRequestAccesses}$accessId/reject/',
      );
      return PartRequestAccess.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PartRequest> updateRequestStatus({
    required int requestId,
    required int statusId,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.partRequests}$requestId/',
        data: {'status': statusId},
      );
      return PartRequest.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PartRequest> createRequest(
    PartRequest request, {
    List<RequestUploadImage> images = const [],
  }) async {
    try {
      Future<FormData> buildRetryData() {
        return _buildMultipartPayload(request, images: images);
      }

      final shouldUseMultipart = images.isNotEmpty;
      final payload = shouldUseMultipart
          ? await buildRetryData()
          : _buildJsonPayload(request);
      final response = await _dio.post(
        ApiEndpoints.partRequests,
        data: payload,
        options: shouldUseMultipart
            ? Options(
                sendTimeout: ApiConstants.requestUploadSendTimeout,
                extra: {AppDioClient.retryDataBuilderExtraKey: buildRetryData},
              )
            : null,
      );
      return PartRequest.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PartRequest> updateRequest(
    PartRequest request, {
    required List<int> keepImageIds,
    List<RequestUploadImage> newImages = const [],
  }) async {
    final requestId = request.id;
    if (requestId == null) {
      throw ApiException('Request id is required for updates.');
    }

    try {
      Future<FormData> buildRetryData() => _buildMultipartPayload(
        request,
        images: newImages,
        keepImageIds: keepImageIds,
        syncImages: true,
      );
      final response = await _dio.patch(
        '${ApiEndpoints.partRequests}$requestId/',
        data: await buildRetryData(),
        options: Options(
          sendTimeout: ApiConstants.requestUploadSendTimeout,
          extra: {AppDioClient.retryDataBuilderExtraKey: buildRetryData},
        ),
      );
      return PartRequest.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deleteRequest(int requestId) async {
    try {
      await _dio.delete('${ApiEndpoints.partRequests}$requestId/');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<FormData> _buildMultipartPayload(
    PartRequest request, {
    List<RequestUploadImage> images = const [],
    List<int> keepImageIds = const [],
    bool syncImages = false,
  }) async {
    final data = <String, dynamic>{
      'requester': request.requester.toString(),
      'title': request.title,
      'description': request.description,
      'status': request.status.toString(),
    };
    final carModelId = request.carModelId;
    if (carModelId != null || syncImages) {
      data['car_model'] = carModelId?.toString() ?? '';
    }
    if (images.isNotEmpty) {
      data['images'] = await Future.wait(
        images.map(
          (image) => MultipartFile.fromFile(
            image.path,
            filename: image.fileName,
            contentType: MediaType.parse(image.contentType),
          ),
        ),
      );
    }
    if (syncImages) {
      data['sync_images'] = 'true';
      data['keep_image_ids'] = keepImageIds
          .map((id) => id.toString())
          .toList(growable: false);
    }
    final minPrice = request.minPrice?.trim() ?? '';
    final maxPrice = request.maxPrice?.trim() ?? '';
    final city = request.city?.trim() ?? '';
    if (minPrice.isNotEmpty || syncImages) {
      data['min_price'] = minPrice;
    }
    if (maxPrice.isNotEmpty || syncImages) {
      data['max_price'] = maxPrice;
    }
    if (city.isNotEmpty || syncImages) {
      data['city'] = city;
    }
    return FormData.fromMap(data);
  }

  Map<String, dynamic> _buildJsonPayload(PartRequest request) {
    final data = <String, dynamic>{
      'requester': request.requester,
      'title': request.title,
      'description': request.description,
      'status': request.status,
    };
    if (request.carModelId != null) {
      data['car_model'] = request.carModelId;
    }
    final minPrice = request.minPrice?.trim() ?? '';
    final maxPrice = request.maxPrice?.trim() ?? '';
    final city = request.city?.trim() ?? '';
    if (minPrice.isNotEmpty) {
      data['min_price'] = minPrice;
    }
    if (maxPrice.isNotEmpty) {
      data['max_price'] = maxPrice;
    }
    data['city'] = city.isEmpty ? null : city;
    return data;
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
