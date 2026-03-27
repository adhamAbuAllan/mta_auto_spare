import '../../models/models.dart';

class HealthState {
  const HealthState({
    this.isLoading = false,
    this.errorMessage,
    this.healthStatus,
  });

  final bool isLoading;
  final String? errorMessage;
  final HealthStatus? healthStatus;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  HealthState copyWith({
    bool? isLoading,
    Object? errorMessage = _healthUnset,
    HealthStatus? healthStatus,
  }) {
    return HealthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _healthUnset)
          ? this.errorMessage
          : errorMessage as String?,
      healthStatus: healthStatus ?? this.healthStatus,
    );
  }
}

const _healthUnset = Object();
