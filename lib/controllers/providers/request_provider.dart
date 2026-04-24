import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../localization/app_locale_notifier.dart';
import '../../models/models.dart';
import '../methods/api_methods/create_request_notifier.dart';
import '../methods/api_methods/load_requests_notifier.dart';
import '../statuses/request_state.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

final requestsNotifierProvider =
    StateNotifierProvider<LoadRequestsNotifier, RequestState>((ref) {
      final notifier = LoadRequestsNotifier(ref.read(requestApiProvider));
      ref.listen(appLocaleProvider, (previous, next) {
        unawaited(notifier.refreshTranslationLocale());
      });
      return notifier;
    });

final createRequestNotifierProvider =
    StateNotifierProvider.autoDispose<
      CreateRequestNotifier,
      CreateRequestState
    >((ref) {
      return CreateRequestNotifier(ref.read(requestApiProvider));
    });

final currentUserIdProvider = Provider<int?>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session.profile?.id;
});

final requestStatusesProvider = FutureProvider<List<PartRequestStatus>>((
  ref,
) async {
  return ref.read(requestApiProvider).getAllRequestStatuses();
});

final browseRequestsProvider = Provider<List<PartRequest>>((ref) {
  final state = ref.watch(requestsNotifierProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) {
    return state.requests;
  }
  return state.browseRequestsFor(currentUserId);
});

final myRequestsProvider = Provider<List<PartRequest>>((ref) {
  final state = ref.watch(requestsNotifierProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) {
    return const [];
  }
  return state.myRequestsFor(currentUserId);
});

final assignedRequestsProvider = Provider<List<PartRequest>>((ref) {
  final state = ref.watch(requestsNotifierProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) {
    return const [];
  }
  return state.assignedRequestsFor(currentUserId);
});

final activeRequestsProvider = Provider<List<PartRequest>>((ref) {
  final state = ref.watch(requestsNotifierProvider);
  final requests = switch (state.segment) {
    RequestSegment.browse => ref.watch(browseRequestsProvider),
    RequestSegment.mine => ref.watch(myRequestsProvider),
    RequestSegment.assigned => ref.watch(assignedRequestsProvider),
  };
  final selectedStatusId = state.selectedStatusId;
  if (selectedStatusId == null) {
    return requests;
  }
  return requests
      .where((request) => request.status == selectedStatusId)
      .toList(growable: false);
});
