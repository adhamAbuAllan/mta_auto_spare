import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

bool _appCheckActivated = false;

Future<bool> ensureFirebaseInitialized({bool throwOnError = false}) async {
  if (kIsWeb) {
    return false;
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await _activateAppCheck();
    return true;
  } catch (error) {
    if (throwOnError) {
      throw StateError(
        'Firebase is not configured for this app yet. Add '
        'android/app/google-services.json and ios/Runner/GoogleService-Info.plist, '
        'then enable Firebase phone authentication. Original error: $error',
      );
    }
    debugPrint('Firebase initialization skipped: $error');
    return false;
  }
}

Future<void> _activateAppCheck() async {
  if (_appCheckActivated) {
    return;
  }

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    _appCheckActivated = true;
  } catch (error, stackTrace) {
    debugPrint('Firebase App Check activation skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
