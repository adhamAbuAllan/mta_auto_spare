import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/api/auth_api.dart';

void main() {
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
