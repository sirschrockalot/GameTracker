import 'package:isar/isar.dart';

import '../auth/api_client.dart';
import '../auth/memberships_api.dart';
import '../data/isar/models/join_request.dart';
import '../domain/authorization/join_request_status_mapping.dart';
import '../repositories/game_repository.dart';
import '../repositories/join_request_repository.dart';
import '../repositories/player_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/team_repository.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  return DateTime.tryParse(s);
}

/// Single source for membership sync: fetches /me/memberships, upserts into Isar,
/// computes allowedTeamIds, and cleans up local data for revoked teams.
class MembershipSyncService {
  MembershipSyncService({
    required this.isar,
    required this.currentUserId,
  });

  final Isar isar;
  final String currentUserId;

  /// Call on app launch and foreground. Fetches memberships, upserts, removes revoked teams from device.
  static Future<void> refresh(
    AuthenticatedHttpClient client,
    Isar isar,
    String currentUserId,
  ) async {
    final joinRepo = JoinRequestRepository(isar);
    final teamRepo = TeamRepository(isar);
    final playerRepo = PlayerRepository(isar);
    final scheduleRepo = ScheduleRepository(isar);
    final gameRepo = GameRepository(isar);

    final previousAllowed = await _computeAllowedTeamIds(isar, currentUserId, teamRepo, joinRepo);

    List<Map<String, dynamic>> list;
    try {
      list = await fetchMyMemberships(client);
    } catch (_) {
      return;
    }

    await isar.writeTxn(() async {
      for (final data in list) {
        final uuid = data['uuid'] as String?;
        final teamId = data['teamId'] as String?;
        final userId = data['userId'] as String?;
        final coachName = data['coachName'] as String?;
        final roleStr = data['role'] as String?;
        final statusStr = data['status'] as String? ?? 'pending';
        if (uuid == null || teamId == null || userId == null || coachName == null || roleStr == null) continue;

        final role = roleStr == 'owner'
            ? TeamMemberRole.owner
            : (roleStr == 'parent' ? TeamMemberRole.parent : TeamMemberRole.coach);
        final status = JoinRequestStatusMapping.fromApiString(statusStr) ?? JoinRequestStatus.pending;

        final existing = await joinRepo.getByUuid(uuid);
        final jr = existing ?? JoinRequest();
        if (existing != null) jr.id = existing.id;

        jr.uuid = uuid;
        jr.teamId = teamId;
        jr.userId = userId;
        jr.coachName = coachName;
        jr.note = data['note'] as String?;
        jr.role = role;
        jr.status = status;
        jr.requestedAt = _parseDate(data['requestedAt']) ?? jr.requestedAt;
        jr.approvedAt = _parseDate(data['approvedAt']) ?? jr.approvedAt;
        jr.approvedByUserId = data['approvedByUserId'] as String? ?? jr.approvedByUserId;
        jr.updatedAt = _parseDate(data['updatedAt']) ?? DateTime.now();
        jr.updatedBy = data['updatedBy'] as String? ?? jr.updatedBy;
        jr.deletedAt = _parseDate(data['deletedAt']) ?? jr.deletedAt;

        await isar.joinRequests.put(jr);
      }
    });

    final newAllowed = await _computeAllowedTeamIds(isar, currentUserId, teamRepo, joinRepo);
    final removed = previousAllowed.difference(newAllowed);

    for (final teamId in removed) {
      await playerRepo.deleteAllByTeamId(teamId);
      await scheduleRepo.deleteAllByTeamId(teamId);
      await gameRepo.deleteAllByTeamId(teamId);
      await teamRepo.deleteByUuid(teamId);
    }
  }

  static Future<Set<String>> _computeAllowedTeamIds(
    Isar isar,
    String userId,
    TeamRepository teamRepo,
    JoinRequestRepository joinRepo,
  ) async {
    final approved = await joinRepo.listApprovedTeamIdsForUser(userId);
    final teams = await teamRepo.getAll();
    final ownerIds = teams
        .where((t) => t.ownerUserId != null && t.ownerUserId == userId)
        .map((t) => t.uuid)
        .toList();
    return {...approved, ...ownerIds};
  }

  /// Compute allowed team IDs (active membership or owner). Used by providers.
  static Future<Set<String>> getAllowedTeamIds(
    Isar isar,
    String userId,
    TeamRepository teamRepo,
    JoinRequestRepository joinRepo,
  ) async {
    return _computeAllowedTeamIds(isar, userId, teamRepo, joinRepo);
  }
}
