import 'package:isar/isar.dart';

part 'player.g.dart';

enum Skill {
  strong,
  developing,
}

@collection
class Player {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;

  @enumerated
  late Skill skill;

  /// Team UUID this player belongs to (for multi-coach sync).
  String? teamId;

  late DateTime createdAt;

  late DateTime updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  late int schemaVersion;

  Player();

  Player.create({
    required this.uuid,
    required this.name,
    this.skill = Skill.developing,
    this.teamId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.updatedBy,
    this.deletedAt,
    int schemaVersion = 1,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        schemaVersion = schemaVersion;
}
