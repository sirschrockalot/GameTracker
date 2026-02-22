import 'package:flutter_test/flutter_test.dart';
import 'package:upward_lineup/data/isar/models/join_request.dart';
import 'package:upward_lineup/domain/authorization/join_request_status_mapping.dart';

void main() {
  group('JoinRequestStatusMapping', () {
    test('toApiString maps approved to active', () {
      expect(JoinRequestStatusMapping.toApiString(JoinRequestStatus.approved), 'active');
    });
    test('toApiString maps pending/rejected/revoked 1:1', () {
      expect(JoinRequestStatusMapping.toApiString(JoinRequestStatus.pending), 'pending');
      expect(JoinRequestStatusMapping.toApiString(JoinRequestStatus.rejected), 'rejected');
      expect(JoinRequestStatusMapping.toApiString(JoinRequestStatus.revoked), 'revoked');
    });
    test('fromApiString maps active to approved', () {
      expect(JoinRequestStatusMapping.fromApiString('active'), JoinRequestStatus.approved);
    });
    test('fromApiString maps pending/rejected/revoked 1:1', () {
      expect(JoinRequestStatusMapping.fromApiString('pending'), JoinRequestStatus.pending);
      expect(JoinRequestStatusMapping.fromApiString('rejected'), JoinRequestStatus.rejected);
      expect(JoinRequestStatusMapping.fromApiString('revoked'), JoinRequestStatus.revoked);
    });
    test('round-trip approved <-> active', () {
      expect(
        JoinRequestStatusMapping.fromApiString(
          JoinRequestStatusMapping.toApiString(JoinRequestStatus.approved),
        ),
        JoinRequestStatus.approved,
      );
    });
    test('unknown API string returns null', () {
      expect(JoinRequestStatusMapping.fromApiString('unknown'), isNull);
    });
  });
}
