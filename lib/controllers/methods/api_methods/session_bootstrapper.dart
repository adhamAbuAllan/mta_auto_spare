import '../../../api/api_exception.dart';
import '../../../api/auth_api.dart';
import '../../../session/session_notifier.dart';

class SessionBootstrapper {
  SessionBootstrapper({
    required AuthApi authApi,
    required SessionNotifier sessionNotifier,
  }) : _authApi = authApi,
       _sessionNotifier = sessionNotifier;

  final AuthApi _authApi;
  final SessionNotifier _sessionNotifier;

  Future<void> restore() async {
    final initialSession = _sessionNotifier.currentState;
    final refreshToken = initialSession.refreshToken?.trim() ?? '';
    final accessToken = initialSession.accessToken?.trim() ?? '';
    final hasRefreshToken = refreshToken.isNotEmpty;
    final hasAccessToken = accessToken.isNotEmpty;
    final hasProfile = initialSession.profile != null;

    if (!hasRefreshToken && !hasAccessToken) {
      return;
    }

    if (hasRefreshToken) {
      final refreshed = await _refreshSession(refreshToken);
      if (!refreshed) {
        return;
      }
    }

    if (hasRefreshToken || !hasProfile) {
      await _loadProfile();
    }
  }

  Future<bool> _refreshSession(String refreshToken) async {
    try {
      final refreshedTokens = await _authApi.refresh(
        refreshToken: refreshToken,
      );
      await _sessionNotifier.saveTokens(refreshedTokens);
      return true;
    } on ApiException catch (error) {
      if (_isAuthenticationFailure(error.statusCode)) {
        await _sessionNotifier.clear();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authApi.getProfile();
      await _sessionNotifier.saveProfile(profile);
    } on ApiException catch (error) {
      if (_isAuthenticationFailure(error.statusCode)) {
        await _sessionNotifier.clear();
      }
    } catch (_) {
      // Keep the last cached session on transient startup failures.
    }
  }

  bool _isAuthenticationFailure(int? statusCode) {
    return switch (statusCode) {
      400 || 401 || 403 => true,
      _ => false,
    };
  }
}
