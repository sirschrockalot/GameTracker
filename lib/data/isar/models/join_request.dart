import 'package:isar/isar.dart';

part 'join_request.g.dart';

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  revoked,
}

/// Requested/assigned role. owner is not requested via join; set on Team.ownerUserId.
enum TeamMemberRole {
  owner,
  coach,
  parent,
}

@collection
class JoinRequest {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String teamId;

  /// Authenticated user ID (internal; security). coachName is display-only.
  late String userId;

  /// Display label only; not used for lookup or security.
  late String coachName;

  /// Optional note from requester; stored when status==pending and kept after approve/reject.
  /// Display only in Pending requests list; do not show in Active Members list.
  String? note;

  @enumerated
  late TeamMemberRole role;

  @enumerated
  late JoinRequestStatus status;

  late DateTime requestedAt;

  DateTime? approvedAt;
  String? approvedByUserId;

  JoinRequest();

  JoinRequest.create({
    required this.uuid,
    required this.teamId,
    required this.userId,
    required this.coachName,
    this.note,
    required this.role,
    this.status = JoinRequestStatus.pending,
    DateTime? requestedAt,
    this.approvedAt,
    this.approvedByUserId,
  }) : requestedAt = requestedAt ?? DateTime.now();
}
