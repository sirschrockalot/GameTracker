import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';

/// Per-player season totals (computed from all games).
class PlayerSeasonTotals {
  const PlayerSeasonTotals({
    required this.playerUuid,
    required this.playerName,
    required this.totalQuartersPlayed,
    required this.totalAwardsByType,
    required this.gamesPlayedCount,
  });

  final String playerUuid;
  final String playerName;
  final int totalQuartersPlayed;
  final Map<AwardType, int> totalAwardsByType;
  final int gamesPlayedCount;

  int get totalAwards =>
      totalAwardsByType.values.fold<int>(0, (s, c) => s + c);
}

/// Compute per-player totals across [games]. [playerByUuid] maps UUID to name.
List<PlayerSeasonTotals> computeSeasonTotals(
  List<Game> games,
  List<Player> players,
) {
  final playerByUuid = {for (final p in players) p.uuid: p.name};
  final totalQuarters = <String, int>{};
  final awardsByType = <String, Map<AwardType, int>>{};
  final gamesPlayed = <String, int>{};

  for (final g in games) {
    final present = g.presentPlayerIds.toSet();
    for (final uuid in present) {
      gamesPlayed[uuid] = (gamesPlayed[uuid] ?? 0) + 1;
    }
    final qp = g.quartersPlayedDerived;
    for (final e in qp.entries) {
      totalQuarters[e.key] = (totalQuarters[e.key] ?? 0) + e.value;
    }
    final awards = g.awards;
    for (final e in awards.entries) {
      for (final uuid in e.value) {
        awardsByType[uuid] ??= {for (final t in AwardType.values) t: 0};
        awardsByType[uuid]![e.key] = (awardsByType[uuid]![e.key] ?? 0) + 1;
      }
    }
  }

  final allUuids = <String>{}
    ..addAll(totalQuarters.keys)
    ..addAll(gamesPlayed.keys)
    ..addAll(awardsByType.keys);
  return allUuids.map((uuid) {
    final name = playerByUuid[uuid] ?? 'Unknown';
    final byType = awardsByType[uuid] ?? {for (final t in AwardType.values) t: 0};
    return PlayerSeasonTotals(
      playerUuid: uuid,
      playerName: name,
      totalQuartersPlayed: totalQuarters[uuid] ?? 0,
      totalAwardsByType: byType,
      gamesPlayedCount: gamesPlayed[uuid] ?? 0,
    );
  }).toList();
}
