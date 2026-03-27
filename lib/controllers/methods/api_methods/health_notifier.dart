import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/system_api.dart';
import '../../../controllers/statuses/health_state.dart';
import '../../../api/api_exception.dart';

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier(this._systemApi) : super(const HealthState());

  final SystemApi _systemApi;

  Future<void> check() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final health = await _systemApi.health();
      state = state.copyWith(
        isLoading: false,
        healthStatus: health,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
