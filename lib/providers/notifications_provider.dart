import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/notifications_api.dart';

final pendingNotificationsSummaryProvider =
    FutureProvider<PendingRequestsSummary>((ref) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  if (baseUrl.isEmpty) {
    return PendingRequestsSummary(pendingByTeam: const {}, totalPending: 0);
  }
  final client = ref.read(authenticatedHttpClientProvider);
  return fetchPendingRequestsSummary(client);
});

final notificationsPollerProvider = Provider<void>((ref) {
  Timer? timer;
  void tick(Timer _) {
    ref.invalidate(pendingNotificationsSummaryProvider);
  }

  timer = Timer.periodic(const Duration(seconds: 60), tick);
  ref.onDispose(() {
    timer?.cancel();
  });
});

