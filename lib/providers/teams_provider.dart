import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/bootstrap_api.dart';
import '../data/isar/models/join_request.dart';
import '../data/isar/models/team.dart';
import '../data/repositories/team_repository.dart';
import '../data/repositories/join_request_repository.dart';
import '../data/repositories/sync_outbox_repository.dart';
import '../data/sync/bootstrap_upsert.dart';
import '../data/sync/game_sync.dart';
import '../data/sync/membership_sync_service.dart';
import 'current_user_provider.dart';
import 'game_provider.dart';
import 'isar_provider.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  return DateTime.tryParse(s);
}

/// Last successful membership refresh (GET /me/memberships) time.
final lastMembershipRefreshTimeProvider = StateProvider<DateTime?>((_) => null);

/// Sync memberships from server, upsert into Isar, cleanup revoked teams. Run on launch + foreground + pull-to-refresh.
final membershipSyncProvider = FutureProvider<void>((ref) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  if (baseUrl.isEmpty) return;

  final client = ref.read(authenticatedHttpClientProvider);
  final isar = await ref.read(isarProvider.future);
  final currentUserId = ref.read(currentUserIdProvider);

  await MembershipSyncService.refresh(client, isar, currentUserId);

  ref.read(lastMembershipRefreshTimeProvider.notifier).state = DateTime.now();
  ref.invalidate(allowedTeamIdsProvider);
  ref.invalidate(teamsStreamProvider);
});

/// Allowed team IDs: active membership or owner. Single source for "team visibility" invariant.
final allowedTeamIdsProvider = FutureProvider<Set<String>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final userId = ref.watch(currentUserIdProvider);
  final teamRepo = TeamRepository(isar);
  final joinRepo = JoinRequestRepository(isar);
  return MembershipSyncService.getAllowedTeamIds(isar, userId, teamRepo, joinRepo);
});

/// Stream of allowed team IDs (reactive to local membership + team changes).
final allowedTeamIdsStreamProvider = StreamProvider<Set<String>>((ref) async* {
  final isar = ref.watch(isarProvider).valueOrNull;
  final userId = ref.watch(currentUserIdProvider);
  if (isar == null) {
    yield {};
    return;
  }
  final joinRepo = JoinRequestRepository(isar);
  final teamRepo = TeamRepository(isar);

  Future<Set<String>> compute() async {
    final approved = await joinRepo.listApprovedTeamIdsForUser(userId);
    final teams = await teamRepo.getAll();
    final ownerIds = teams
        .where((t) => t.ownerUserId != null && t.ownerUserId == userId)
        .map((t) => t.uuid)
        .toSet();
    return {...approved, ...ownerIds};
  }

  yield await compute();
  await for (final _ in joinRepo.watchByUserId(userId)) {
    yield await compute();
  }
});

/// Local teams stream (Isar-backed). Raw list; filter by allowedTeamIds for visibility.
final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return TeamRepository(isar).watchAll();
});

/// Teams the user is allowed to see (active membership or owner). Invariant: only these appear in UI.
final visibleTeamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  final userId = ref.watch(currentUserIdProvider);
  if (isar == null) return Stream.value([]);
  final teamRepo = TeamRepository(isar);
  final joinRepo = JoinRequestRepository(isar);

  final controller = StreamController<List<Team>>.broadcast(sync: true);
  Future<void> emit() async {
    final teams = await teamRepo.getAll();
    final approved = await joinRepo.listApprovedTeamIdsForUser(userId);
    final ownerIds = teams
        .where((t) => t.ownerUserId != null && t.ownerUserId == userId)
        .map((t) => t.uuid)
        .toSet();
    final allowed = {...approved, ...ownerIds};
    controller.add(teams.where((t) => allowed.contains(t.uuid)).toList());
  }

  final sub1 = teamRepo.watchAll().listen((_) => emit());
  final sub2 = joinRepo.watchByUserId(userId).listen((_) => emit());
  emit();

  controller.onCancel = () {
    sub1.cancel();
    sub2.cancel();
  };
  return controller.stream;
});

/// Last successful /teams refresh time from server.
final lastTeamsRefreshTimeProvider = StateProvider<DateTime?>((_) => null);

/// Last API error message (debug).
final lastApiErrorProvider = StateProvider<String?>((_) => null);

/// Refresh teams from backend for the current user and upsert into Isar.
/// Runs membership sync first so revoked teams are removed; then GET /teams (only returns allowed).
final refreshTeamsFromServerProvider = FutureProvider<void>((ref) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  if (baseUrl.isEmpty) return;

  try {
  await ref.read(membershipSyncProvider.future);

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
      final team = await TeamRepository(isar).getByUuid(teamId);
      if (team != null) {
        team.lastSyncedAt = DateTime.now();
        await isar.teams.put(team);
      }
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

  } catch (e) {
    ref.read(lastApiErrorProvider.notifier).state = e.toString();
    rethrow;
  }
  ref.read(lastTeamsRefreshTimeProvider.notifier).state = DateTime.now();
});

/// Pending sync outbox count (non-blocking banner when > 0).
final pendingOutboxCountStreamProvider = StreamProvider<int>((ref) async* {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) {
    yield 0;
    return;
  }
  final repo = SyncOutboxRepository(isar);
  yield await repo.count();
  yield* Stream.periodic(const Duration(seconds: 5), (_) {}).asyncMap((_) => repo.count());
});
