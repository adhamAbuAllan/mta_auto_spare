import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../methods/api_methods/health_notifier.dart';
import '../statuses/health_state.dart';
import 'api_provider.dart';

final healthNotifierProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
      return HealthNotifier(ref.read(systemApiProvider));
    });
