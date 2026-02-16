import 'dart:async';

import '../../domain/sync/sync_provider.dart';

/// Mock implementation: always reports offline (no backend).
class MockSyncProvider implements SyncProvider {
  MockSyncProvider() : _statusController = StreamController<SyncStatus>.broadcast() {
    _statusController.add(SyncStatus.offline);
  }

  final StreamController<SyncStatus> _statusController;

  @override
  Future<void> pushLocalChanges() async {}

  @override
  Future<void> pullRemoteChanges() async {}

  @override
  Stream<SyncStatus> watchStatus() => _statusController.stream;

  void dispose() => _statusController.close();
}
