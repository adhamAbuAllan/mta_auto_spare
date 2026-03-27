import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../session/session_notifier.dart';
import '../../statuses/auth_state.dart';

class LogoutNotifier extends StateNotifier<AuthState> {
  LogoutNotifier(this._sessionNotifier, {required this.onLogout})
    : super(const AuthState());

  final SessionNotifier _sessionNotifier;
  final Future<void> Function() onLogout;

  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearTokens: true,
      clearProfile: true,
      clearRegisteredUser: true,
    );

    await _sessionNotifier.clear();
    await onLogout();

    state = state.copyWith(
      isLoading: false,
      clearTokens: true,
      clearProfile: true,
      clearRegisteredUser: true,
      errorMessage: null,
    );
  }
}
