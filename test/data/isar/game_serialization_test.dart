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

    group('Game awards getter/setter', () {
      test('round-trip AwardType map', () {
        final game = Game.create(
          uuid: 'game-1',
          startedAt: DateTime.now(),
          presentPlayerIds: [],
        );
        final awards = <AwardType, List<String>>{
          AwardType.christlike: ['p1', 'p2'],
          AwardType.hustle: ['p3'],
        };
        game.awards = awards;
        expect(game.awards, awards);
      });
    });
  });
}
