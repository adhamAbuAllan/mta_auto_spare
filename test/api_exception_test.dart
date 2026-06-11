import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/api/api_exception.dart';
import 'package:mta_auto_spare/models/models.dart';

void main() {
  test('ApiException formats backend field errors with field names', () {
    final requestOptions = RequestOptions(path: '/api/users/');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 400,
        data: {
          'phone': ['This field may not be null.'],
          'city': ['This field may not be null.'],
        },
      ),
    );

    final exception = ApiException.fromDioException(error);

    expect(
      exception.message,
      'Phone: This field may not be null.\nCity: This field may not be null.',
    );
  });

  test('ApiException prefers the backend message over metadata fields', () {
    final requestOptions = RequestOptions(path: '/api/users/');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 400,
        data: {
          'email': ['A user with this email already exists.'],
          'message': 'A user with this email already exists.',
          'status_code': 400,
        },
      ),
    );

    final exception = ApiException.fromDioException(error);

    expect(exception.message, 'A user with this email already exists.');
  });

  test('ApiException maps upload send timeout to a helpful message', () {
    final requestOptions = RequestOptions(path: '/api/part-requests/');
    final error = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.sendTimeout,
    );

    final exception = ApiException.fromDioException(error);

    expect(
      exception.message,
      'The upload took too long. Try fewer or smaller images, or use a stronger connection.',
    );
  });

  test('ApiException maps connection errors to a helpful message', () {
    final requestOptions = RequestOptions(path: '/api/part-requests/');
    final error = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.connectionError,
    );

    final exception = ApiException.fromDioException(error);

    expect(
      exception.message,
      'Could not reach the server. Check your connection and API URL.',
    );
  });

  test('ApiUser toJson omits optional null fields', () {
    const user = ApiUser(
      name: 'New User',
      phone: '+966555000111',
      role: 'user',
      password: 'secret123',
    );

    final json = user.toJson();

    expect(json, {
      'name': 'New User',
      'phone': '+966555000111',
      'role': 'user',
      'is_active': true,
      'is_admin': false,
      'password': 'secret123',
    });
    expect(json.containsKey('city'), isFalse);
    expect(json.containsKey('avatar'), isFalse);
  });
}
