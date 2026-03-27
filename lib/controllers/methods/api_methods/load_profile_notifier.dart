import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/auth_api.dart';
import '../../../session/session_notifier.dart';
import '../../statuses/auth_state.dart';

class LoadProfileNotifier extends StateNotifier<AuthState> {
  LoadProfileNotifier({
    required AuthApi authApi,
    required SessionNotifier sessionNotifier,
  }) : _authApi = authApi,
       _sessionNotifier = sessionNotifier,
       super(const AuthState());

  final AuthApi _authApi;
  final SessionNotifier _sessionNotifier;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = await _authApi.getProfile();
      await _sessionNotifier.saveProfile(profile);
      state = state.copyWith(
        isLoading: false,
        profile: profile,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
