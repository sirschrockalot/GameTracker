import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/join_team_api.dart';
import '../auth/team_members_api.dart';
import '../core/feature_flags.dart';
import '../data/isar/models/join_request.dart';
import '../data/isar/models/team.dart';
import '../data/repositories/join_request_repository.dart';
import '../data/repositories/team_repository.dart';
import '../domain/authorization/join_request_status_mapping.dart';
import '../domain/authorization/team_auth.dart';
import 'current_user_provider.dart';
import 'isar_provider.dart';
import 'teams_provider.dart';

/// Display model for a pending request (local or from server). Used to merge and show in team detail.
class PendingRequestView {
  const PendingRequestView({
    required this.uuid,
    required this.coachName,
    this.note,
    required this.role,
    required this.requestedAt,
    required this.isFromServer,
  });
  final String uuid;
  final String coachName;
  final String? note;
  final TeamMemberRole role;
  final DateTime requestedAt;
  final bool isFromServer;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  return DateTime.tryParse(s);
}

/// Debug: last pending-list fetch count and teamId (server).
final lastPendingListFetchCountProvider = StateProvider<int>((_) => 0);
final lastPendingListFetchTeamIdProvider = StateProvider<String?>((_) => null);

/// All team members from server (GET /teams/:teamId/members). Used to show active members after approving server-side.
final serverTeamMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, teamId) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  if (baseUrl.isEmpty) return [];
  try {
    final client = ref.read(authenticatedHttpClientProvider);
    return listTeamMembers(client, teamId);
  } catch (_) {
    return [];
  }
});

/// Pending requests from server (GET /teams/:teamId/requests) for this team.
/// The backend enforces owner-only access; non-owners will just get an error which we swallow.
final serverPendingRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, teamId) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  if (baseUrl.isEmpty) return [];
  final client = ref.read(authenticatedHttpClientProvider);
  final list = await listPendingRequests(client, teamId);

  ref.read(lastPendingListFetchCountProvider.notifier).state = list.length;
  ref.read(lastPendingListFetchTeamIdProvider.notifier).state = teamId;

  // Upsert pending requests into Isar so local views stay in sync with server.
  final isar = await ref.read(isarProvider.future);
  final currentUserId = ref.read(currentUserIdProvider);
  await isar.writeTxn(() async {
    for (final raw in list) {
      final data = raw;
      final uuid = data['uuid'] as String?;
      final coachName = data['coachName'] as String?;
      final roleStr = data['role'] as String?;
      final statusStr = data['status'] as String? ?? JoinRequestStatusMapping.apiPending;
      if (uuid == null || coachName == null || roleStr == null) continue;

      final existing =
          await JoinRequestRepository(isar).getByUuid(uuid);

      final request = existing ?? JoinRequest();
      if (existing != null) {
        request.id = existing.id;
      }

      request.uuid = uuid;
      request.teamId = (data['teamId'] as String?) ?? teamId;
      request.userId = (data['userId'] as String?) ?? currentUserId;
      request.coachName = coachName;
      request.note = data['note'] as String?;

      final role = roleStr == 'parent' ? TeamMemberRole.parent : TeamMemberRole.coach;
      final mappedStatus =
          JoinRequestStatusMapping.fromApiString(statusStr) ?? JoinRequestStatus.pending;

      request.role = role;
      request.status = mappedStatus;

      final requestedAt = _parseDate(data['requestedAt']);
      final approvedAt = _parseDate(data['approvedAt']);
      final updatedAt = _parseDate(data['updatedAt']);

      request.requestedAt = requestedAt ?? existing?.requestedAt ?? DateTime.now();
      request.approvedAt = approvedAt ?? existing?.approvedAt;
      request.approvedByUserId =
          (data['approvedByUserId'] as String?) ?? existing?.approvedByUserId;
      request.updatedAt = updatedAt ?? DateTime.now();
      request.updatedBy = (data['updatedBy'] as String?) ?? existing?.updatedBy;
      request.deletedAt = _parseDate(data['deletedAt']) ?? existing?.deletedAt;

      await isar.joinRequests.put(request);
    }
  });

  return list;
});

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

/// Merged pending requests: local + server, deduped by uuid (server wins). For owner UI.
final mergedPendingRequestsProvider =
    Provider.family<List<PendingRequestView>, String>((ref, teamId) {
  final localAsync = ref.watch(pendingJoinRequestsProvider(teamId));
  final serverAsync = ref.watch(serverPendingRequestsProvider(teamId));
  final local = localAsync.valueOrNull ?? [];
  final server = serverAsync.valueOrNull ?? [];
  final seen = <String>{};
  final merged = <PendingRequestView>[];
  for (final m in server) {
    final uuid = m['uuid'] as String?;
    if (uuid == null || seen.contains(uuid)) continue;
    seen.add(uuid);
    final roleStr = m['role'] as String?;
    final role = roleStr == 'parent' ? TeamMemberRole.parent : TeamMemberRole.coach;
    final requestedAtStr = m['requestedAt'] as String?;
    final requestedAt = requestedAtStr != null ? DateTime.tryParse(requestedAtStr) : null;
    merged.add(PendingRequestView(
      uuid: uuid,
      coachName: (m['coachName'] as String?) ?? 'Unknown',
      note: m['note'] as String?,
      role: role,
      requestedAt: requestedAt ?? DateTime.now(),
      isFromServer: true,
    ));
  }
  for (final r in local) {
    if (seen.contains(r.uuid)) continue;
    seen.add(r.uuid);
    merged.add(PendingRequestView(
      uuid: r.uuid,
      coachName: r.coachName,
      note: r.note,
      role: r.role,
      requestedAt: r.requestedAt,
      isFromServer: false,
    ));
  }
  merged.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  return merged;
});

final pendingJoinRequestsProvider =
    StreamProvider.family<List<JoinRequest>, String>((ref, teamId) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return JoinRequestRepository(isar).watchPendingByTeamId(teamId);
});

final approvedMembersProvider =
    StreamProvider.family<List<JoinRequest>, String>((ref, teamId) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return JoinRequestRepository(isar).watchApprovedByTeamId(teamId);
});

/// Effective membership for a user on a team (for role-based routing).
class UserTeamMembership {
  const UserTeamMembership({
    this.team,
    required this.isOwner,
    this.membership,
  });
  final Team? team;
  final bool isOwner;
  final JoinRequest? membership;
}

final userTeamMembershipProvider =
    FutureProvider.family<UserTeamMembership, String>((ref, teamUuid) async {
  final isar = await ref.watch(isarProvider.future);
  final userId = ref.watch(currentUserIdProvider);
  final installId = ref.watch(installIdProvider).valueOrNull;
  final teamRepo = TeamRepository(isar);
  final joinRepo = JoinRequestRepository(isar);
  final team = await teamRepo.getByUuid(teamUuid);
  final isOwner = team != null && TeamAuth.isOwner(team, userId, installId);
  final membership = team != null
      ? await joinRepo.getEffectiveMembership(team.uuid, userId)
      : null;
  return UserTeamMembership(team: team, isOwner: isOwner, membership: membership);
});

/// True if the current user can access coach-only routes (has at least one team where they can use coach tools).
final canAccessCoachNavProvider = FutureProvider<bool>((ref) async {
  // Before auth/membership v2, always allow coach nav (single-user coach app).
  if (!FeatureFlags.enableMembershipAuthV2) return true;

  final isar = await ref.watch(isarProvider.future);
  final userId = ref.watch(currentUserIdProvider);
  final installId = ref.watch(installIdProvider).valueOrNull;
  final teams = await TeamRepository(isar).getAll();
  final joinRepo = JoinRequestRepository(isar);
  for (final team in teams) {
    final membership = await joinRepo.getEffectiveMembership(team.uuid, userId);
    if (TeamAuth.canUseCoachTools(team, userId, membership, installId)) return true;
  }
  return false;
});
