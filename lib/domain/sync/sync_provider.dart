/// Sync status for multi-coach Phase 2 (no backend integration yet).
enum SyncStatus {
  offline,
  syncing,
  upToDate,
}

/// Interface for pushing/pulling changes. No implementation yet; use [MockSyncProvider].
abstract class SyncProvider {
  Future<void> pushLocalChanges();
  Future<void> pullRemoteChanges();
  Stream<SyncStatus> watchStatus();
}
