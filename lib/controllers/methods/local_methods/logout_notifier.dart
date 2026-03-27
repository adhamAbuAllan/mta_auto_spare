import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../session/session_notifier.dart';
import '../../statuses/auth_state.dart';

class LogoutNotifier extends StateNotifier<AuthState> {
  LogoutNotifier(this._sessionNotifier) : super(const AuthState());

  final SessionNotifier _sessionNotifier;

  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearTokens: true,
      clearProfile: true,
      clearRegisteredUser: true,
    );

    await _sessionNotifier.clear();

    state = state.copyWith(
      isLoading: false,
      clearTokens: true,
      clearProfile: true,
      clearRegisteredUser: true,
      errorMessage: null,
    );
  }
}
