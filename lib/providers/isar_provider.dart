import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isar/isar_schemas.dart';
import '../data/isar/models/player.dart';
import '../data/isar/models/game.dart';
import '../data/isar/models/team.dart';
import '../data/isar/models/join_request.dart';
import '../data/isar/models/schedule_event.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      isarSchemas,
      directory: dir.path,
      name: 'upward_lineup',
    );
    ref.onDispose(() => isar.close());
    return isar;
  } catch (e, st) {
    throw Exception(
      'Database failed to open: $e. '
      'If this persists, try deleting and reinstalling the app.',
    );
  }
});

/// Clears all data from the database (players, games, teams, join requests, schedule events).
Future<void> clearIsarDatabase(Isar isar) async {
  await isar.writeTxn(() async {
    await isar.players.clear();
    await isar.games.clear();
    await isar.teams.clear();
    await isar.joinRequests.clear();
    await isar.scheduleEvents.clear();
  });
}
