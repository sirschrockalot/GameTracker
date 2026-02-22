import 'package:isar/isar.dart';

import '../repositories/game_repository.dart';
import '../../auth/api_client.dart';
import '../../auth/sync_api.dart';

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
