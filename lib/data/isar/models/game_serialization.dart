import 'dart:convert';

/// Serialization helpers for Game's map fields (Isar cannot store Map directly).
/// Uses raw string keys for award types; Game model converts to/from AwardType.
class GameSerialization {
  GameSerialization._();

  static const String emptyQuarterLineupsJson = '{}';
  static const String emptyQuartersPlayedJson = '{}';
  static const String emptyAwardsJson = '{}';

  // --- Quarter lineups: Map<int, List<String>> (quarter 1..6 -> 5 player UUIDs)
  static Map<int, List<String>> decodeQuarterLineups(String json) {
    if (json.isEmpty || json == '{}') return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) {
      final quarter = int.parse(k);
      final list = (v as List<dynamic>).map((e) => e as String).toList();
      return MapEntry(quarter, list);
    });
  }

  static String encodeQuarterLineups(Map<int, List<String>> map) {
    if (map.isEmpty) return emptyQuarterLineupsJson;
    final encoded = map.map((k, v) => MapEntry(k.toString(), v));
    return jsonEncode(encoded);
  }

  /// Derive quarters played from quarter lineups (use for sync; do not store in cloud).
  static Map<String, int> computeQuartersPlayedFromLineups(
    Map<int, List<String>> quarterLineups,
  ) {
    final result = <String, int>{};
    for (final list in quarterLineups.values) {
      for (final uuid in list) {
        result[uuid] = (result[uuid] ?? 0) + 1;
      }
    }
    return result;
  }

  // --- Quarters played: Map<String, int> (player UUID -> count). Local cache only.
  static Map<String, int> decodeQuartersPlayed(String json) {
    if (json.isEmpty || json == '{}') return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  }

  static String encodeQuartersPlayed(Map<String, int> map) {
    if (map.isEmpty) return emptyQuartersPlayedJson;
    return jsonEncode(map);
  }

  // --- Awards: Map<String, List<String>> (award type name -> list of up to 2 player UUIDs)
  static Map<String, List<String>> decodeAwardsRaw(String json) {
    if (json.isEmpty || json == '{}') return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) {
      final list = (v as List<dynamic>).map((e) => e as String).toList();
      return MapEntry(k, list);
    });
  }

  static String encodeAwardsRaw(Map<String, List<String>> map) {
    if (map.isEmpty) return emptyAwardsJson;
    return jsonEncode(map);
  }
}
