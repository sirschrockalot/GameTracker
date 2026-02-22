import 'package:isar/isar.dart';

import '../../core/team_code_generator.dart';
import '../isar/models/team.dart';

class TeamRepository {
  TeamRepository(this._isar);

  final Isar _isar;

  Future<Team?> getByUuid(String uuid) async {
    return _isar.teams.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Look up team by invite code (case-insensitive for display).
  Future<Team?> getByInviteCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _isar.teams.filter().inviteCodeEqualTo(normalized).findFirst();
  }

  /// Look up team by coach code (case-insensitive).
  Future<Team?> getByCoachCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _isar.teams.filter().coachCodeEqualTo(normalized).findFirst();
  }

  /// Look up team by parent code (case-insensitive).
  Future<Team?> getByParentCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _isar.teams.filter().parentCodeEqualTo(normalized).findFirst();
  }

  Future<List<Team>> getAll() async {
    return _isar.teams.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<Team>> watchAll() {
    return _isar.teams.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  Future<String> add(Team team) => _isar.writeTxn(() async {
        final existing = await _isar.teams
            .filter()
            .uuidEqualTo(team.uuid)
            .findFirst();
        if (existing != null) {
          team.id = existing.id;
        }
        team.updatedAt = DateTime.now();
        await _isar.teams.put(team);
        return team.uuid;
      });

  Future<void> update(Team team, {String? updatedBy}) => _isar.writeTxn(() async {
        if (team.id == Isar.autoIncrement) {
          final existing = await _isar.teams
              .filter()
              .uuidEqualTo(team.uuid)
              .findFirst();
          if (existing != null) {
            team.id = existing.id;
          }
        }
        team.updatedAt = DateTime.now();
        if (updatedBy != null) team.updatedBy = updatedBy;
        await _isar.teams.put(team);
      });

  Future<bool> deleteByUuid(String uuid) => _isar.writeTxn(() async {
        final t = await _isar.teams.filter().uuidEqualTo(uuid).findFirst();
        if (t == null) return false;
        await _isar.teams.delete(t.id);
        return true;
      });

  /// Rotate invite code to a new 6–8 char code. Does not affect existing members or join requests.
  Future<String?> rotateInviteCode(String teamUuid) async {
    final team = await getByUuid(teamUuid);
    if (team == null) return null;
    var code = TeamCodeGenerator.generate();
    for (var i = 0; i < 20; i++) {
      final existing = await getByInviteCode(code);
      if (existing == null || existing.uuid == teamUuid) break;
      code = TeamCodeGenerator.generate();
    }
    team.inviteCode = code;
    team.inviteCodeRotatedAt = DateTime.now();
    await update(team);
    return code;
  }

  /// Rotate coach code (owner only). Ensures uniqueness across teams.
  Future<String?> rotateCoachCode(String teamUuid) async {
    final team = await getByUuid(teamUuid);
    if (team == null) return null;
    var code = TeamCodeGenerator.generate();
    for (var i = 0; i < 20; i++) {
      final existing = await getByCoachCode(code);
      if (existing == null || existing.uuid == teamUuid) break;
      code = TeamCodeGenerator.generate();
    }
    team.coachCode = code;
    team.coachCodeRotatedAt = DateTime.now();
    await update(team);
    return code;
  }

  /// Rotate parent code (owner only). Ensures uniqueness across teams.
  Future<String?> rotateParentCode(String teamUuid) async {
    final team = await getByUuid(teamUuid);
    if (team == null) return null;
    var code = TeamCodeGenerator.generate();
    for (var i = 0; i < 20; i++) {
      final existing = await getByParentCode(code);
      if (existing == null || existing.uuid == teamUuid) break;
      code = TeamCodeGenerator.generate();
    }
    team.parentCode = code;
    team.parentCodeRotatedAt = DateTime.now();
    await update(team);
    return code;
  }
}
