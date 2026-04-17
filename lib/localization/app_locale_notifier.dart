import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../session/session_notifier.dart';
import 'app_locale.dart';

final appLocaleProvider =
    StateNotifierProvider<AppLocaleNotifier, AppLocaleMode>((ref) {
      return AppLocaleNotifier(ref.read(sharedPreferencesProvider));
    });

final materialAppLocaleProvider = Provider<Locale?>((ref) {
  final mode = ref.watch(appLocaleProvider);
  return mode.locale;
});

class AppLocaleNotifier extends StateNotifier<AppLocaleMode> {
  AppLocaleNotifier(this._preferences)
    : super(
        AppLocaleMode.fromStorage(
          _preferences.getString(appLocalePreferenceKey),
        ),
      );

  final SharedPreferences _preferences;

  Future<void> setMode(AppLocaleMode mode) async {
    if (state == mode) {
      return;
    }
    await _preferences.setString(appLocalePreferenceKey, mode.storageValue);
    state = mode;
  }
}
