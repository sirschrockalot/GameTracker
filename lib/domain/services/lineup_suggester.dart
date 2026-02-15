import '../../data/isar/models/player.dart';

const int _defaultRequiredOnCourt = 5;

const double _fairnessWeight = 1.0;
const double _rotationWeight = 0.4;
const double _mixWeight = 1.0;

/// Result of suggesting a lineup for the next quarter.
class Suggestion {
  const Suggestion({
    required this.nextQuarter,
    required this.onCourt,
    required this.sitting,
    required this.reason,
    this.recommendedSwap,
  });

  final int nextQuarter;
  final List<String> onCourt;
  final List<String> sitting;
  final String reason;
  final RecommendedSwap? recommendedSwap;
}

/// Optional single swap to improve fairness of a coach-edited lineup.
class RecommendedSwap {
  const RecommendedSwap({
    required this.outId,
    required this.inId,
    required this.reason,
  });

  final String outId;
  final String inId;
  final String reason;
}

/// Suggests the next quarter lineup from present players using fairness,
/// rotation preference, and skill mix.
Suggestion suggestLineup({
  required List<Player> presentPlayers,
  required Map<String, int> quartersPlayed,
  required List<String> lastQuarterLineup,
  required List<String> lastQuarterSitting,
  int nextQuarter = 1,
  int requiredOnCourt = _defaultRequiredOnCourt,
}) {
  final presentIds = presentPlayers.map((p) => p.uuid).toList();
  final idToPlayer = {for (final p in presentPlayers) p.uuid: p};
  final n = presentIds.length;

  if (n < requiredOnCourt) {
    return Suggestion(
      nextQuarter: nextQuarter,
      onCourt: List.from(presentIds),
      sitting: [],
      reason: 'Only $n players present; need $requiredOnCourt.',
    );
  }

  if (n == requiredOnCourt) {
    return Suggestion(
      nextQuarter: nextQuarter,
      onCourt: List.from(presentIds),
      sitting: [],
      reason: 'Exactly $requiredOnCourt present; no rotation choice.',
    );
  }

  final lastSittingSet = lastQuarterSitting.toSet();
  final hasDeveloping = presentPlayers.any((p) => p.skill == Skill.developing);

  List<List<String>> combinations = _combinations(presentIds, requiredOnCourt);
  double bestScore = -double.infinity;
  List<String>? bestOnCourt;

  for (final combo in combinations) {
    final after = Map<String, int>.from(quartersPlayed);
    for (final id in combo) {
      after[id] = (after[id] ?? 0) + 1;
    }
    final presentCounts = presentIds.map((id) => after[id] ?? 0).toList();
    final maxP = presentCounts.reduce((a, b) => a > b ? a : b);
    final minP = presentCounts.reduce((a, b) => a < b ? a : b);
    final spread = maxP - minP;
    final fairnessScore = -spread.toDouble();

    final rotationScore =
        combo.where((id) => lastSittingSet.contains(id)).length / requiredOnCourt;

    final strongCount = combo.where((id) => idToPlayer[id]?.skill == Skill.strong).length;
    final developingCount = requiredOnCourt - strongCount;
    double mixScore = 0.0;
    if (hasDeveloping) {
      if (strongCount == requiredOnCourt) {
        mixScore = -1.5;
      } else if (strongCount >= 1 && developingCount >= 1) {
        mixScore = 0.5;
      }
    }

    final score = _fairnessWeight * fairnessScore +
        _rotationWeight * rotationScore +
        _mixWeight * mixScore;

    if (score > bestScore) {
      bestScore = score;
      bestOnCourt = List.from(combo);
    }
  }

  final onCourt = bestOnCourt ?? combinations.first;
  final sitting = presentIds.where((id) => !onCourt.contains(id)).toList();

  final after = Map<String, int>.from(quartersPlayed);
  for (final id in onCourt) {
    after[id] = (after[id] ?? 0) + 1;
  }
  final minPlayed = presentIds.map((id) => after[id] ?? 0).reduce((a, b) => a < b ? a : b);
  final behind = onCourt
      .where((id) => (after[id] ?? 0) == minPlayed)
      .map((id) => idToPlayer[id]?.name ?? id)
      .take(3)
      .toList();
  final reason = behind.isEmpty
      ? 'Balanced rotation.'
      : 'Prioritizing ${behind.join(", ")} (behind on minutes).';

  return Suggestion(
    nextQuarter: nextQuarter,
    onCourt: onCourt,
    sitting: sitting,
    reason: reason,
    recommendedSwap: null,
  );
}

/// Given a coach-edited lineup, suggests one swap (out from onCourt, in from sitting)
/// that improves fairness (reduces spread of quartersPlayed after the swap).
/// [quartersPlayed] is the current count per player (e.g. after applying this quarter).
RecommendedSwap? suggestSwapForFairness({
  required List<String> onCourt,
  required List<String> sitting,
  required Map<String, int> quartersPlayed,
}) {
  if (sitting.isEmpty) return null;

  int spreadFor(List<String> court) {
    final counts = court.map((id) => quartersPlayed[id] ?? 0).toList();
    final maxC = counts.reduce((a, b) => a > b ? a : b);
    final minC = counts.reduce((a, b) => a < b ? a : b);
    return maxC - minC;
  }

  final currentSpread = spreadFor(onCourt);
  String? bestOut;
  String? bestIn;
  int bestSpread = currentSpread;

  for (final outId in onCourt) {
    for (final inId in sitting) {
      final newCourt = onCourt.where((id) => id != outId).toList()..add(inId);
      final s = spreadFor(newCourt);
      if (s < bestSpread) {
        bestSpread = s;
        bestOut = outId;
        bestIn = inId;
      }
    }
  }

  if (bestOut == null || bestIn == null) return null;
  return RecommendedSwap(
    outId: bestOut,
    inId: bestIn,
    reason: 'Swap improves fairness (spread $currentSpread → $bestSpread).',
  );
}

List<List<String>> _combinations(List<String> list, int k) {
  if (k == 0) return [[]];
  if (k > list.length) return [];
  final result = <List<String>>[];
  void go(int start, List<String> acc) {
    if (acc.length == k) {
      result.add(List.from(acc));
      return;
    }
    for (int i = start; i <= list.length - (k - acc.length); i++) {
      acc.add(list[i]);
      go(i + 1, acc);
      acc.removeLast();
    }
  }
  go(0, []);
  return result;
}
