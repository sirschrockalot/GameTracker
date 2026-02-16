import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/mock_sync_provider.dart';
import '../domain/sync/sync_provider.dart' as domain;

final syncProviderInstanceProvider = Provider<domain.SyncProvider>((ref) {
  return MockSyncProvider();
});

final syncStatusStreamProvider = StreamProvider<domain.SyncStatus>((ref) {
  return ref.watch(syncProviderInstanceProvider).watchStatus();
});
