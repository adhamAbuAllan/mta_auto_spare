import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'session_state.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _profileKey = 'profile_json';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  );
});

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      return SessionNotifier(ref.read(sharedPreferencesProvider));
    });

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._preferences) : super(_restore(_preferences));

  final SharedPreferences _preferences;

  static SessionState _restore(SharedPreferences preferences) {
    final accessToken = preferences.getString(_accessTokenKey);
    final refreshToken = preferences.getString(_refreshTokenKey);
    final profileJson = preferences.getString(_profileKey);

    MeProfile? profile;
    if (profileJson != null && profileJson.isNotEmpty) {
      profile = MeProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(profileJson) as Map),
      );
    }

    return SessionState(
      accessToken: accessToken,
      refreshToken: refreshToken,
      profile: profile,
    );
  }

  Future<void> saveTokens(AuthTokenPair tokens) async {
    final nextRefreshToken = tokens.refresh.isNotEmpty
        ? tokens.refresh
        : state.refreshToken;

    await _preferences.setString(_accessTokenKey, tokens.access);
    if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
      await _preferences.setString(_refreshTokenKey, nextRefreshToken);
    }
    state = state.copyWith(
      accessToken: tokens.access,
      refreshToken: nextRefreshToken,
    );
  }

  Future<void> saveProfile(MeProfile profile) async {
    await _preferences.setString(_profileKey, jsonEncode(profile.toJson()));
    state = state.copyWith(profile: profile);
  }

  Future<void> updateSession({
    AuthTokenPair? tokens,
    MeProfile? profile,
  }) async {
    if (tokens != null) {
      await saveTokens(tokens);
    }
    if (profile != null) {
      await saveProfile(profile);
    }
  }

  Future<void> clear() async {
    await _preferences.remove(_accessTokenKey);
    await _preferences.remove(_refreshTokenKey);
    await _preferences.remove(_profileKey);
    state = const SessionState();
  }
}
