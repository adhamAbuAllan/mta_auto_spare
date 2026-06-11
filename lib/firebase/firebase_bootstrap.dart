import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future<bool> ensureFirebaseInitialized({bool throwOnError = false}) async {
  if (kIsWeb) {
    return false;
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
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
