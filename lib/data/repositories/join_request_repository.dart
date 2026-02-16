import 'package:isar/isar.dart';

import '../../domain/validation/join_request_validators.dart';
import '../isar/models/join_request.dart';

class JoinRequestRepository {
  JoinRequestRepository(this._isar);

  final Isar _isar;

  Future<JoinRequest?> getByUuid(String uuid) async {
    return _isar.joinRequests.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> add(JoinRequest request) async {
    final coachName = JoinRequestValidators.enforceCoachNameForPersist(request.coachName);
    if (coachName.length < JoinRequestValidators.coachNameMinLength) {
      throw ArgumentError('coachName must be at least ${JoinRequestValidators.coachNameMinLength} characters after sanitization');
    }
    request.coachName = coachName;
    request.note = JoinRequestValidators.enforceNoteForPersist(request.note);
    await _isar.writeTxn(() async {
      await _isar.joinRequests.put(request);
    });
  }

  Future<List<JoinRequest>> listPendingByTeamId(String teamId) async {
    return _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .statusEqualTo(JoinRequestStatus.pending)
        .sortByRequestedAtDesc()
        .findAll();
  }

  Stream<List<JoinRequest>> watchPendingByTeamId(String teamId) {
    return _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .statusEqualTo(JoinRequestStatus.pending)
        .sortByRequestedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<void> approve(String requestUuid, String approvedByUserId) async {
    await _isar.writeTxn(() async {
      final r = await _isar.joinRequests.filter().uuidEqualTo(requestUuid).findFirst();
      if (r == null) return;
      r.status = JoinRequestStatus.approved;
      r.approvedAt = DateTime.now();
      r.approvedByUserId = approvedByUserId;
      await _isar.joinRequests.put(r);
    });
  }

  Future<void> reject(String requestUuid) async {
    await _isar.writeTxn(() async {
      final r = await _isar.joinRequests.filter().uuidEqualTo(requestUuid).findFirst();
      if (r == null) return;
      r.status = JoinRequestStatus.rejected;
      await _isar.joinRequests.put(r);
    });
  }

  Future<void> revoke(String requestUuid) async {
    await _isar.writeTxn(() async {
      final r = await _isar.joinRequests.filter().uuidEqualTo(requestUuid).findFirst();
      if (r == null) return;
      r.status = JoinRequestStatus.revoked;
      await _isar.joinRequests.put(r);
    });
  }

  Future<List<JoinRequest>> listApprovedByTeamId(String teamId) async {
    return _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .statusEqualTo(JoinRequestStatus.approved)
        .sortByApprovedAtDesc()
        .findAll();
  }

  Stream<List<JoinRequest>> watchApprovedByTeamId(String teamId) {
    return _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .statusEqualTo(JoinRequestStatus.approved)
        .sortByApprovedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Whether this user already has a pending request for this team.
  Future<bool> hasPendingRequest(String teamId, String userId) async {
    return _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .userIdEqualTo(userId)
        .statusEqualTo(JoinRequestStatus.pending)
        .findFirst()
        .then((r) => r != null);
  }

  /// Whether this user already has a pending request for this team and role (dedupe per team/user/role).
  Future<bool> hasPendingRequestForTeamAndRole(
    String teamId,
    String userId,
    TeamMemberRole role,
  ) async {
    return _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .userIdEqualTo(userId)
        .roleEqualTo(role)
        .statusEqualTo(JoinRequestStatus.pending)
        .findFirst()
        .then((r) => r != null);
  }

  /// Whether this user has an approved request (active member) for this team.
  Future<bool> hasApprovedRequest(String teamId, String userId) async {
    return _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .userIdEqualTo(userId)
        .statusEqualTo(JoinRequestStatus.approved)
        .findFirst()
        .then((r) => r != null);
  }

  /// Effective membership for routing: approved if any, else pending, else latest rejected/revoked.
  Future<JoinRequest?> getEffectiveMembership(String teamId, String userId) async {
    final approved = await _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .userIdEqualTo(userId)
        .statusEqualTo(JoinRequestStatus.approved)
        .findFirst();
    if (approved != null) return approved;
    final pending = await _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .userIdEqualTo(userId)
        .statusEqualTo(JoinRequestStatus.pending)
        .findFirst();
    if (pending != null) return pending;
    return getLatestRejectedOrRevokedRequest(teamId, userId);
  }

  /// Latest rejected or revoked request for this team by this user (for cooldown / rotation check).
  Future<JoinRequest?> getLatestRejectedOrRevokedRequest(String teamId, String userId) async {
    final rejected = await _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .userIdEqualTo(userId)
        .statusEqualTo(JoinRequestStatus.rejected)
        .sortByRequestedAtDesc()
        .findFirst();
    final revoked = await _isar.joinRequests
        .filter()
        .teamIdEqualTo(teamId)
        .userIdEqualTo(userId)
        .statusEqualTo(JoinRequestStatus.revoked)
        .sortByRequestedAtDesc()
        .findFirst();
    if (rejected == null) return revoked;
    if (revoked == null) return rejected;
    return rejected.requestedAt.isAfter(revoked.requestedAt) ? rejected : revoked;
  }
}
