import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/app_localizations.dart';

/// Converts Firebase failures into app-localized, user-safe messages.
///
/// Firebase's [FirebaseException.message] is supplied by the SDK and is not
/// guaranteed to use the language selected in the app. Do not show it to the
/// user; map its stable error code instead.
String localizeFirebaseError(Object error, AppLocalizations l10n) {
  if (error is! FirebaseAuthException) {
    return l10n.phoneVerificationFailed;
  }

  final code = error.code.trim().toLowerCase();
  final searchable = '$code ${error.message ?? ''}'.toLowerCase();

  if (code == 'operation-not-allowed' ||
      code == 'app-not-authorized' ||
      searchable.contains('sms unable') ||
      searchable.contains('region')) {
    return l10n.firebaseSmsBlocked;
  }
  if (code == 'invalid-phone-number') {
    return l10n.validPhoneNumberError;
  }
  if (code == 'too-many-requests' || code == 'quota-exceeded') {
    return l10n.tooManySmsAttempts;
  }
  if (code == 'invalid-verification-code') {
    return l10n.smsCodeIncorrect;
  }
  if (code == 'session-expired') {
    return l10n.smsCodeExpired;
  }
  if (code == 'network-request-failed' ||
      code == 'network-error' ||
      code == 'web-network-request-failed') {
    return l10n.firebaseNetworkError;
  }

  // Includes new/unknown Firebase codes. Never expose the SDK's English (or
  // device-language) message, as it may not match the app language.
  return l10n.phoneVerificationFailed;
}
