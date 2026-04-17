import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../api/auth_api.dart';
import '../../../models/models.dart';
import '../../../session/session_notifier.dart';
import '../../statuses/auth_state.dart';

class UpdateProfileNotifier extends StateNotifier<AuthState> {
  UpdateProfileNotifier({
    required AuthApi authApi,
    required SessionNotifier sessionNotifier,
  }) : _authApi = authApi,
       _sessionNotifier = sessionNotifier,
       super(const AuthState());

  final AuthApi _authApi;
  final SessionNotifier _sessionNotifier;

  Future<MeProfile?> update({
    required String name,
    required String? phone,
    required String? city,
    required bool chatPushEnabled,
    required bool chatMessagePreviewEnabled,
    List<int>? supportedCarModelIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = await _authApi.updateProfile(
        name: name,
        phone: phone,
        city: city,
        chatPushEnabled: chatPushEnabled,
        chatMessagePreviewEnabled: chatMessagePreviewEnabled,
        supportedCarModelIds: supportedCarModelIds,
      );
      await _sessionNotifier.saveProfile(profile);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        profile: profile,
      );
      return profile;
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }

    return null;
  }
}
