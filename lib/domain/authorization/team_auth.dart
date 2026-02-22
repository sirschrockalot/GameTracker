import '../../data/isar/models/join_request.dart';
import '../../data/isar/models/team.dart';

/// Phase 2 authorization helpers. Wire UI visibility/enabled to these.
/// "Active membership" = local [JoinRequestStatus.approved] = API "active" (see [JoinRequestStatusMapping]).
class TeamAuth {
  TeamAuth._();

  /// True if status represents active membership (API "active"). Use for auth and API mapping.
  static bool isActiveMembership(JoinRequestStatus status) {
    return status == JoinRequestStatus.approved;
  }

  /// Can view team: active member (approved) or owner.
  static bool canViewTeam(Team team, String userId, bool isApprovedMember) {
    final isOwner = team.ownerUserId != null && team.ownerUserId == userId;
    return isOwner || isApprovedMember;
  }

  /// Can view schedule: owner or any active (approved) member.
  static bool canViewSchedule(Team team, String userId, JoinRequest? membership) {
    if (team.ownerUserId == userId) return true;
    return membership != null && membership.status == JoinRequestStatus.approved;
  }

  /// Can use coach tools (lineups, awards, game, schedule CRUD): owner or approved coach only.
  static bool canUseCoachTools(Team team, String userId, JoinRequest? membership) {
    if (team.ownerUserId == userId) return true;
    return membership != null &&
        membership.status == JoinRequestStatus.approved &&
        (membership.role == TeamMemberRole.owner || membership.role == TeamMemberRole.coach);
  }

  /// Can manage team: owner only (edit, code, pending, members).
  static bool canManageTeam(Team team, String userId) {
    return team.ownerUserId != null && team.ownerUserId == userId;
  }

  /// Can submit a join request: not already pending and not already active (approved).
  static bool canRequestJoin(bool hasPendingRequest, bool hasApprovedRequest) {
    return !hasPendingRequest && !hasApprovedRequest;
  }
}
