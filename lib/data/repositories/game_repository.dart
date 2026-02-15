import 'package:isar/isar.dart';

import '../isar/models/game.dart';
import '../isar/models/game_serialization.dart';

class GameRepository {
  GameRepository(this._isar);

  final Isar _isar;

  Future<Game?> getByUuid(String uuid) async {
    return _isar.games.filter().uuidEqualTo(uuid).findFirst();
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
    return _isar.games.where().sortByStartedAtDesc().findAll();
  }

  Stream<List<Game>> watchAllGames() {
    return _isar.games.where().sortByStartedAtDesc().watch(fireImmediately: true);
  }

  /// Update lineup for a quarter (1..6). Replaces the list of 5 player UUIDs.
  Future<void> updateLineupForQuarter(
    String gameUuid,
    int quarter,
    List<String> playerUuids,
  ) async {
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      final lineups = game.quarterLineups;
      lineups[quarter] = List.from(playerUuids);
      game.quarterLineups = lineups;
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

  /// Update quartersPlayed map (e.g. after applying a lineup).
  Future<void> updateQuartersPlayed(
    String gameUuid,
    Map<String, int> quartersPlayed,
  ) async {
    await _isar.writeTxn(() async {
      final game = await _isar.games.filter().uuidEqualTo(gameUuid).findFirst();
      if (game == null) return;
      game.quartersPlayed = quartersPlayed;
      await _isar.games.put(game);
    });
  }
}
