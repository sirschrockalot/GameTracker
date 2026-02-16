import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isar/isar_schemas.dart';
import '../data/isar/models/player.dart';
import '../data/isar/models/game.dart';
import '../data/isar/models/team.dart';
import '../data/isar/models/join_request.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    isarSchemas,
    directory: dir.path,
    name: 'upward_lineup',
  );
  ref.onDispose(() => isar.close());
  return isar;
});

/// Clears all data from the database (players, games, teams, join requests).
Future<void> clearIsarDatabase(Isar isar) async {
  await isar.writeTxn(() async {
    await isar.players.clear();
    await isar.games.clear();
    await isar.teams.clear();
    await isar.joinRequests.clear();
  });
}
