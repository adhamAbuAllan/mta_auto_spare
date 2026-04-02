import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/models/models.dart';

void main() {
  test('mobile device JSON omits null optional metadata', () {
    const device = MobileDevice(
      deviceId: 'android-001',
      platform: 'android',
      isActive: true,
    );

    final json = device.toJson();

    expect(json['device_id'], 'android-001');
    expect(json['platform'], 'android');
    expect(json['is_active'], isTrue);
    expect(json.containsKey('device_name'), isFalse);
    expect(json.containsKey('app_version'), isFalse);
    expect(json.containsKey('push_token'), isFalse);
  });

  test('mobile device JSON clears push token when device is deactivated', () {
    const device = MobileDevice(
      deviceId: 'android-001',
      platform: 'android',
      isActive: false,
    );

    final json = device.toJson();

    expect(json['push_token'], '');
    expect(json['is_active'], isFalse);
  });
}
