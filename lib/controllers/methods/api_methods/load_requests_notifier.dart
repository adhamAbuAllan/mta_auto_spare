import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/request_api.dart';
import '../../../constants/api_constants.dart';
import '../../../models/models.dart';
import '../../statuses/request_state.dart';

class LoadRequestsNotifier extends StateNotifier<RequestState> {
  LoadRequestsNotifier(this._requestApi) : super(const RequestState());

  final RequestApi _requestApi;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final requests = await _requestApi.getAllRequests();
      _logLoadedRequestImages(requests);
      state = state.copyWith(
        isLoading: false,
        requests: requests,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void setSegment(RequestSegment segment) {
    state = state.copyWith(segment: segment);
  }

  void prependRequest(PartRequest request) {
    state = state.copyWith(requests: [request, ...state.requests]);
  }

  void _logLoadedRequestImages(List<PartRequest> requests) {
    if (requests.isEmpty) {
      debugPrint('[Requests][Images] No requests were loaded.');
      return;
    }

    for (final request in requests) {
      if (request.images.isEmpty) {
        debugPrint(
          '[Requests][Images] Request #${request.id ?? 0} '
          '"${request.title}" has no images.',
        );
        continue;
      }

      for (final image in request.images) {
        final rawUrl = image.image.trim();
        final resolvedUrl = ApiConstants.resolveUrl(rawUrl);
        debugPrint(
          '[Requests][Images] Request #${request.id ?? 0} '
          '"${request.title}" image: raw="$rawUrl" resolved="$resolvedUrl"',
        );
      }
    }
  }
}
