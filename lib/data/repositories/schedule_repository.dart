import 'package:isar/isar.dart';

import '../isar/models/schedule_event.dart';

class ScheduleRepository {
  ScheduleRepository(this._isar);

  final Isar _isar;

  Future<ScheduleEvent?> getByUuid(String uuid) async {
    return _isar.scheduleEvents
        .filter()
        .uuidEqualTo(uuid)
        .deletedAtIsNull()
        .findFirst();
  }

  /// Events for a team (excluding soft-deleted), ascending by startsAt.
  Future<List<ScheduleEvent>> listByTeamId(String teamId) async {
    return _isar.scheduleEvents
        .filter()
        .teamIdEqualTo(teamId)
        .deletedAtIsNull()
        .sortByStartsAt()
        .findAll();
  }

  /// Stream of events for a team (local-first reactive).
  Stream<List<ScheduleEvent>> watchByTeamId(String teamId) {
    return _isar.scheduleEvents
        .filter()
        .teamIdEqualTo(teamId)
        .deletedAtIsNull()
        .sortByStartsAt()
        .watch(fireImmediately: true);
  }

  /// Upcoming events (startsAt >= [from]), for a team.
  Future<List<ScheduleEvent>> listUpcomingByTeamId(
    String teamId,
    DateTime from,
  ) async {
    final inclusive = from.subtract(const Duration(milliseconds: 1));
    return _isar.scheduleEvents
        .filter()
        .teamIdEqualTo(teamId)
        .deletedAtIsNull()
        .startsAtGreaterThan(inclusive)
        .sortByStartsAt()
        .findAll();
  }

  Future<String> add(ScheduleEvent event) => _isar.writeTxn(() async {
        final existing = await _isar.scheduleEvents
            .filter()
            .uuidEqualTo(event.uuid)
            .findFirst();
        if (existing != null) {
          event.id = existing.id;
        }
        await _isar.scheduleEvents.put(event);
        return event.uuid;
      });

  Future<void> update(ScheduleEvent event, {String? updatedByUserId}) async {
    event.updatedAt = DateTime.now();
    if (updatedByUserId != null) event.updatedByUserId = updatedByUserId;
    await _isar.writeTxn(() async {
      if (event.id == Isar.autoIncrement) {
        final existing = await _isar.scheduleEvents
            .filter()
            .uuidEqualTo(event.uuid)
            .findFirst();
        if (existing != null) event.id = existing.id;
      }
      await _isar.scheduleEvents.put(event);
    });
  }

  /// Soft delete (cloud-ready: set deletedAt).
  Future<void> softDelete(ScheduleEvent event, {String? deletedByUserId}) async {
    event.deletedAt = DateTime.now();
    event.updatedAt = DateTime.now();
    if (deletedByUserId != null) event.updatedByUserId = deletedByUserId;
    await _isar.writeTxn(() async {
      if (event.id == Isar.autoIncrement) {
        final existing = await _isar.scheduleEvents
            .filter()
            .uuidEqualTo(event.uuid)
            .findFirst();
        if (existing != null) event.id = existing.id;
      }
      await _isar.scheduleEvents.put(event);
    });
  }

  /// Hard delete (removes from DB).
  Future<bool> deleteByUuid(String uuid) => _isar.writeTxn(() async {
        final e = await _isar.scheduleEvents
            .filter()
            .uuidEqualTo(uuid)
            .findFirst();
        if (e == null) return false;
        await _isar.scheduleEvents.delete(e.id);
        return true;
      });
}
