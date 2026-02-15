import 'package:flutter_test/flutter_test.dart';
import 'package:upward_lineup/data/isar/models/player.dart';
import 'package:upward_lineup/domain/services/lineup_suggester.dart';

void main() {
  late List<Player> players5;
  late List<Player> players6;
  late List<Player> players7;
  late List<Player> players9;

  setUpAll(() {
    players5 = _makePlayers(5, allDeveloping: false);
    players6 = _makePlayers(6, allDeveloping: false);
    players7 = _makePlayers(7, allDeveloping: false);
    players9 = _makePlayers(9, allDeveloping: false);
  });

  group('LineupSuggester', () {
    test('5 players: only combination is all on court', () {
      final q = _quarters(players5, const [0, 0, 0, 0, 0]);
      final s = suggestLineup(
        presentPlayers: players5,
        quartersPlayed: q,
        lastQuarterLineup: [],
        lastQuarterSitting: players5.map((p) => p.uuid).toList(),
        nextQuarter: 1,
        requiredOnCourt: 5,
      );
      expect(s.onCourt.length, 5);
      expect(s.sitting.length, 0);
      expect(s.nextQuarter, 1);
      expect(s.reason, isNotEmpty);
    });

    test('6 players: suggestion has 5 on court, 1 sitting', () {
      final ids = players6.map((p) => p.uuid).toList();
      final q = _quarters(players6, [0, 0, 1, 1, 2, 2]);
      final s = suggestLineup(
        presentPlayers: players6,
        quartersPlayed: q,
        lastQuarterLineup: ids.take(5).toList(),
        lastQuarterSitting: [ids[5]],
        nextQuarter: 2,
        requiredOnCourt: 5,
      );
      expect(s.onCourt.length, 5);
      expect(s.sitting.length, 1);
      expect(s.nextQuarter, 2);
      expect(s.onCourt.toSet().length, 5);
      expect(s.sitting.toSet().length, 1);
      expect(s.onCourt.toSet().intersection(s.sitting.toSet()).isEmpty, true);
    });

    test('7 players: suggestion has 5 on court, 2 sitting', () {
      final ids = players7.map((p) => p.uuid).toList();
      final q = _quarters(players7, [0, 0, 0, 1, 1, 1, 2]);
      final s = suggestLineup(
        presentPlayers: players7,
        quartersPlayed: q,
        lastQuarterLineup: ids.take(5).toList(),
        lastQuarterSitting: ids.skip(5).toList(),
        nextQuarter: 2,
        requiredOnCourt: 5,
      );
      expect(s.onCourt.length, 5);
      expect(s.sitting.length, 2);
      expect(s.nextQuarter, 2);
      expect(Set.from(s.onCourt).length, 5);
      expect(Set.from(s.onCourt).intersection(Set.from(s.sitting)).isEmpty, true);
    });

    test('9 players: suggestion valid and from present only', () {
      final ids = players9.map((p) => p.uuid).toList();
      final q = _quarters(players9, [0, 0, 1, 1, 1, 2, 2, 2, 3]);
      final s = suggestLineup(
        presentPlayers: players9,
        quartersPlayed: q,
        lastQuarterLineup: ids.take(5).toList(),
        lastQuarterSitting: ids.skip(5).toList(),
        nextQuarter: 3,
        requiredOnCourt: 5,
      );
      expect(s.onCourt.length, 5);
      expect(s.sitting.length, 4);
      expect(Set.from(s.onCourt).union(Set.from(s.sitting)), equals(Set.from(ids)));
      expect(s.reason, isNotEmpty);
    });

    test('suggestSwapForFairness suggests swap when spread improves', () {
      final ids = players6.map((p) => p.uuid).toList();
      final onCourt = ids.take(5).toList();
      final sitting = [ids[5]];
      final quartersPlayed = <String, int>{
        ids[0]: 5,
        ids[1]: 5,
        ids[2]: 5,
        ids[3]: 5,
        ids[4]: 1,
        ids[5]: 3,
      };
      final swap = suggestSwapForFairness(
        onCourt: onCourt,
        sitting: sitting,
        quartersPlayed: quartersPlayed,
      );
      expect(swap, isNotNull);
      expect(swap!.outId, isIn(onCourt));
      expect(swap.inId, ids[5]);
      expect(swap.reason, contains('fairness'));
    });

    test('suggestSwapForFairness returns null when no improvement', () {
      final ids = players6.map((p) => p.uuid).toList();
      final onCourt = ids.take(5).toList();
      final sitting = [ids[5]];
      final quartersPlayed = _quarters(players6, [1, 1, 1, 1, 1, 1]);
      final swap = suggestSwapForFairness(
        onCourt: onCourt,
        sitting: sitting,
        quartersPlayed: quartersPlayed,
      );
      expect(swap, isNull);
    });

    test('suggestSwapForFairness returns null when sitting empty', () {
      final ids = players5.map((p) => p.uuid).toList();
      final swap = suggestSwapForFairness(
        onCourt: ids,
        sitting: [],
        quartersPlayed: _quarters(players5, [1, 1, 1, 1, 1]),
      );
      expect(swap, isNull);
    });
  });
}

List<Player> _makePlayers(int n, {bool allDeveloping = false}) {
  return List.generate(n, (i) {
    return Player.create(
      uuid: 'p$i',
      name: 'Player$i',
      skill: allDeveloping ? Skill.developing : (i.isEven ? Skill.strong : Skill.developing),
    );
  });
}

Map<String, int> _quarters(List<Player> players, List<int> counts) {
  final m = <String, int>{};
  for (var i = 0; i < players.length && i < counts.length; i++) {
    m[players[i].uuid] = counts[i];
  }
  return m;
}
