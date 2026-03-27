import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/auth_api.dart';
import '../../../session/session_notifier.dart';
import '../../statuses/auth_state.dart';

class LoginNotifier extends StateNotifier<AuthState> {
  LoginNotifier({
    required AuthApi authApi,
    required SessionNotifier sessionNotifier,
  }) : _authApi = authApi,
       _sessionNotifier = sessionNotifier,
       super(const AuthState());

  final AuthApi _authApi;
  final SessionNotifier _sessionNotifier;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearRegisteredUser: true,
    );

    try {
      final tokens = await _authApi.login(
        username: username,
        password: password,
      );
      await _sessionNotifier.saveTokens(tokens);

      final profile = await _authApi.getProfile();
      await _sessionNotifier.saveProfile(profile);

      state = state.copyWith(
        isLoading: false,
        tokens: tokens,
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
