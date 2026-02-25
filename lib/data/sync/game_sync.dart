import 'package:isar/isar.dart';

import '../repositories/game_repository.dart';
import '../repositories/team_repository.dart';
import '../../auth/api_client.dart';
import '../../auth/game_api.dart';
import '../../auth/sync_api.dart';

/// Push local games to the server for all teams that have sync enabled.
/// Use so game history appears in the DB (e.g. after enabling sync or if upsert failed at start).
Future<void> pushLocalGamesToServer(
  AuthenticatedHttpClient client,
  Isar isar,
) async {
  final teamRepo = TeamRepository(isar);
  final gameRepo = GameRepository(isar);
  final teams = await teamRepo.getAll();
  final syncedTeams = teams.where((t) => t.syncEnabled == true).toList();
  for (final team in syncedTeams) {
    final games = await gameRepo.listByTeamId(team.uuid);
    for (final game in games) {
      try {
        final payload = {
          'uuid': game.uuid,
          'teamId': game.teamId ?? team.uuid,
          'startedAt': game.startedAt.toIso8601String(),
          'quarterLineupsJson': game.quarterLineupsJson,
          'completedQuartersJson': game.completedQuartersJson,
          'awardsJson': game.awardsJson,
          'schemaVersion': game.schemaVersion,
        };
        await upsertGame(client, team.uuid, payload);
      } catch (_) {}
    }
  }
}

/// Pull sync (games only) and upsert into Isar. Use since to avoid re-downloading all.
/// quartersPlayedJson is recomputed from quarterLineups (never stored from server).
Future<void> pullGamesIntoIsar(
  AuthenticatedHttpClient client,
  Isar isar, {
  DateTime? since,
}) async {
  final response = await pullSync(client, since: since ?? DateTime(0));
  final games = response['games'] as List<dynamic>? ?? [];
  final repo = GameRepository(isar);
  for (final g in games) {
    final m = g as Map<String, dynamic>;
    if (m['uuid'] != null) await repo.upsertFromServerGame(m);
  }
}
