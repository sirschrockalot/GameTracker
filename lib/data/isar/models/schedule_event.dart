import 'package:isar/isar.dart';

part 'schedule_event.g.dart';

enum ScheduleEventType {
  practice,
  game,
}

@collection
class ScheduleEvent {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String teamId;

  @enumerated
  late ScheduleEventType type;

  late DateTime startsAt;

  DateTime? endsAt;

  String? location;

  /// Opponent name; typically used when type == game.
  String? opponent;

  String? notes;

  late DateTime createdAt;

  late DateTime updatedAt;

  /// User ID of last updater (cloud-ready).
  String? updatedByUserId;

  /// Soft delete for sync (cloud-ready).
  DateTime? deletedAt;

  /// Schema version for migrations (cloud-ready).
  late int schemaVersion;

  ScheduleEvent();

  ScheduleEvent.create({
    required this.uuid,
    required this.teamId,
    required this.type,
    required this.startsAt,
    this.endsAt,
    this.location,
    this.opponent,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.updatedByUserId,
    this.deletedAt,
    this.schemaVersion = 1,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
