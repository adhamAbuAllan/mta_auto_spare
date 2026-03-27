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

  test('ApiUser toJson omits optional null fields', () {
    const user = ApiUser(
      email: 'new@example.com',
      username: 'new_user',
      name: 'New User',
      role: 'user',
      password: 'secret123',
    );

    final json = user.toJson();

    expect(json, {
      'email': 'new@example.com',
      'username': 'new_user',
      'name': 'New User',
      'role': 'user',
      'password': 'secret123',
    });
    expect(json.containsKey('phone'), isFalse);
    expect(json.containsKey('city'), isFalse);
    expect(json.containsKey('avatar'), isFalse);
  });
}
