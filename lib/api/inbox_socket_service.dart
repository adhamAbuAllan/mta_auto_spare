import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'chat_socket_service.dart';

class InboxSocketService {
  InboxSocketService({String Function()? resolveLanguageCode})
    : _resolveLanguageCode = resolveLanguageCode ?? _defaultLanguageCode;

  final StreamController<MessageModel> _messagesController =
      StreamController<MessageModel>.broadcast();
  final StreamController<ChatConnectionStatus> _statusController =
      StreamController<ChatConnectionStatus>.broadcast();
  final String Function() _resolveLanguageCode;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  String? _token;
  String? _languageCode;
  bool _shouldReconnect = false;
  bool _isDisposed = false;
  int _reconnectAttempt = 0;
  ChatConnectionStatus _status = ChatConnectionStatus.disconnected;

  Stream<MessageModel> get messages => _messagesController.stream;
  Stream<ChatConnectionStatus> get statuses => _statusController.stream;

  ChatConnectionStatus get status => _status;

  Future<void> connect({required String token}) async {
    if (_isDisposed) {
      return;
    }

    final normalizedToken = token.trim();
    final languageCode = _resolveLanguageCode().trim();
    final sameConnection =
        _token == normalizedToken &&
        _languageCode == languageCode &&
        (_status == ChatConnectionStatus.connected ||
            _status == ChatConnectionStatus.connecting ||
            _status == ChatConnectionStatus.reconnecting);
    if (normalizedToken.isEmpty || sameConnection) {
      return;
    }

    _token = normalizedToken;
    _languageCode = languageCode;
    _shouldReconnect = true;
    _reconnectAttempt = 0;
    await _openSocket(isReconnect: false);
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectAttempt = 0;
    await _closeSocket();
    _token = null;
    _languageCode = null;
    _setStatus(ChatConnectionStatus.disconnected);
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _shouldReconnect = false;
    await _closeSocket();
    await _messagesController.close();
    await _statusController.close();
  }

  Future<void> _openSocket({required bool isReconnect}) async {
    final token = _token;
    final languageCode = _resolveLanguageCode().trim();
    if (_isDisposed || token == null || token.isEmpty) {
      return;
    }

    _reconnectTimer?.cancel();
    await _closeSocket();
    _setStatus(
      isReconnect
          ? ChatConnectionStatus.reconnecting
          : ChatConnectionStatus.connecting,
    );
    _languageCode = languageCode;

    final uri = ApiConstants.buildInboxSocketUri(
      token: token,
      languageCode: languageCode,
    );

    try {
      final socket = await WebSocket.connect(
        uri.toString(),
      ).timeout(ApiConstants.connectTimeout);
      _socket = socket;
      _socketSubscription = socket.listen(
        _handleSocketData,
        onDone: _handleSocketDone,
        onError: _handleSocketError,
        cancelOnError: true,
      );
      _reconnectAttempt = 0;
      _startHeartbeat();
      _setStatus(ChatConnectionStatus.connected);
    } catch (error) {
      _setStatus(ChatConnectionStatus.failed);
      if (_isTerminalHandshakeFailure(error)) {
        return;
      }
      _scheduleReconnect();
    }
  }

  bool _isTerminalHandshakeFailure(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains(' 401') ||
        message.contains(' 403') ||
        message.contains('unauthorized') ||
        message.contains('forbidden') ||
        message.contains('access denied');
  }

  void _handleSocketData(dynamic data) {
    if (data is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) {
        return;
      }

      final payload = Map<String, dynamic>.from(decoded);
      final type = payload['type']?.toString() ?? '';
      if (type != 'inbox.message') {
        return;
      }

      final messageJson = payload['message'];
      if (messageJson is! Map) {
        return;
      }
      _messagesController.add(
        MessageModel.fromJson(Map<String, dynamic>.from(messageJson)),
      );
    } catch (_) {
      // Ignore malformed payloads and keep the connection alive.
    }
  }

  void _handleSocketDone() {
    _scheduleReconnect();
  }

  void _handleSocketError(Object _) {
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(ApiConstants.chatHeartbeatInterval, (_) {
      final socket = _socket;
      if (socket == null || _status != ChatConnectionStatus.connected) {
        return;
      }
      socket.add(jsonEncode(const {'type': 'ping'}));
    });
  }

  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket = null;

    if (_isDisposed || !_shouldReconnect) {
      _setStatus(ChatConnectionStatus.disconnected);
      return;
    }

    _setStatus(ChatConnectionStatus.reconnecting);
    final exponent = _reconnectAttempt.clamp(0, 3);
    final delaySeconds = 1 << exponent;
    final delay = Duration(
      seconds: delaySeconds.clamp(
        ApiConstants.chatReconnectBaseDelay.inSeconds,
        ApiConstants.chatReconnectMaxDelay.inSeconds,
      ),
    );
    _reconnectAttempt += 1;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _openSocket(isReconnect: true);
    });
  }

  Future<void> _closeSocket() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {
        // Best effort shutdown.
      }
    }
  }

  void _setStatus(ChatConnectionStatus next) {
    if (_status == next || _isDisposed) {
      return;
    }
    _status = next;
    _statusController.add(next);
  }

  static String _defaultLanguageCode() => 'en';
}
