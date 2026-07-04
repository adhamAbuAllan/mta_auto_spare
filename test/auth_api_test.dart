import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/api/auth_api.dart';
import 'package:mta_auto_spare/constants/api_constants.dart';

void main() {
  test('login sends phone and password to the token endpoint', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiEndpoints.login);
          expect(options.data, {
            'phone': '+966555000111',
            'password': 'StrongPass123!',
          });
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {'access': 'access-token', 'refresh': 'refresh-token'},
            ),
          );
        },
      ),
    );

    final authApi = AuthApi(dio);
    final tokens = await authApi.login(
      phone: '+966555000111',
      password: 'StrongPass123!',
    );

    expect(tokens.access, 'access-token');
    expect(tokens.refresh, 'refresh-token');
  });

  test(
    'registerVerifiedPhone posts Firebase token and returns session',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, ApiEndpoints.register);
            expect(options.data, {
              'firebase_id_token': 'firebase-token',
              'phone': '+966555000111',
              'password': 'StrongPass123!',
              'name': 'New User',
              'role': 'supplier',
              'supported_car_model_ids': [1, 2],
            });
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'access': 'access-token',
                  'refresh': 'refresh-token',
                  'user': {
                    'id': 9,
                    'name': 'New User',
                    'phone': '+966555000111',
                    'role': 'supplier',
                    'is_active': true,
                    'is_admin': false,
                    'chat_push_enabled': true,
                    'chat_message_preview_enabled': false,
                    'created_at': '2026-06-01T00:00:00Z',
                  },
                },
              ),
            );
          },
        ),
      );

      final authApi = AuthApi(dio);
      final session = await authApi.registerVerifiedPhone(
        firebaseIdToken: 'firebase-token',
        phone: '+966555000111',
        password: 'StrongPass123!',
        name: 'New User',
        role: 'supplier',
        supportedCarModelIds: [1, 2],
      );

      expect(session.tokens.access, 'access-token');
      expect(session.tokens.refresh, 'refresh-token');
      expect(session.profile.id, 9);
      expect(session.profile.phone, '+966555000111');
    },
  );

  test(
    'resetPasswordWithVerifiedPhone posts Firebase token and new password',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, ApiEndpoints.passwordReset);
            expect(options.data, {
              'firebase_id_token': 'firebase-token',
              'phone': '+966555000111',
              'password': 'NewStrongPass123!',
            });
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {'detail': 'Password updated successfully.'},
              ),
            );
          },
        ),
      );

      final authApi = AuthApi(dio);
      await authApi.resetPasswordWithVerifiedPhone(
        firebaseIdToken: 'firebase-token',
        phone: '+966555000111',
        password: 'NewStrongPass123!',
      );
    },
  );

  test(
    'refresh keeps the old refresh token when backend only returns access',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {'access': 'new-access-token'},
              ),
            );
          },
        ),
      );

      final authApi = AuthApi(dio);
      final tokens = await authApi.refresh(
        refreshToken: 'existing-refresh-token',
      );

      expect(tokens.access, 'new-access-token');
      expect(tokens.refresh, 'existing-refresh-token');
    },
  );
}
