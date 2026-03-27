import '../../models/models.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.tokens,
    this.profile,
    this.registeredUser,
  });

  final bool isLoading;
  final String? errorMessage;
  final AuthTokenPair? tokens;
  final MeProfile? profile;
  final ApiUser? registeredUser;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  AuthState copyWith({
    bool? isLoading,
    Object? errorMessage = _authUnset,
    AuthTokenPair? tokens,
    MeProfile? profile,
    ApiUser? registeredUser,
    bool clearTokens = false,
    bool clearProfile = false,
    bool clearRegisteredUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _authUnset)
          ? this.errorMessage
          : errorMessage as String?,
      tokens: clearTokens ? null : tokens ?? this.tokens,
      profile: clearProfile ? null : profile ?? this.profile,
      registeredUser: clearRegisteredUser
          ? null
          : registeredUser ?? this.registeredUser,
    );
  }
}

const _authUnset = Object();
