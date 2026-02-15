import 'package:isar/isar.dart';

import 'game_serialization.dart';

part 'game.g.dart';

enum AwardType {
  christlike,
  offense,
  defense,
  hustle,
}

@collection
class Game {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late DateTime startedAt;

  late int quartersTotal;

  /// 1-based quarter (1..6).
  late int currentQuarter;

  /// UUIDs of players present for this game.
  late List<String> presentPlayerIds;

  /// JSON: quarter (1..6) -> list of 5 player UUIDs. Stored as string.
  @Name('quarterLineupsJson')
  late String quarterLineupsJson;

  /// JSON: playerId -> quarters played count. Stored as string.
  @Name('quartersPlayedJson')
  late String quartersPlayedJson;

  /// JSON: awardType -> list of up to 2 player UUIDs. Stored as string.
  @Name('awardsJson')
  late String awardsJson;

  Game();

  Game.create({
    required this.uuid,
    required this.startedAt,
    this.quartersTotal = 6,
    this.currentQuarter = 1,
    required this.presentPlayerIds,
    String? quarterLineupsJson,
    String? quartersPlayedJson,
    String? awardsJson,
  })  : quarterLineupsJson = quarterLineupsJson ?? GameSerialization.emptyQuarterLineupsJson,
        quartersPlayedJson = quartersPlayedJson ?? GameSerialization.emptyQuartersPlayedJson,
        awardsJson = awardsJson ?? GameSerialization.emptyAwardsJson;

  /// Quarter index (1..6) -> list of 5 player UUIDs.
  @ignore
  Map<int, List<String>> get quarterLineups =>
      GameSerialization.decodeQuarterLineups(quarterLineupsJson);

  @ignore
  set quarterLineups(Map<int, List<String>> value) {
    quarterLineupsJson = GameSerialization.encodeQuarterLineups(value);
  }

  /// Player UUID -> quarters played count.
  @ignore
  Map<String, int> get quartersPlayed =>
      GameSerialization.decodeQuartersPlayed(quartersPlayedJson);

  @ignore
  set quartersPlayed(Map<String, int> value) {
    quartersPlayedJson = GameSerialization.encodeQuartersPlayed(value);
  }

  /// Award type -> list of up to 2 player UUIDs.
  @ignore
  Map<AwardType, List<String>> get awards {
    final raw = GameSerialization.decodeAwardsRaw(awardsJson);
    final result = <AwardType, List<String>>{};
    for (final entry in raw.entries) {
      for (final t in AwardType.values) {
        if (t.name == entry.key) {
          result[t] = entry.value;
          break;
        }
      }
    }
    return result;
  }

  @ignore
  set awards(Map<AwardType, List<String>> value) {
    final raw = value.map((k, v) => MapEntry(k.name, v));
    awardsJson = GameSerialization.encodeAwardsRaw(raw);
  }
}
