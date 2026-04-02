import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../session/session_notifier.dart';
import '../../statuses/auth_state.dart';

class LogoutNotifier extends StateNotifier<AuthState> {
  LogoutNotifier(
    this._sessionNotifier, {
    required this.beforeLogout,
    required this.onLogout,
  }) : super(const AuthState());

  final SessionNotifier _sessionNotifier;
  final Future<void> Function() beforeLogout;
  final Future<void> Function() onLogout;

  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearTokens: true,
      clearProfile: true,
      clearRegisteredUser: true,
    );

    try {
      await beforeLogout();
    } catch (_) {}

    await _sessionNotifier.clear();

    try {
      await onLogout();
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      clearTokens: true,
      clearProfile: true,
      clearRegisteredUser: true,
      errorMessage: null,
    );
  }
}
