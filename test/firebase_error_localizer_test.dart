import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mta_auto_spare/l10n/app_localizations_ar.dart';
import 'package:mta_auto_spare/l10n/app_localizations_en.dart';
import 'package:mta_auto_spare/localization/firebase_error_localizer.dart';

void main() {
  test('translates Firebase network failures in the selected app language', () {
    final error = FirebaseAuthException(
      code: 'network-request-failed',
      message: 'A network error has occurred.',
    );

    expect(
      localizeFirebaseError(error, AppLocalizationsAr()),
      'لا يوجد اتصال بالإنترنت. تحقق من الاتصال ثم حاول مرة أخرى.',
    );
  });

  test('does not expose an unknown Firebase SDK message', () {
    final error = FirebaseAuthException(
      code: 'new-firebase-error',
      message: 'English SDK message that must not be shown.',
    );

    expect(
      localizeFirebaseError(error, AppLocalizationsEn()),
      'Phone verification failed.',
    );
  });
}
