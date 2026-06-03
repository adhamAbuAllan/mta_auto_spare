import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../methods/api_methods/health_notifier.dart';
import '../statuses/health_state.dart';
import 'api_provider.dart';
import '../../notifications/app_update_service.dart';
import '../../session/session_notifier.dart';

final healthNotifierProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
      return HealthNotifier(ref.read(systemApiProvider));
    });

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(
    systemApi: ref.read(systemApiProvider),
    preferences: ref.read(sharedPreferencesProvider),
  );
});
