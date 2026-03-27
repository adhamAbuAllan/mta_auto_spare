import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  factory ApiException.fromDioException(DioException error) {
    final responseData = error.response?.data;
    if (responseData == null) {
      return ApiException(error.message ?? 'Unexpected network error.');
    }

    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      if (map['detail'] != null) {
        return ApiException(map['detail'].toString());
      }
      final formatted = _formatValidationMap(map);
      if (formatted.isNotEmpty) {
        return ApiException(formatted);
      }
    }

    if (responseData is List) {
      final formatted = responseData.map(_stringifyValue).join('\n');
      if (formatted.isNotEmpty) {
        return ApiException(formatted);
      }
    }

    return ApiException(error.message ?? 'Unexpected network error.');
  }

  @override
  String toString() => message;

  static String _formatValidationMap(Map<String, dynamic> responseData) {
    final lines = <String>[];

    responseData.forEach((key, value) {
      if (value == null) {
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
}
