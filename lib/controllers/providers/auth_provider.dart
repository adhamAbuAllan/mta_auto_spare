import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/session_notifier.dart';
import '../methods/api_methods/load_profile_notifier.dart';
import '../methods/api_methods/login_notifier.dart';
import '../methods/api_methods/register_notifier.dart';
import '../methods/api_methods/session_bootstrapper.dart';
import '../methods/api_methods/update_profile_notifier.dart';
import '../methods/local_methods/logout_notifier.dart';
import '../statuses/auth_state.dart';
import 'api_provider.dart';
import 'chat_provider.dart';
import 'notification_provider.dart';

final registerNotifierProvider =
    StateNotifierProvider<RegisterNotifier, AuthState>((ref) {
      return RegisterNotifier(
        authApi: ref.read(authApiProvider),
        sessionNotifier: ref.read(sessionNotifierProvider.notifier),
      );
    });

final loginNotifierProvider = StateNotifierProvider<LoginNotifier, AuthState>((
  ref,
) {
  return LoginNotifier(
    authApi: ref.read(authApiProvider),
    sessionNotifier: ref.read(sessionNotifierProvider.notifier),
  );
});

final loadProfileNotifierProvider =
    StateNotifierProvider<LoadProfileNotifier, AuthState>((ref) {
      return LoadProfileNotifier(
        authApi: ref.read(authApiProvider),
        sessionNotifier: ref.read(sessionNotifierProvider.notifier),
      );
    });

final updateProfileNotifierProvider =
    StateNotifierProvider.autoDispose<UpdateProfileNotifier, AuthState>((ref) {
      return UpdateProfileNotifier(
        authApi: ref.read(authApiProvider),
        sessionNotifier: ref.read(sessionNotifierProvider.notifier),
      );
    });

final logoutNotifierProvider = StateNotifierProvider<LogoutNotifier, AuthState>(
  (ref) {
    return LogoutNotifier(
      ref.read(sessionNotifierProvider.notifier),
      beforeLogout: () async {
        await ref
            .read(chatNotificationServiceProvider)
            .deactivateCurrentDevice();
      },
      onLogout: () async {
        await ref.read(chatSocketServiceProvider).disconnect();
        ref.invalidate(conversationsNotifierProvider);
        ref.invalidate(messagesNotifierProvider);
        ref.invalidate(ensureConversationNotifierProvider);
        ref.invalidate(inboxSocketServiceProvider);
        ref.invalidate(chatSocketServiceProvider);
        ref.read(selectedConversationIdProvider.notifier).state = null;
      },
    );
  },
);

final currentSessionProvider = Provider((ref) {
  return ref.watch(sessionNotifierProvider);
});

final sessionBootstrapperProvider = Provider<SessionBootstrapper>((ref) {
  return SessionBootstrapper(
    authApi: ref.read(authApiProvider),
    sessionNotifier: ref.read(sessionNotifierProvider.notifier),
  );
});

final loginPhoneControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final loginPasswordControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final registerPhoneControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final registerNameControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final registerPasswordControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final isPasswordObscureProvider = StateProvider<bool>((ref) => true);
