import '../../api/api_exception.dart';
import '../../l10n/app_localizations.dart';

String asyncErrorMessage(
  Object? error, {
  required AppLocalizations l10n,
  String fallback = 'Unexpected error.',
}) {
  return localizeErrorMessage(error, l10n, fallback: fallback);
}

/// Converts transport, backend, and SDK messages into safe app-localized text.
/// Raw diagnostics remain available in logs, but never reach the user-facing UI.
String localizeErrorMessage(
  Object? error,
  AppLocalizations l10n, {
  String? fallback,
}) {
  if (error == null) {
    return fallback ?? l10n.errorUnexpected;
  }

  final statusCode = error is ApiException ? error.statusCode : null;
  final raw = error is ApiException ? error.message : error.toString();
  return _localizeErrorText(
    raw,
    l10n,
    statusCode: statusCode,
    fallback: fallback,
  );
}

String localizeErrorText(
  String? raw,
  AppLocalizations l10n, {
  int? statusCode,
  String? fallback,
}) {
  return _localizeErrorText(
    raw,
    l10n,
    statusCode: statusCode,
    fallback: fallback,
  );
}

String _localizeErrorText(
  String? raw,
  AppLocalizations l10n, {
  int? statusCode,
  String? fallback,
}) {
  final message = (raw ?? '').trim();
  if (message.isEmpty) {
    return fallback ?? l10n.errorUnexpected;
  }

  final lower = message.toLowerCase();
  if (statusCode == 401 ||
      _containsAny(lower, const [
        'unauthorized',
        'authentication credentials were not provided',
        'token is invalid',
        'token not valid',
      ])) {
    return l10n.errorUnauthorized;
  }
  if (statusCode == 403 ||
      _containsAny(lower, const [
        'permission denied',
        'forbidden',
        'not permitted',
        'do not have permission',
      ])) {
    return l10n.errorForbidden;
  }
  if (statusCode == 404 ||
      _containsAny(lower, const [
        'not found',
        'does not exist',
        'status code of 404',
      ])) {
    return l10n.errorNotFound;
  }
  if ((statusCode != null && statusCode >= 500 && statusCode <= 599) ||
      _containsAny(lower, const [
        'status code of 5',
        'internal server error',
        'bad gateway',
        'service unavailable',
      ])) {
    return l10n.errorServer;
  }
  if (_containsAny(lower, const [
    'connection error',
    'connection timeout',
    'send timeout',
    'receive timeout',
    'could not connect',
    'network error',
    'network-request-failed',
    'requestoptions.validatestatus',
  ])) {
    return l10n.errorNetwork;
  }
  if (statusCode == 400 ||
      _containsAny(lower, const [
        'bad request',
        'validation error',
        'invalid request',
        'is required',
        'may not be blank',
        'invalid phone',
      ])) {
    return l10n.errorInvalidRequest;
  }

  // These are already app-authored messages, rather than SDK diagnostics.
  if (_containsAny(lower, const ['already has an account'])) {
    return message;
  }

  // Preserve messages that are already written in a non-Latin app language.
  if (RegExp(r'[\u0590-\u05FF\u0600-\u06FF\u0400-\u04FF]').hasMatch(message)) {
    return message;
  }

  return fallback ?? l10n.errorUnexpected;
}

bool _containsAny(String value, List<String> patterns) {
  return patterns.any(value.contains);
}
