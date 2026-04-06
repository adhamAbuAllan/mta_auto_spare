import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    if (responseData == null) {
      final timeoutMessage = _timeoutMessage(error);
      if (timeoutMessage != null) {
        return ApiException(timeoutMessage, statusCode: statusCode);
      }
      final connectionMessage = _connectionMessage(error);
      if (connectionMessage != null) {
        return ApiException(connectionMessage, statusCode: statusCode);
      }
      return ApiException(
        error.message ?? 'Unexpected network error.',
        statusCode: statusCode,
      );
    }

    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      if (map['detail'] != null) {
        return ApiException(map['detail'].toString(), statusCode: statusCode);
      }
      if (map['message'] != null) {
        final message = map['message'].toString().trim();
        if (message.isNotEmpty) {
          return ApiException(message, statusCode: statusCode);
        }
      }
      final formatted = _formatValidationMap(map);
      if (formatted.isNotEmpty) {
        return ApiException(formatted, statusCode: statusCode);
      }
    }

    if (responseData is List) {
      final formatted = responseData.map(_stringifyValue).join('\n');
      if (formatted.isNotEmpty) {
        return ApiException(formatted, statusCode: statusCode);
      }
    }

    return ApiException(
      error.message ?? 'Unexpected network error.',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;

  static String _formatValidationMap(Map<String, dynamic> responseData) {
    final lines = <String>[];
    const ignoredKeys = {'message', 'status_code', 'code'};

    responseData.forEach((key, value) {
      if (ignoredKeys.contains(key) || value == null) {
        return;
      }

      final messages = _flattenMessages(value);
      if (messages.isEmpty) {
        return;
      }

      final fieldName = _formatFieldName(key);
      for (final message in messages) {
        if (fieldName.isEmpty) {
          lines.add(message);
        } else {
          lines.add('$fieldName: $message');
        }
      }
    });

    return lines.join('\n');
  }

  static List<String> _flattenMessages(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value
          .expand((item) => _flattenMessages(item))
          .where((message) => message.isNotEmpty)
          .toList(growable: false);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value).entries
          .expand(
            (entry) => _flattenMessages(
              '${_formatFieldName(entry.key)}: ${_stringifyValue(entry.value)}',
            ),
          )
          .where((message) => message.isNotEmpty)
          .toList(growable: false);
    }

    final message = _stringifyValue(value);
    return message.isEmpty ? const [] : [message];
  }

  static String _stringifyValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static String _formatFieldName(String key) {
    if (key == 'non_field_errors') {
      return 'General';
    }

    final normalized = key.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return '';
    }

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  static String? _timeoutMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'The server took too long to connect.',
      DioExceptionType.sendTimeout =>
        'The upload took too long. Try fewer or smaller images, or use a stronger connection.',
      DioExceptionType.receiveTimeout => 'The server took too long to respond.',
      _ => null,
    };
  }

  static String? _connectionMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError =>
        'Could not reach the server. Check your connection and API URL.',
      _ => null,
    };
  }
}
