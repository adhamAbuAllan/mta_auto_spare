import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/auth_api.dart';
import '../../../session/session_notifier.dart';
import '../../statuses/auth_state.dart';

class RegisterNotifier extends StateNotifier<AuthState> {
  RegisterNotifier({
    required AuthApi authApi,
    required SessionNotifier sessionNotifier,
  }) : _authApi = authApi,
       _sessionNotifier = sessionNotifier,
       super(const AuthState());

  final AuthApi _authApi;
  final SessionNotifier _sessionNotifier;

  void reset() {
    state = const AuthState();
  }

  Future<bool> registerVerifiedPhone({
    required String firebaseIdToken,
    required String phone,
    required String name,
    required String password,
    String role = 'user',
    String? city,
    List<int>? supportedCarModelIds,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearRegisteredUser: true,
    );

    try {
      final authenticatedSession = await _authApi.registerVerifiedPhone(
        firebaseIdToken: firebaseIdToken,
        phone: phone,
        password: password,
        name: name,
        role: role,
        city: city,
        supportedCarModelIds: supportedCarModelIds,
      );
      await _sessionNotifier.updateSession(
        tokens: authenticatedSession.tokens,
        profile: authenticatedSession.profile,
      );

      state = state.copyWith(
        isLoading: false,
        tokens: authenticatedSession.tokens,
        profile: authenticatedSession.profile,
        errorMessage: null,
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }
}
