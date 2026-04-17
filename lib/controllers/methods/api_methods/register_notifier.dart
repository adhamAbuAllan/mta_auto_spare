import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/auth_api.dart';
import '../../../models/models.dart';
import '../../statuses/auth_state.dart';

class RegisterNotifier extends StateNotifier<AuthState> {
  RegisterNotifier(this._authApi) : super(const AuthState());

  final AuthApi _authApi;

  void reset() {
    state = const AuthState();
  }

  Future<void> register({
    required String email,
    required String username,
    required String name,
    required String password,
    String role = 'user',
    List<int>? supportedCarModelIds,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearRegisteredUser: true,
    );

    try {
      final user = await _authApi.register(
        ApiUser(
          email: email,
          username: username,
          name: name,
          role: role,
          password: password,
          supportedCarModelIds: supportedCarModelIds,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        registeredUser: user,
        errorMessage: null,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
