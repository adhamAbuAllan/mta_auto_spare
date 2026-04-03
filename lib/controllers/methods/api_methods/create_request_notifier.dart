import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/request_api.dart';
import '../../../models/models.dart';
import '../../statuses/request_state.dart';

class CreateRequestNotifier extends StateNotifier<CreateRequestState> {
  CreateRequestNotifier(this._requestApi) : super(const CreateRequestState());

  final RequestApi _requestApi;

  Future<void> loadStatuses() async {
    state = state.copyWith(
      isLoadingStatuses: true,
      errorMessage: null,
      blockedMessage: null,
      createdRequest: null,
    );

    try {
      final statuses = await _requestApi.getAllRequestStatuses();
      if (statuses.isEmpty) {
        state = state.copyWith(
          isLoadingStatuses: false,
          statuses: const [],
          selectedStatusId: null,
          blockedMessage:
              'Request creation is not available yet because no request statuses are configured on the backend.',
        );
        return;
      }

      final preferredStatus = statuses.firstWhere(
        (status) => !status.isTerminal,
        orElse: () => statuses.first,
      );

      state = state.copyWith(
        isLoadingStatuses: false,
        statuses: statuses,
        selectedStatusId: preferredStatus.id,
        blockedMessage: null,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoadingStatuses: false,
        errorMessage: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingStatuses: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> create({
    required int requesterId,
    required String title,
    required String description,
    required String? city,
    required String? minPrice,
    required String? maxPrice,
    List<RequestUploadImage> images = const [],
  }) async {
    if (!state.canSubmit || state.selectedStatusId == null) {
      state = state.copyWith(
        errorMessage:
            state.blockedMessage ??
            'Request creation is currently unavailable.',
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      createdRequest: null,
    );

    try {
      final request = await _requestApi.createRequest(
        PartRequest(
          requester: requesterId,
          title: title.trim(),
          description: description.trim(),
          minPrice: _normalizeOptionalDecimal(minPrice),
          maxPrice: _normalizeOptionalDecimal(maxPrice),
          status: state.selectedStatusId!,
          city: _normalizeOptionalText(city),
        ),
        images: images,
      );

      state = state.copyWith(
        isSubmitting: false,
        createdRequest: request,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clearCreatedRequest() {
    state = state.copyWith(createdRequest: null);
  }

  String? _normalizeOptionalText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  String? _normalizeOptionalDecimal(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
