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

  late DateTime createdAt;

  Player();

  Player.create({
    required this.uuid,
    required this.name,
    this.skill = Skill.developing,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
