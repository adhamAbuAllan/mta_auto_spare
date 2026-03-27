abstract final class ApiConstants {
  static const String baseUrl =
      'https://polishedly-bouncy-jerry.ngrok-free.dev';
  static const String acceptHeader = 'application/json';
  static const String ngrokHeaderKey = 'ngrok-skip-browser-warning';
  static const String ngrokHeaderValue = 'true';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}

abstract final class ApiEndpoints {
  static const String health = '/api/health/';
  static const String login = '/api/token/';
  static const String refresh = '/api/token/refresh/';
  static const String me = '/api/me/';
  static const String users = '/api/users/';
  static const String partRequests = '/api/part-requests/';
  static const String partRequestStatuses = '/api/part-request-statuses/';
  static const String conversations = '/api/conversations/';
  static const String conversationParticipants =
      '/api/conversation-participants/';
  static const String messages = '/api/messages/';
}
