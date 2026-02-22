import 'dart:convert';

import 'api_client.dart';

/// GET /teams/:teamId/games?limit=&before=
Future<List<Map<String, dynamic>>> listGames(
  AuthenticatedHttpClient client,
  String teamId, {
  int limit = 50,
  DateTime? before,
  bool includeDeleted = false,
}) async {
  final q = <String, String>{
    'limit': limit.toString(),
    if (before != null) 'before': before.toIso8601String(),
    if (includeDeleted) 'includeDeleted': 'true',
  };
  final uri = Uri.parse('${client.baseUrl}/teams/$teamId/games').replace(queryParameters: q);
  final res = await client.get(uri);
  if (res.statusCode != 200) throw Exception('List games failed: ${res.statusCode}');
  final list = jsonDecode(res.body) as List<dynamic>;
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// GET /teams/:teamId/games/:gameId
Future<Map<String, dynamic>?> getGame(
  AuthenticatedHttpClient client,
  String teamId,
  String gameId,
) async {
  final uri = Uri.parse('${client.baseUrl}/teams/$teamId/games/$gameId');
  final res = await client.get(uri);
  if (res.statusCode == 404) return null;
  if (res.statusCode != 200) throw Exception('Get game failed: ${res.statusCode}');
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// POST /teams/:teamId/games (create or upsert by uuid)
Future<Map<String, dynamic>> upsertGame(
  AuthenticatedHttpClient client,
  String teamId,
  Map<String, dynamic> payload,
) async {
  final uri = Uri.parse('${client.baseUrl}/teams/$teamId/games');
  final res = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('Upsert game failed: ${res.statusCode}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// PUT /teams/:teamId/games/:gameId
Future<Map<String, dynamic>> updateGame(
  AuthenticatedHttpClient client,
  String teamId,
  String gameId,
  Map<String, dynamic> payload,
) async {
  final uri = Uri.parse('${client.baseUrl}/teams/$teamId/games/$gameId');
  final res = await client.put(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );
  if (res.statusCode != 200) throw Exception('Update game failed: ${res.statusCode}');
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// DELETE /teams/:teamId/games/:gameId (soft delete)
Future<void> deleteGame(
  AuthenticatedHttpClient client,
  String teamId,
  String gameId,
) async {
  final uri = Uri.parse('${client.baseUrl}/teams/$teamId/games/$gameId');
  final res = await client.delete(uri);
  if (res.statusCode != 200) throw Exception('Delete game failed: ${res.statusCode}');
}
