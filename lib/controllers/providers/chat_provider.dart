import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/chat_socket_service.dart';
import '../../api/inbox_socket_service.dart';
import '../../notifications/chat_sound_effects.dart';
import '../../localization/app_locale.dart';
import '../../localization/app_locale_notifier.dart';
import '../../models/models.dart';
import '../../session/session_notifier.dart';
import '../methods/api_methods/load_conversations_notifier.dart';
import '../methods/api_methods/ensure_conversation_notifier.dart';
import '../methods/api_methods/load_messages_notifier.dart';
import '../methods/local_methods/chat_message_cache_store.dart';
import '../statuses/conversation_state.dart';
import '../statuses/message_state.dart';
import 'api_provider.dart';

final selectedConversationIdProvider = StateProvider<int?>((ref) => null);
final pendingSharedProductProvider = StateProvider<PartRequestBrief?>(
  (ref) => null,
);

String _currentAppLanguageCode(Ref ref) {
  final locale = resolveEffectiveAppLocale(
    mode: ref.read(appLocaleProvider),
    deviceLocale: currentDeviceLocale(),
  );
  return locale.languageCode;
}

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService(
    resolveLanguageCode: () => _currentAppLanguageCode(ref),
  );
  ref.onDispose(service.dispose);
  return service;
});

final inboxSocketServiceProvider = Provider<InboxSocketService>((ref) {
  final service = InboxSocketService(
    resolveLanguageCode: () => _currentAppLanguageCode(ref),
  );
  ref.onDispose(service.dispose);
  return service;
});

final chatMessageCacheStoreProvider = Provider<ChatMessageCacheStore>((ref) {
  return ChatMessageCacheStore(ref.read(sharedPreferencesProvider));
});

final chatSoundEffectsProvider = Provider<ChatSoundEffects>((ref) {
  final effects = ChatSoundEffects();
  ref.onDispose(() => unawaited(effects.dispose()));
  return effects;
});

final conversationsNotifierProvider =
    StateNotifierProvider<LoadConversationsNotifier, ConversationState>((ref) {
      final notifier = LoadConversationsNotifier(
        ref.read(chatApiProvider),
        ref.read(inboxSocketServiceProvider),
      );
      ref.listen(sessionNotifierProvider, (previous, next) {
        unawaited(notifier.syncWithSession(next));
      });
      ref.listen(appLocaleProvider, (previous, next) {
        unawaited(
          notifier.refreshTranslationLocale(ref.read(sessionNotifierProvider)),
        );
      });
      unawaited(notifier.syncWithSession(ref.read(sessionNotifierProvider)));
      return notifier;
    });

final messagesNotifierProvider =
    StateNotifierProvider<LoadMessagesNotifier, MessageState>((ref) {
      final notifier = LoadMessagesNotifier(
        ref.read(chatApiProvider),
        ref.read(chatSocketServiceProvider),
        cacheStore: ref.read(chatMessageCacheStoreProvider),
        resolveLiveAccessToken: () async {
          final session = ref.read(sessionNotifierProvider);
          final currentAccessToken = session.accessToken;
          final refreshToken = session.refreshToken;

          if (refreshToken == null || refreshToken.isEmpty) {
            return currentAccessToken;
          }

          try {
            final refreshedTokens = await ref
                .read(authApiProvider)
                .refresh(refreshToken: refreshToken);
            await ref
                .read(sessionNotifierProvider.notifier)
                .saveTokens(refreshedTokens);
            return refreshedTokens.access.isNotEmpty
                ? refreshedTokens.access
                : currentAccessToken;
          } catch (_) {
            return currentAccessToken;
          }
        },
        resolveCacheUserId: () => ref.read(sessionNotifierProvider).profile?.id,
        onMessagePreviewChanged:
            ({
              required conversationId,
              required message,
              required isActiveConversation,
              required currentUserId,
            }) {
              ref
                  .read(conversationsNotifierProvider.notifier)
                  .touchConversationFromMessage(
                    conversationId: conversationId,
                    message: message,
                    isActiveConversation: isActiveConversation,
                    currentUserId: currentUserId,
                  );
            },
        onIncomingMessageReceived:
            ({
              required message,
              required isActiveConversation,
              required currentUserId,
            }) {
              if (isActiveConversation && message.sender.id != currentUserId) {
                unawaited(
                  ref.read(chatSoundEffectsProvider).playIncomingMessage(),
                );
              }
            },
        onConversationMessagesChanged:
            ({
              required conversationId,
              required messages,
              required isActiveConversation,
              required currentUserId,
            }) {
              ref
                  .read(conversationsNotifierProvider.notifier)
                  .syncConversationFromMessages(
                    conversationId: conversationId,
                    messages: messages,
                    currentUserId: currentUserId,
                    isActiveConversation: isActiveConversation,
                  );
            },
        onConversationReadChanged: (conversationId) {
          ref
              .read(conversationsNotifierProvider.notifier)
              .markConversationRead(conversationId);
        },
        onUserPresenceChanged:
            ({required userId, required isOnline, lastSeenAt}) {
              ref
                  .read(conversationsNotifierProvider.notifier)
                  .updateUserPresence(
                    userId: userId,
                    isOnline: isOnline,
                    lastSeenAt: lastSeenAt,
                  );
            },
      );
      ref.listen(appLocaleProvider, (previous, next) {
        unawaited(notifier.refreshTranslationLocale());
      });
      return notifier;
    });

final ensureConversationNotifierProvider =
    StateNotifierProvider<EnsureConversationNotifier, EnsureConversationState>((
      ref,
    ) {
      return EnsureConversationNotifier(ref.read(chatApiProvider));
    });
