import 'package:isar/isar.dart';

import '../isar/models/game.dart';
import '../isar/models/game_serialization.dart';

class GameRepository {
  GameRepository(this._isar);

  final Isar _isar;

  Future<Game?> getByUuid(String uuid) async {
    return _isar.games
        .filter()
        .uuidEqualTo(uuid)
        .deletedAtIsNull()
        .findFirst();
  }

  Future<String> createGame(Game game) => _isar.writeTxn(() async {
        final existing = await _isar.games
            .filter()
            .uuidEqualTo(game.uuid)
            .findFirst();
        if (existing != null) {
          game.id = existing.id;
        }
        await _isar.games.put(game);
      }).then((_) => game.uuid);

  Future<List<Game>> listGames() async {
    return _isar.games
        .filter()
        .deletedAtIsNull()
        .sortByStartedAtDesc()
        .findAll();
  }

  Stream<List<Game>> watchAllGames() {
    return _isar.games
        .filter()
        .deletedAtIsNull()
        .sortByStartedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Update lineup for a quarter (1..6). Replaces the list of 5 player UUIDs.
  /// No-op if quarter is completed. Recomputes quartersPlayed from quarterLineups.
  Future<void> updateLineupForQuarter(
    String gameUuid,
    int quarter,
    List<String> playerUuids,
  ) async {
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      if (game.completedQuarters.contains(quarter)) return;
      final lineups = game.quarterLineups;
      lineups[quarter] = List.from(playerUuids);
      game.quarterLineups = lineups;
      game.quartersPlayed = GameSerialization.computeQuartersPlayedFromLineups(lineups);
      await _isar.games.put(game);
    });
  }

  /// Set current quarter (1..6).
  Future<void> updateCurrentQuarter(String gameUuid, int currentQuarter) async {
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      game.currentQuarter = currentQuarter;
      await _isar.games.put(game);
    });
  }

  /// Save awards: replaces the full awards map (each list max 2 per type).
  Future<void> saveAwards(String gameUuid, Map<AwardType, List<String>> awards) async {
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      game.awards = awards;
      await _isar.games.put(game);
    });
  }

  /// Batch update multiple quarter lineups and currentQuarter. Skips completed quarters.
  /// Recomputes quartersPlayed from quarterLineups (drift-free).
  Future<void> batchUpdateLineupsQuartersAndCurrent(
    String gameUuid,
    Map<int, List<String>> quarterLineups,
    int currentQuarter,
  ) async {
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      final completed = game.completedQuarters;
      final lineups = game.quarterLineups;
      for (final e in quarterLineups.entries) {
        if (completed.contains(e.key)) continue;
        lineups[e.key] = List.from(e.value);
      }
      game.quarterLineups = lineups;
      game.quartersPlayed =
          GameSerialization.computeQuartersPlayedFromLineups(lineups);
      game.currentQuarter = currentQuarter;
      await _isar.games.put(game);
    });
  }

  /// Mark quarter (1..6) as completed (locked). Fails if quarter has no full lineup.
  Future<bool> markQuarterCompleted(String gameUuid, int quarter) async {
    bool ok = false;
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      final lineup = game.quarterLineups[quarter];
      if (lineup == null || lineup.length != 5) return;
      final completed = game.completedQuarters;
      if (completed.contains(quarter)) return;
      completed.add(quarter);
      game.completedQuarters = completed;
      await _isar.games.put(game);
      ok = true;
    });
    return ok;
  }

  /// Soft-delete game (set deletedAt). Schedule/players untouched.
  Future<void> deleteGame(String gameUuid) async {
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      game.deletedAt = DateTime.now();
      await _isar.games.put(game);
    });
  }

}
