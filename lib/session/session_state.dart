import '../models/models.dart';

class SessionState {
  const SessionState({this.accessToken, this.refreshToken, this.profile});

  final String? accessToken;
  final String? refreshToken;
  final MeProfile? profile;

  bool get isAuthenticated =>
      (accessToken?.isNotEmpty ?? false) && profile != null;

  SessionState copyWith({
    String? accessToken,
    String? refreshToken,
    MeProfile? profile,
    bool clearTokens = false,
    bool clearProfile = false,
  }) {
    return SessionState(
      accessToken: clearTokens ? null : accessToken ?? this.accessToken,
      refreshToken: clearTokens ? null : refreshToken ?? this.refreshToken,
      profile: clearProfile ? null : profile ?? this.profile,
    );
  }
}
