import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mta_auto_spare/models/models.dart';
import 'package:mta_auto_spare/session/session_notifier.dart';

void main() {
  test(
    'saveTokens preserves the stored refresh token when the new one is empty',
    () async {
      SharedPreferences.setMockInitialValues({
        'refresh_token': 'persisted-refresh-token',
      });
      final preferences = await SharedPreferences.getInstance();
      final notifier = SessionNotifier(preferences);

      await notifier.saveTokens(
        const AuthTokenPair(refresh: '', access: 'new-access-token'),
      );

      expect(notifier.state.accessToken, 'new-access-token');
      expect(notifier.state.refreshToken, 'persisted-refresh-token');
      expect(preferences.getString('refresh_token'), 'persisted-refresh-token');
    },
  );
}
