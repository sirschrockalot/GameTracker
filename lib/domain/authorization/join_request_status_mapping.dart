import '../../data/isar/models/join_request.dart';

/// Maps local [JoinRequestStatus] to/from backend API status string.
/// Backend uses "active"; local enum uses [JoinRequestStatus.approved].
/// All authorization treats approved == active membership.
class JoinRequestStatusMapping {
  JoinRequestStatusMapping._();

  static const String apiActive = 'active';
  static const String apiPending = 'pending';
  static const String apiRejected = 'rejected';
  static const String apiRevoked = 'revoked';

  /// Local status to API string. approved -> "active".
  static String toApiString(JoinRequestStatus status) {
    switch (status) {
      case JoinRequestStatus.pending:
        return apiPending;
      case JoinRequestStatus.approved:
        return apiActive;
      case JoinRequestStatus.rejected:
        return apiRejected;
      case JoinRequestStatus.revoked:
        return apiRevoked;
    }
  }

  /// API string to local status. "active" -> approved.
  static JoinRequestStatus? fromApiString(String value) {
    switch (value) {
      case apiActive:
        return JoinRequestStatus.approved;
      case apiPending:
        return JoinRequestStatus.pending;
      case apiRejected:
        return JoinRequestStatus.rejected;
      case apiRevoked:
        return JoinRequestStatus.revoked;
      default:
        return null;
    }
  }
}
