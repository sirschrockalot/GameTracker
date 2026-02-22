import 'package:flutter_test/flutter_test.dart';

import 'package:upward_lineup/data/isar/models/game.dart';
import 'package:upward_lineup/data/isar/models/game_serialization.dart';

void main() {
  group('GameSerialization', () {
    group('quarterLineups', () {
      test('round-trip empty', () {
        const json = GameSerialization.emptyQuarterLineupsJson;
        final decoded = GameSerialization.decodeQuarterLineups(json);
        expect(decoded, isEmpty);
        expect(GameSerialization.encodeQuarterLineups(decoded), json);
      });

      test('round-trip quarter 1 with 5 player UUIDs', () {
        const uuids = ['a', 'b', 'c', 'd', 'e'];
        final map = {1: uuids};
        final encoded = GameSerialization.encodeQuarterLineups(map);
        expect(encoded, isNotEmpty);
        final decoded = GameSerialization.decodeQuarterLineups(encoded);
        expect(decoded, {1: uuids});
      });

      test('round-trip multiple quarters', () {
        final map = {
          1: ['p1', 'p2', 'p3', 'p4', 'p5'],
          2: ['p2', 'p3', 'p4', 'p5', 'p6'],
        };
        final encoded = GameSerialization.encodeQuarterLineups(map);
        final decoded = GameSerialization.decodeQuarterLineups(encoded);
        expect(decoded, map);
      });
    });

    group('quartersPlayed', () {
      test('round-trip empty', () {
        const json = GameSerialization.emptyQuartersPlayedJson;
        final decoded = GameSerialization.decodeQuartersPlayed(json);
        expect(decoded, isEmpty);
        expect(GameSerialization.encodeQuartersPlayed(decoded), json);
      });

      test('round-trip player UUID to count', () {
        final map = {'player-uuid-1': 3, 'player-uuid-2': 2};
        final encoded = GameSerialization.encodeQuartersPlayed(map);
        final decoded = GameSerialization.decodeQuartersPlayed(encoded);
        expect(decoded, map);
      });
    });

    group('awards (raw)', () {
      test('round-trip empty', () {
        const json = GameSerialization.emptyAwardsJson;
        final decoded = GameSerialization.decodeAwardsRaw(json);
        expect(decoded, isEmpty);
        expect(GameSerialization.encodeAwardsRaw(decoded), json);
      });

      test('round-trip award type to list of UUIDs', () {
        final map = {
          'christlike': ['uuid1', 'uuid2'],
          'offense': ['uuid3'],
        };
        final encoded = GameSerialization.encodeAwardsRaw(map);
        final decoded = GameSerialization.decodeAwardsRaw(encoded);
        expect(decoded, map);
      });
    });

    group('completedQuarters', () {
      test('round-trip empty', () {
        const json = GameSerialization.emptyCompletedQuartersJson;
        final decoded = GameSerialization.decodeCompletedQuarters(json);
        expect(decoded, isEmpty);
        expect(GameSerialization.encodeCompletedQuarters(decoded), json);
      });

      test('round-trip set of quarter numbers', () {
        final set = {1, 3, 5};
        final encoded = GameSerialization.encodeCompletedQuarters(set);
        final decoded = GameSerialization.decodeCompletedQuarters(encoded);
        expect(decoded, set);
      });
    });

    group('computeQuartersPlayedFromLineups', () {
      test('editing same quarter twice: counts reflect only latest lineup (no double count)', () {
        final lineups1 = {1: ['a', 'b', 'c', 'd', 'e']};
        final counts1 = GameSerialization.computeQuartersPlayedFromLineups(lineups1);
        expect(counts1, {'a': 1, 'b': 1, 'c': 1, 'd': 1, 'e': 1});

        final lineups2 = {1: ['b', 'c', 'd', 'e', 'f']};
        final counts2 = GameSerialization.computeQuartersPlayedFromLineups(lineups2);
        expect(counts2, {'b': 1, 'c': 1, 'd': 1, 'e': 1, 'f': 1});
        expect(counts2.containsKey('a'), false);
      });
    });

    group('Game awards getter/setter', () {
      test('round-trip AwardType map', () {
        final game = Game.create(
          uuid: 'game-1',
          startedAt: DateTime.now(),
          presentPlayerIds: [],
        );
        final awards = <AwardType, List<String>>{
          AwardType.christlikeness: ['p1', 'p2'],
          AwardType.effort: ['p3'],
        };
        game.awards = awards;
        expect(game.awards, awards);
      });
    });
  });
}
