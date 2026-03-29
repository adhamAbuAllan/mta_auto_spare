import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/api_constants.dart';
import '../models/models.dart';

enum ChatConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class ChatSocketService {
  ChatSocketService();

  final StreamController<ChatSocketEvent> _eventsController =
      StreamController<ChatSocketEvent>.broadcast();
  final StreamController<ChatConnectionStatus> _statusController =
      StreamController<ChatConnectionStatus>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int? _conversationId;
  String? _token;
  bool _shouldReconnect = false;
  bool _isPaused = false;
  bool _isDisposed = false;
  int _reconnectAttempt = 0;
  ChatConnectionStatus _status = ChatConnectionStatus.disconnected;

  Stream<ChatSocketEvent> get events => _eventsController.stream;
  Stream<ChatConnectionStatus> get statuses => _statusController.stream;

  ChatConnectionStatus get status => _status;
  int? get activeConversationId => _conversationId;

  Future<void> connect({
    required int conversationId,
    required String token,
  }) async {
    if (_isDisposed) {
      return;
    }

    final sameConnection =
        _conversationId == conversationId &&
        _token == token &&
        (_status == ChatConnectionStatus.connected ||
            _status == ChatConnectionStatus.connecting ||
            _status == ChatConnectionStatus.reconnecting);
    if (sameConnection) {
      return;
    }

    _conversationId = conversationId;
    _token = token;
    _shouldReconnect = true;
    _isPaused = false;
    _reconnectAttempt = 0;
    await _openSocket(isReconnect: false);
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectAttempt = 0;
    await _closeSocket();
    _conversationId = null;
    _token = null;
    _setStatus(ChatConnectionStatus.disconnected);
  }

  Future<void> pause() async {
    _isPaused = true;
    await _closeSocket();
    if (!_isDisposed) {
      _setStatus(ChatConnectionStatus.disconnected);
    }
  }

  Future<void> resume() async {
    if (_isDisposed) {
      return;
    }
    _isPaused = false;
    final conversationId = _conversationId;
    final token = _token;
    if (conversationId == null || token == null || token.isEmpty) {
      return;
    }
    await _openSocket(isReconnect: true);
  }

  Future<void> sendJson(Map<String, dynamic> payload) async {
    final socket = _socket;
    if (socket == null || _status != ChatConnectionStatus.connected) {
      return;
    }
    socket.add(jsonEncode(payload));
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _shouldReconnect = false;
    await _closeSocket();
    await _eventsController.close();
    await _statusController.close();
  }

  Future<void> _openSocket({required bool isReconnect}) async {
    final conversationId = _conversationId;
    final token = _token;
    if (_isDisposed ||
        _isPaused ||
        conversationId == null ||
        token == null ||
        token.isEmpty) {
      return;
    }

    _reconnectTimer?.cancel();
    await _closeSocket();
    _setStatus(
      isReconnect
          ? ChatConnectionStatus.reconnecting
          : ChatConnectionStatus.connecting,
    );

    final uri = ApiConstants.buildChatSocketUri(
      conversationId: conversationId,
      token: token,
    );

    try {
      final socket = await WebSocket.connect(uri.toString()).timeout(
        ApiConstants.connectTimeout,
      );
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
    } catch (_) {
      _setStatus(ChatConnectionStatus.failed);
      _scheduleReconnect();
    }
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
      final event = ChatSocketEvent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _eventsController.add(event);
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
      sendJson(const PingSocketRequest().toJson());
    });
  }

  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket = null;

    if (_isDisposed || !_shouldReconnect || _isPaused) {
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
}
