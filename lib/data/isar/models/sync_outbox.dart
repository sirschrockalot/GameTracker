import 'package:isar/isar.dart';

part 'sync_outbox.g.dart';

/// Outbox item for deferred cloud sync (players, schedule events, etc.).
@collection
class SyncOutboxItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  /// Team scope (teams.uuid).
  late String teamId;

  /// Entity type: "player" | "scheduleEvent".
  late String entityType;

  /// Operation: "upsert" | "delete".
  late String op;

  /// JSON payload for upsert/delete (server contract).
  late String payloadJson;

  late DateTime createdAt;

  int retryCount = 0;

  DateTime? lastTriedAt;

  String? lastError;
}

