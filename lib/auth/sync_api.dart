import 'dart:convert';

import 'api_client.dart';

/// GET /sync/pull?since=<ISO>. Returns { serverTime, teams, teamMembers, scheduleEvents, games }.
Future<Map<String, dynamic>> pullSync(
  AuthenticatedHttpClient client, {
  DateTime? since,
}) async {
  final q = since != null ? {'since': since.toIso8601String()} : null;
  final uri = Uri.parse('${client.baseUrl}/sync/pull').replace(queryParameters: q);
  final res = await client.get(uri);
  if (res.statusCode != 200) throw Exception('Sync pull failed: ${res.statusCode}');
  return jsonDecode(res.body) as Map<String, dynamic>;
}
