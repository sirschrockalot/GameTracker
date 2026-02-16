import 'package:isar/isar.dart';

import '../../../core/team_code_generator.dart';

part 'team.g.dart';

@collection
class Team {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;

  /// UUIDs of players assigned to this team.
  late List<String> playerIds;

  /// 6–8 char uppercase code (no 0,O,1,I). Lookup by this for "Join Team".
  late String inviteCode;

  /// When the owner last rotated the code; re-request after reject is allowed if set and after this time.
  DateTime? inviteCodeRotatedAt;

  /// Coach join code (6–8 chars, uppercase, exclude 0,O,1,I). Owner only can rotate.
  late String coachCode;

  DateTime? coachCodeRotatedAt;

  /// Parent join code (same format). Owner only can rotate.
  late String parentCode;

  DateTime? parentCodeRotatedAt;

  /// Authenticated user ID of the team owner (internal; used for approval).
  String? ownerUserId;

  late DateTime createdAt;

  Team();

  Team.create({
    required this.uuid,
    required this.name,
    List<String>? playerIds,
    String? inviteCode,
    String? coachCode,
    String? parentCode,
    this.ownerUserId,
    DateTime? createdAt,
  })  : playerIds = playerIds ?? [],
        inviteCode = inviteCode ?? TeamCodeGenerator.generate(),
        coachCode = coachCode ?? TeamCodeGenerator.generate(),
        parentCode = parentCode ?? TeamCodeGenerator.generate(),
        createdAt = createdAt ?? DateTime.now();
}
