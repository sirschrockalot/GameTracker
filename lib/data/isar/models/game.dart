import 'package:isar/isar.dart';

import 'game_serialization.dart';

part 'game.g.dart';

enum AwardType {
  christlikeness,
  defense,
  effort,
  offense,
  sportsmanship,
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

  /// Team UUID this game belongs to (for multi-coach sync).
  String? teamId;

  late DateTime updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  late int schemaVersion;

  /// JSON: quarter (1..6) -> list of 5 player UUIDs. Stored as string.
  @Name('quarterLineupsJson')
  late String quarterLineupsJson;

  /// JSON: playerId -> quarters played count. Local cache only; sync derives from quarterLineups.
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
    this.teamId,
    DateTime? updatedAt,
    this.updatedBy,
    this.deletedAt,
    int schemaVersion = 1,
    String? quarterLineupsJson,
    String? quartersPlayedJson,
    String? awardsJson,
  })  : updatedAt = updatedAt ?? startedAt,
        schemaVersion = schemaVersion,
        quarterLineupsJson = quarterLineupsJson ?? GameSerialization.emptyQuarterLineupsJson,
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

  /// Player UUID -> quarters played count (local cache; kept in sync with lineups on save).
  @ignore
  Map<String, int> get quartersPlayed =>
      GameSerialization.decodeQuartersPlayed(quartersPlayedJson);

  @ignore
  set quartersPlayed(Map<String, int> value) {
    quartersPlayedJson = GameSerialization.encodeQuartersPlayed(value);
  }

  /// Derived from [quarterLineups]; use for sync payloads instead of storing quartersPlayed.
  @ignore
  Map<String, int> get quartersPlayedDerived =>
      GameSerialization.computeQuartersPlayedFromLineups(quarterLineups);

  /// Award type -> list of up to 2 player UUIDs.
  @ignore
  Map<AwardType, List<String>> get awards {
    final raw = GameSerialization.decodeAwardsRaw(awardsJson);
    final result = <AwardType, List<String>>{};
    final oldKeyToNew = <String, AwardType>{
      'christlike': AwardType.christlikeness,
      'hustle': AwardType.effort,
    };
    for (final entry in raw.entries) {
      AwardType? t;
      for (final e in AwardType.values) {
        if (e.name == entry.key) {
          t = e;
          break;
        }
      }
      t ??= oldKeyToNew[entry.key];
      if (t != null) result[t] = entry.value;
    }
    return result;
  }

  @ignore
  set awards(Map<AwardType, List<String>> value) {
    final raw = value.map((k, v) => MapEntry(k.name, v));
    awardsJson = GameSerialization.encodeAwardsRaw(raw);
  }
}
