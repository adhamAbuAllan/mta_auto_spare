import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/request_api.dart';
import '../../../models/models.dart';
import '../../statuses/request_state.dart';

class LoadRequestsNotifier extends StateNotifier<RequestState> {
  LoadRequestsNotifier(this._requestApi) : super(const RequestState());

  final RequestApi _requestApi;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final requests = await _requestApi.getAllRequests();
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

  Future<void> refreshTranslationLocale() async {
    if (state.requests.isEmpty && !state.isLoading) {
      return;
    }
    await load();
  }

  void setSegment(RequestSegment segment) {
    state = state.copyWith(segment: segment);
  }

  void setStatusFilter(int? statusId) {
    state = state.copyWith(selectedStatusId: statusId);
  }

  void prependRequest(PartRequest request) {
    state = state.copyWith(requests: [request, ...state.requests]);
  }

  void replaceRequest(PartRequest request) {
    final requestId = request.id;
    if (requestId == null) {
      return;
    }

    state = state.copyWith(
      requests: [
        for (final current in state.requests)
          if (current.id == requestId) request else current,
      ],
    );
  }

  void upsertRequest(PartRequest request) {
    final requestId = request.id;
    if (requestId == null) {
      prependRequest(request);
      return;
    }

    final existingIndex = state.requests.indexWhere(
      (current) => current.id == requestId,
    );
    if (existingIndex == -1) {
      prependRequest(request);
      return;
    }

    replaceRequest(request);
  }

  void removeRequestById(int requestId) {
    state = state.copyWith(
      requests: state.requests
          .where((request) => request.id != requestId)
          .toList(growable: false),
    );
  }
}
