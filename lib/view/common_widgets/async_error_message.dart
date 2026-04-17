import '../../api/api_exception.dart';

String asyncErrorMessage(
  Object? error, {
  String fallback = 'Unexpected error.',
}) {
  if (error == null) {
    return fallback;
  }

  if (error is ApiException) {
    final statusCode = error.statusCode;
    if (statusCode != null) {
      return 'HTTP $statusCode: ${error.message}';
    }
    return error.message;
  }

  final message = error.toString().trim();
  if (message.isEmpty) {
    return fallback;
  }
  if (message.startsWith('Exception: ')) {
    final normalized = message.substring('Exception: '.length).trim();
    return normalized.isEmpty ? fallback : normalized;
  }
  return message;
}
