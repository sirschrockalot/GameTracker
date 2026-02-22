import '../isar/models/player.dart';
import '../isar/models/schedule_event.dart';
import 'package:isar/isar.dart';

import '../repositories/player_repository.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  final d = DateTime.tryParse(s);
  return d;
}

/// Upsert server bootstrap response into Isar (players and scheduleEvents by uuid).
Future<void> upsertBootstrapResponse(Isar isar, Map<String, dynamic> response) async {
  final playerRepo = PlayerRepository(isar);
  final players = response['players'] as List<dynamic>? ?? [];
  final events = response['scheduleEvents'] as List<dynamic>? ?? [];
  await isar.writeTxn(() async {
    for (final p in players) {
      final m = p as Map<String, dynamic>;
      final uuid = m['uuid'] as String?;
      if (uuid == null) continue;
      final skillStr = m['skill'] as String? ?? 'developing';
      final skill = skillStr == 'strong' ? Skill.strong : Skill.developing;
      final createdAt = _parseDate(m['createdAt']) ?? DateTime.now();
      final updatedAt = _parseDate(m['updatedAt']) ?? DateTime.now();
      final player = Player()
        ..uuid = uuid
        ..teamId = m['teamId'] as String?
        ..name = m['name'] as String? ?? ''
        ..skill = skill
        ..createdAt = createdAt
        ..updatedAt = updatedAt
        ..updatedBy = m['updatedBy'] as String?
        ..deletedAt = _parseDate(m['deletedAt'])
        ..schemaVersion = m['schemaVersion'] as int? ?? 1;
      final existing = await playerRepo.getByUuid(uuid);
      if (existing != null) player.id = existing.id;
      await isar.players.put(player);
    }
    for (final e in events) {
      final m = e as Map<String, dynamic>;
      final uuid = m['uuid'] as String?;
      if (uuid == null) continue;
      final typeStr = m['type'] as String? ?? 'practice';
      final type = typeStr == 'game' ? ScheduleEventType.game : ScheduleEventType.practice;
      final startsAt = _parseDate(m['startsAt']) ?? DateTime.now();
      final updatedAt = _parseDate(m['updatedAt']) ?? DateTime.now();
      final event = ScheduleEvent()
        ..uuid = uuid
        ..teamId = m['teamId'] as String? ?? ''
        ..type = type
        ..startsAt = startsAt
        ..endsAt = _parseDate(m['endsAt'])
        ..location = m['location'] as String?
        ..opponent = m['opponent'] as String?
        ..notes = m['notes'] as String?
        ..createdAt = updatedAt
        ..updatedAt = updatedAt
        ..updatedByUserId = m['updatedBy'] as String?
        ..deletedAt = _parseDate(m['deletedAt'])
        ..schemaVersion = m['schemaVersion'] as int? ?? 1;
      final existing = await isar.scheduleEvents.filter().uuidEqualTo(uuid).findFirst();
      if (existing != null) event.id = existing.id;
      await isar.scheduleEvents.put(event);
    }
  });
}
