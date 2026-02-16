import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isar/models/join_request.dart';
import '../data/isar/models/team.dart';
import '../domain/authorization/team_auth.dart';
import '../data/repositories/join_request_repository.dart';
import '../data/repositories/team_repository.dart';
import '../core/feature_flags.dart';
import 'current_user_provider.dart';
import 'isar_provider.dart';

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
  final teamRepo = TeamRepository(isar);
  final joinRepo = JoinRequestRepository(isar);
  final team = await teamRepo.getByUuid(teamUuid);
  final isOwner = team?.ownerUserId == userId;
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
  final teams = await TeamRepository(isar).getAll();
  final joinRepo = JoinRequestRepository(isar);
  for (final team in teams) {
    final membership = await joinRepo.getEffectiveMembership(team.uuid, userId);
    if (TeamAuth.canUseCoachTools(team, userId, membership)) return true;
  }
  return false;
});
