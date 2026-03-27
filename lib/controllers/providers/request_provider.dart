import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../methods/api_methods/create_request_notifier.dart';
import '../methods/api_methods/load_requests_notifier.dart';
import '../statuses/request_state.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

final requestsNotifierProvider =
    StateNotifierProvider<LoadRequestsNotifier, RequestState>((ref) {
      return LoadRequestsNotifier(ref.read(requestApiProvider));
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

final activeRequestsProvider = Provider<List<PartRequest>>((ref) {
  final state = ref.watch(requestsNotifierProvider);
  return switch (state.segment) {
    RequestSegment.browse => ref.watch(browseRequestsProvider),
    RequestSegment.mine => ref.watch(myRequestsProvider),
  };
});
