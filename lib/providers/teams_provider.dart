import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/bootstrap_api.dart';
import '../data/isar/models/join_request.dart';
import '../data/isar/models/team.dart';
import '../data/repositories/team_repository.dart';
import '../data/repositories/join_request_repository.dart';
import '../data/sync/bootstrap_upsert.dart';
import '../data/sync/game_sync.dart';
import 'current_user_provider.dart';
import 'game_provider.dart';
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

  // Track teams that may have cloud sync enabled so we can bootstrap
  // roster and schedule after the transaction completes.
  final syncedTeamIds = <String>[];

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
            syncEnabled: data['syncEnabled'] as bool? ?? false,
            lastSyncedAt: _parseDate(data['lastSyncedAt']),
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

        final syncEnabled = data['syncEnabled'] as bool?;
        if (syncEnabled != null) {
          team.syncEnabled = syncEnabled;
        }
        final lastSyncedAt = _parseDate(data['lastSyncedAt']);
        if (lastSyncedAt != null) {
          team.lastSyncedAt = lastSyncedAt;
        }
      }

      await isar.teams.put(team);

      // Ensure there is an active local membership for this user and team
      // when the server lists the team (handles fresh installs on coach devices).
      final membership =
          await joinRepo.getEffectiveMembership(uuid, currentUserId);
      if (membership == null) {
        final jr = JoinRequest.create(
          uuid: '${uuid}_$currentUserId',
          teamId: uuid,
          userId: currentUserId,
          coachName: 'Coach',
          role: TeamMemberRole.coach,
          status: JoinRequestStatus.approved,
        );
        await isar.joinRequests.put(jr);
      } else if (membership.status != JoinRequestStatus.approved) {
        membership.status = JoinRequestStatus.approved;
        membership.approvedAt =
            membership.approvedAt ?? DateTime.now();
        membership.approvedByUserId =
            membership.approvedByUserId ?? currentUserId;
        membership.updatedAt = DateTime.now();
        membership.updatedBy = currentUserId;
        await isar.joinRequests.put(membership);
      }

      syncedTeamIds.add(uuid);
    }
  });

  // For all teams returned by the backend, attempt to download the latest
  // roster and schedule so non-owner members see players/events. The backend
  // can choose to return data only for teams that actually have sync enabled.
  for (final teamId in syncedTeamIds) {
    try {
      final response = await bootstrapDownload(client, teamId);
      await upsertBootstrapResponse(isar, response);
    } catch (_) {
      // Swallow errors – teams list should still be correct even if
      // bootstrap download fails (e.g. older backend without this endpoint).
    }
  }

  // Pull game history for all active teams so History tab is up to date for non-owners.
  try {
    await pushLocalGamesToServer(client, isar);
  } catch (_) {}
  try {
    await pullGamesIntoIsar(client, isar);
    ref.invalidate(gamesStreamProvider);
  } catch (_) {}

  ref.read(lastTeamsRefreshTimeProvider.notifier).state = DateTime.now();
});
