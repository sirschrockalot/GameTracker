import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/bootstrap_api.dart';
import '../data/isar/models/join_request.dart';
import '../data/isar/models/team.dart';
import '../data/repositories/join_request_repository.dart';
import '../data/repositories/team_repository.dart';
import '../domain/authorization/join_request_status_mapping.dart';
import 'current_user_provider.dart';
import 'isar_provider.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  return DateTime.tryParse(s);
}

/// Local teams stream (Isar-backed). UI should treat this as cached view;
/// server is the source of truth for membership and team list.
final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return TeamRepository(isar).watchAll();
});

/// Debug: last successful /teams refresh time from server.
final lastTeamsRefreshTimeProvider = StateProvider<DateTime?>((_) => null);

/// Refresh teams from backend for the current user and upsert into Isar.
/// Also promotes local pending membership to approved when server lists a team.
final refreshTeamsFromServerProvider = FutureProvider<void>((ref) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  if (baseUrl.isEmpty) return;

  final client = ref.read(authenticatedHttpClientProvider);
  final isar = await ref.read(isarProvider.future);
  final currentUserId = ref.read(currentUserIdProvider);
  final teamMaps = await listCloudTeams(client);

  await isar.writeTxn(() async {
    final teamRepo = TeamRepository(isar);
    final joinRepo = JoinRequestRepository(isar);
    for (final raw in teamMaps) {
      final data = raw;
      final uuid = data['uuid'] as String?;
      final name = data['name'] as String?;
      if (uuid == null || name == null) continue;

      final existing = await teamRepo.getByUuid(uuid);

      final team = existing ??
          Team.create(
            uuid: uuid,
            name: name,
            inviteCode: data['inviteCode'] as String?,
            coachCode: data['coachCode'] as String?,
            parentCode: data['parentCode'] as String?,
            ownerUserId: data['ownerUserId'] as String?,
            createdAt: _parseDate(data['createdAt']),
            logoKind: data['logoKind'] as String?,
            updatedAt: _parseDate(data['updatedAt']),
            updatedBy: data['updatedBy'] as String?,
            deletedAt: _parseDate(data['deletedAt']),
            schemaVersion: data['schemaVersion'] as int? ?? 1,
          );

      if (existing != null) {
        team.name = name;
        final inviteCode = data['inviteCode'] as String?;
        if (inviteCode != null && inviteCode.isNotEmpty) {
          team.inviteCode = inviteCode;
        }
        final coachCode = data['coachCode'] as String?;
        if (coachCode != null && coachCode.isNotEmpty) {
          team.coachCode = coachCode;
        }
        final parentCode = data['parentCode'] as String?;
        if (parentCode != null && parentCode.isNotEmpty) {
          team.parentCode = parentCode;
        }
        team.ownerUserId =
            (data['ownerUserId'] as String?) ?? team.ownerUserId;
        team.logoKind = (data['logoKind'] as String?) ?? team.logoKind;
        team.templateId =
            (data['templateId'] as String?) ?? team.templateId;
        team.paletteId =
            (data['paletteId'] as String?) ?? team.paletteId;
        team.monogramText =
            (data['monogramText'] as String?) ?? team.monogramText;
        team.imagePath = (data['imagePath'] as String?) ?? team.imagePath;
        final updatedAt = _parseDate(data['updatedAt']);
        if (updatedAt != null) {
          team.updatedAt = updatedAt;
        }
        team.updatedBy =
            (data['updatedBy'] as String?) ?? team.updatedBy;
        team.deletedAt =
            _parseDate(data['deletedAt']) ?? team.deletedAt;
        team.schemaVersion =
            data['schemaVersion'] as int? ?? team.schemaVersion;
      }

      await isar.teams.put(team);

      // If this user had a pending membership for this team locally but the
      // server now lists the team, treat membership as active (approved).
      final pendingMembership =
          await joinRepo.getEffectiveMembership(uuid, currentUserId);
      if (pendingMembership != null) {
        if (pendingMembership.status != JoinRequestStatus.pending) {
          continue;
        }
        pendingMembership.status = JoinRequestStatus.approved;
        pendingMembership.approvedAt =
            pendingMembership.approvedAt ?? DateTime.now();
        pendingMembership.approvedByUserId =
            pendingMembership.approvedByUserId ?? currentUserId;
        pendingMembership.updatedAt = DateTime.now();
        pendingMembership.updatedBy = currentUserId;
        await isar.joinRequests.put(pendingMembership);
      }
    }
  });

  ref.read(lastTeamsRefreshTimeProvider.notifier).state = DateTime.now();
});
