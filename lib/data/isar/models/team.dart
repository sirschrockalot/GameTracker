import 'package:isar/isar.dart';

part 'team.g.dart';

@collection
class Team {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;

  /// UUIDs of players assigned to this team.
  late List<String> playerIds;

  late DateTime createdAt;

  Team();

  Team.create({
    required this.uuid,
    required this.name,
    List<String>? playerIds,
    DateTime? createdAt,
  })  : playerIds = playerIds ?? [],
        createdAt = createdAt ?? DateTime.now();
}
