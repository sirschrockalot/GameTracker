import 'dart:convert';

import 'package:isar/isar.dart';

import '../isar/models/sync_outbox.dart';

class SyncOutboxRepository {
  SyncOutboxRepository(this._isar);

  final Isar _isar;

  Future<void> enqueue({
    required String uuid,
    required String teamId,
    required String entityType,
    required String op,
    required Map<String, dynamic> payload,
  }) async {
    final existing = await _isar.syncOutboxItems
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    final item = existing ?? SyncOutboxItem()
      ..uuid = uuid
      ..teamId = teamId
      ..entityType = entityType
      ..op = op
      ..createdAt = existing?.createdAt ?? DateTime.now();

    item.payloadJson = jsonEncode(payload);
    item.lastError = null;

    await _isar.writeTxn(() async {
      if (existing != null) {
        item.id = existing.id;
      }
      await _isar.syncOutboxItems.put(item);
    });
  }

  Future<List<SyncOutboxItem>> listOldest({int limit = 20}) async {
    return _isar.syncOutboxItems
        .where()
        .sortByCreatedAt()
        .limit(limit)
        .findAll();
  }

  Future<void> markResult(
    SyncOutboxItem item, {
    required bool success,
    String? error,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.syncOutboxItems
          .filter()
          .uuidEqualTo(item.uuid)
          .findFirst();
      if (existing == null) return;
      if (success) {
        await _isar.syncOutboxItems.delete(existing.id);
      } else {
        existing.retryCount = (existing.retryCount) + 1;
        existing.lastTriedAt = DateTime.now();
        existing.lastError = error;
        await _isar.syncOutboxItems.put(existing);
      }
    });
  }

  Future<int> count() async {
    return _isar.syncOutboxItems.where().count();
  }

  Future<SyncOutboxItem?> getOldestWithError() async {
    return _isar.syncOutboxItems
        .filter()
        .lastErrorIsNotNull()
        .sortByLastTriedAt()
        .findFirst();
  }
}

