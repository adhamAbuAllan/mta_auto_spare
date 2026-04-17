import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/auth_api.dart';
import '../../api/catalog_api.dart';
import '../../api/chat_api.dart';
import '../../api/dio_client.dart';
import '../../api/request_api.dart';
import '../../api/system_api.dart';
import '../../api/user_api.dart';
import '../../session/session_notifier.dart';
import '../../session/session_state.dart';

final sessionStateProvider = Provider<SessionState>((ref) {
  return ref.watch(sessionNotifierProvider);
});

final dioProvider = Provider<Dio>((ref) {
  return AppDioClient(ref).build();
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(dioProvider));
});

final catalogApiProvider = Provider<CatalogApi>((ref) {
  return CatalogApi(ref.read(dioProvider));
});

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(ref.read(dioProvider));
});

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.read(dioProvider));
});

final requestApiProvider = Provider<RequestApi>((ref) {
  return RequestApi(ref.read(dioProvider));
});

final systemApiProvider = Provider<SystemApi>((ref) {
  return SystemApi(ref.read(dioProvider));
});
