import '../../models/models.dart';

enum RequestSegment { browse, mine }

class RequestState {
  const RequestState({
    this.isLoading = false,
    this.errorMessage,
    this.segment = RequestSegment.browse,
    this.requests = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final RequestSegment segment;
  final List<PartRequest> requests;

  List<PartRequest> browseRequestsFor(int currentUserId) {
    return requests
        .where((request) => request.requester != currentUserId)
        .toList(growable: false);
  }

  List<PartRequest> myRequestsFor(int currentUserId) {
    return requests
        .where((request) => request.requester == currentUserId)
        .toList(growable: false);
  }

  RequestState copyWith({
    bool? isLoading,
    Object? errorMessage = _requestUnset,
    RequestSegment? segment,
    List<PartRequest>? requests,
  }) {
    return RequestState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _requestUnset)
          ? this.errorMessage
          : errorMessage as String?,
      segment: segment ?? this.segment,
      requests: requests ?? this.requests,
    );
  }
}

class CreateRequestState {
  const CreateRequestState({
    this.isLoadingStatuses = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.blockedMessage,
    this.statuses = const [],
    this.selectedStatusId,
    this.createdRequest,
  });

  final bool isLoadingStatuses;
  final bool isSubmitting;
  final String? errorMessage;
  final String? blockedMessage;
  final List<PartRequestStatus> statuses;
  final int? selectedStatusId;
  final PartRequest? createdRequest;

  bool get canSubmit =>
      !isLoadingStatuses &&
      !isSubmitting &&
      blockedMessage == null &&
      selectedStatusId != null;

  CreateRequestState copyWith({
    bool? isLoadingStatuses,
    bool? isSubmitting,
    Object? errorMessage = _createRequestUnset,
    Object? blockedMessage = _createRequestUnset,
    List<PartRequestStatus>? statuses,
    Object? selectedStatusId = _createRequestUnset,
    Object? createdRequest = _createRequestUnset,
  }) {
    return CreateRequestState(
      isLoadingStatuses: isLoadingStatuses ?? this.isLoadingStatuses,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _createRequestUnset)
          ? this.errorMessage
          : errorMessage as String?,
      blockedMessage: identical(blockedMessage, _createRequestUnset)
          ? this.blockedMessage
          : blockedMessage as String?,
      statuses: statuses ?? this.statuses,
      selectedStatusId: identical(selectedStatusId, _createRequestUnset)
          ? this.selectedStatusId
          : selectedStatusId as int?,
      createdRequest: identical(createdRequest, _createRequestUnset)
          ? this.createdRequest
          : createdRequest as PartRequest?,
    );
  }
}

const _requestUnset = Object();
const _createRequestUnset = Object();
