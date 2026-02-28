import 'package:isar/isar.dart';

import '../repositories/game_repository.dart';
import '../repositories/team_repository.dart';
import '../isar/models/join_request.dart';
import '../../domain/authorization/join_request_status_mapping.dart';
import '../../auth/api_client.dart';
import '../../auth/game_api.dart';
import '../../auth/sync_api.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  return DateTime.tryParse(s);
}

/// Upsert membership rows from sync/pull teamMembers into Isar (so revoke deltas apply).
Future<void> _upsertTeamMembersFromPull(Isar isar, List<dynamic> teamMembers) async {
  if (teamMembers.isEmpty) return;
  await isar.writeTxn(() async {
    for (final data in teamMembers) {
      final m = data as Map<String, dynamic>?;
      if (m == null) continue;
      final uuid = m['uuid'] as String?;
      final teamId = m['teamId'] as String?;
      final userId = m['userId'] as String?;
      final coachName = m['coachName'] as String?;
      final roleStr = m['role'] as String?;
      final statusStr = m['status'] as String? ?? 'pending';
      if (uuid == null || teamId == null || userId == null || coachName == null || roleStr == null) continue;
      final role = roleStr == 'owner' ? TeamMemberRole.owner : (roleStr == 'parent' ? TeamMemberRole.parent : TeamMemberRole.coach);
      final status = JoinRequestStatusMapping.fromApiString(statusStr) ?? JoinRequestStatus.pending;
      final existing = await isar.joinRequests.filter().uuidEqualTo(uuid).findFirst();
      final jr = existing ?? JoinRequest();
      if (existing != null) jr.id = existing.id;
      jr.uuid = uuid;
      jr.teamId = teamId;
      jr.userId = userId;
      jr.coachName = coachName;
      jr.note = m['note'] as String?;
      jr.role = role;
      jr.status = status;
      jr.requestedAt = _parseDate(m['requestedAt']) ?? jr.requestedAt;
      jr.approvedAt = _parseDate(m['approvedAt']) ?? jr.approvedAt;
      jr.approvedByUserId = m['approvedByUserId'] as String? ?? jr.approvedByUserId;
      jr.updatedAt = _parseDate(m['updatedAt']) ?? DateTime.now();
      jr.updatedBy = m['updatedBy'] as String? ?? jr.updatedBy;
      jr.deletedAt = _parseDate(m['deletedAt']) ?? jr.deletedAt;
      await isar.joinRequests.put(jr);
    }
  });
}

/// Push local games to the server for all teams that have sync enabled.
/// Use so game history appears in the DB (e.g. after enabling sync or if upsert failed at start).
Future<void> pushLocalGamesToServer(
  AuthenticatedHttpClient client,
  Isar isar,
) async {
  final teamRepo = TeamRepository(isar);
  final gameRepo = GameRepository(isar);
  final teams = await teamRepo.getAll();
  final syncedTeams = teams.where((t) => t.syncEnabled == true).toList();
  for (final team in syncedTeams) {
    final games = await gameRepo.listByTeamId(team.uuid);
    for (final game in games) {
      try {
        final payload = {
          'uuid': game.uuid,
          'teamId': game.teamId ?? team.uuid,
          'startedAt': game.startedAt.toIso8601String(),
          'quarterLineupsJson': game.quarterLineupsJson,
          'completedQuartersJson': game.completedQuartersJson,
          'awardsJson': game.awardsJson,
          'schemaVersion': game.schemaVersion,
        };
        await upsertGame(client, team.uuid, payload);
      } catch (_) {}
    }
  }
}

/// Pull sync (games only) and upsert into Isar. Use since to avoid re-downloading all.
/// quartersPlayedJson is recomputed from quarterLineups (never stored from server).
Future<void> pullGamesIntoIsar(
  AuthenticatedHttpClient client,
  Isar isar, {
  DateTime? since,
}) async {
  final response = await pullSync(client, since: since ?? DateTime(0));
  final teamMembers = response['teamMembers'] as List<dynamic>? ?? [];
  await _upsertTeamMembersFromPull(isar, teamMembers);
  final games = response['games'] as List<dynamic>? ?? [];
  final repo = GameRepository(isar);
  for (final g in games) {
    final m = g as Map<String, dynamic>;
    if (m['uuid'] != null) await repo.upsertFromServerGame(m);
  }
}
