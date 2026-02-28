import '../../data/isar/models/join_request.dart';
import '../../data/isar/models/team.dart';
import 'team_auth.dart';

enum TeamAccessLevel { owner, coach, parent, pending, none }

class TeamAccess {
  const TeamAccess({
    required this.level,
    required this.isActiveMember,
    required this.canManageGames,
    required this.canManageSchedule,
    required this.canManageRoster,
  });

  final TeamAccessLevel level;
  final bool isActiveMember;
  final bool canManageGames;
  final bool canManageSchedule;
  final bool canManageRoster;
}

TeamAccess resolveTeamAccess({
  required Team team,
  required String currentUserId,
  JoinRequest? membership,
}) {
  final isOwner = team.ownerUserId != null && team.ownerUserId == currentUserId;

  JoinRequest? activeMembership;
  JoinRequest? pendingMembership;
  if (membership != null) {
    if (TeamAuth.isActiveMembership(membership.status)) {
      activeMembership = membership;
    } else if (membership.status == JoinRequestStatus.pending) {
      pendingMembership = membership;
    }
    // revoked/rejected: no activeMembership, no pendingMembership -> none
  }

  if (isOwner) {
    return const TeamAccess(
      level: TeamAccessLevel.owner,
      isActiveMember: true,
      canManageGames: true,
      canManageSchedule: true,
      canManageRoster: true,
    );
  }

  if (activeMembership != null &&
      (activeMembership.role == TeamMemberRole.owner ||
          activeMembership.role == TeamMemberRole.coach)) {
    return const TeamAccess(
      level: TeamAccessLevel.coach,
      isActiveMember: true,
      canManageGames: true,
      canManageSchedule: true,
      canManageRoster: true,
    );
  }

  if (activeMembership != null && activeMembership.role == TeamMemberRole.parent) {
    return const TeamAccess(
      level: TeamAccessLevel.parent,
      isActiveMember: true,
      canManageGames: false,
      canManageSchedule: true,
      canManageRoster: false,
    );
  }

  if (pendingMembership != null) {
    return const TeamAccess(
      level: TeamAccessLevel.pending,
      isActiveMember: false,
      canManageGames: false,
      canManageSchedule: false,
      canManageRoster: false,
    );
  }

  return const TeamAccess(
    level: TeamAccessLevel.none,
    isActiveMember: false,
    canManageGames: false,
    canManageSchedule: false,
    canManageRoster: false,
  );
}

