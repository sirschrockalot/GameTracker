import '../../core/constants.dart';
import '../../data/isar/models/game.dart';

/// Validation helpers for game/lineup data (sync and local).
class GameValidators {
  GameValidators._();

  static const int quarterMin = 1;
  static const int quarterMax = AppConstants.quartersPerGame;

  /// Quarter index must be in 1..6.
  static bool isValidQuarterIndex(int quarter) =>
      quarter >= quarterMin && quarter <= quarterMax;

  /// Lineup must have exactly 5 player IDs.
  static bool isValidLineupLength(List<String> lineup) =>
      lineup.length == AppConstants.playersOnCourt;

  /// No duplicate player IDs in a lineup.
  static bool hasNoDuplicatePlayerIds(List<String> lineup) {
    final seen = <String>{};
    for (final id in lineup) {
      if (seen.contains(id)) return false;
      seen.add(id);
    }
    return true;
  }

  /// Each award type must have at most 2 player IDs.
  static bool awardsPerTypeWithinLimit(Map<AwardType, List<String>> awards) {
    for (final list in awards.values) {
      if (list.length > AppConstants.awardsPerCategory) return false;
    }
    return true;
  }
}
