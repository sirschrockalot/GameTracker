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

  /// True if user is owner (by userId or by installId, for teams created before auth completed).
  static bool isOwner(Team team, String userId, [String? installId]) {
    if (team.ownerUserId == null) return false;
    if (team.ownerUserId == userId) return true;
    if (installId != null && installId.isNotEmpty && team.ownerUserId == installId) return true;
    return false;
  }

  /// Can view team: active member (approved) or owner.
  static bool canViewTeam(Team team, String userId, bool isApprovedMember, [String? installId]) {
    return isOwner(team, userId, installId) || isApprovedMember;
  }

  /// Can view schedule: owner or any active (approved) member.
  static bool canViewSchedule(Team team, String userId, JoinRequest? membership, [String? installId]) {
    if (isOwner(team, userId, installId)) return true;
    return membership != null && membership.status == JoinRequestStatus.approved;
  }

  /// Can use coach tools (lineups, awards, game, schedule CRUD): owner or approved coach only.
  static bool canUseCoachTools(Team team, String userId, JoinRequest? membership, [String? installId]) {
    if (isOwner(team, userId, installId)) return true;
    return membership != null &&
        membership.status == JoinRequestStatus.approved &&
        (membership.role == TeamMemberRole.owner || membership.role == TeamMemberRole.coach);
  }

  /// Can manage team: owner only (edit, code, pending, members).
  static bool canManageTeam(Team team, String userId, [String? installId]) {
    return isOwner(team, userId, installId);
  }

  /// Can submit a join request: not already pending and not already active (approved).
  static bool canRequestJoin(bool hasPendingRequest, bool hasApprovedRequest) {
    return !hasPendingRequest && !hasApprovedRequest;
  }

  /// True if [ownerUserId] looks like a Firebase anonymous UID (e.g. 28 chars, no dashes).
  /// Used to migrate teams from Firebase auth to JWT so the same device keeps ownership.
  static bool looksLikeFirebaseUid(String? ownerUserId) {
    if (ownerUserId == null || ownerUserId.isEmpty) return false;
    if (ownerUserId.contains('-')) return false; // UUIDs have dashes
    return ownerUserId.length >= 20 && ownerUserId.length <= 32;
  }
}
