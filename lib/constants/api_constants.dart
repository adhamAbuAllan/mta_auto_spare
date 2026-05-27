abstract final class ApiConstants {
  static const String ngrok = 'https://polishedly-bouncy-jerry.ngrok-free.dev';
  static const String render = 'https://auto-spare-api.onrender.com';
  static const String baseUrl =
     render;
  static const String acceptHeader = 'application/json';
  static const String ngrokHeaderKey = 'ngrok-skip-browser-warning';
  static const String ngrokHeaderValue = 'true';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
  static const Duration requestUploadSendTimeout = Duration(minutes: 2);
  static const Duration chatHeartbeatInterval = Duration(seconds: 20);
  static const Duration chatReconnectBaseDelay = Duration(seconds: 1);
  static const Duration chatReconnectMaxDelay = Duration(seconds: 8);
  static const String chatMessageNotificationChannelId = 'chat_messages';
  static const String chatActivityNotificationChannelId = 'chat_activity';

  static String resolveUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      if (_shouldReplaceWithBaseHost(parsed)) {
        return _rebuildAgainstBaseUrl(parsed);
      }
      return trimmed;
    }

    return Uri.parse(baseUrl).resolve(trimmed).toString();
  }

  static bool _shouldReplaceWithBaseHost(Uri uri) {
    final host = uri.host.trim().toLowerCase();
    return host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '0.0.0.0';
  }

  static String _rebuildAgainstBaseUrl(Uri original) {
    final base = Uri.parse(baseUrl);
    final normalizedPath = original.path.startsWith('/')
        ? original.path
        : '/${original.path}';
    return base
        .replace(
          path: normalizedPath,
          queryParameters: original.hasQuery ? original.queryParameters : null,
          fragment: original.fragment.isEmpty ? null : original.fragment,
        )
        .toString();
  }

  static Uri buildChatSocketUri({
    required int conversationId,
    required String token,
    String? languageCode,
  }) {
    final base = Uri.parse(baseUrl);
    final scheme = switch (base.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => 'ws',
    };
    return base.replace(
      scheme: scheme,
      path: '/ws/chat/$conversationId/',
      queryParameters: {
        'token': token,
        if ((languageCode ?? '').trim().isNotEmpty) 'lang': languageCode,
      },
    );
  }

  static Uri buildInboxSocketUri({
    required String token,
    String? languageCode,
  }) {
    final base = Uri.parse(baseUrl);
    final scheme = switch (base.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => 'ws',
    };
    return base.replace(
      scheme: scheme,
      path: '/ws/inbox/',
      queryParameters: {
        'token': token,
        if ((languageCode ?? '').trim().isNotEmpty) 'lang': languageCode,
      },
    );
  }
}

abstract final class ApiEndpoints {
  static const String health = '/api/health/';
  static const String login = '/api/token/';
  static const String refresh = '/api/token/refresh/';
  static const String me = '/api/me/';
  static const String mobileDevices = '/api/mobile-devices/';
  static const String users = '/api/users/';
  static const String userReports = '/api/user-reports/';
  static const String carMakes = '/api/car-makes/';
  static const String partRequests = '/api/part-requests/';
  static const String partRequestStatuses = '/api/part-request-statuses/';
  static const String partRequestAccesses = '/api/part-request-accesses/';
  static const String conversations = '/api/conversations/';
  static const String conversationParticipants =
      '/api/conversation-participants/';
  static const String messages = '/api/messages/';
}
