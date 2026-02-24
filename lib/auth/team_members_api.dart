import 'dart:convert';

import 'api_client.dart';

/// GET /teams/:teamId/members. Owner-only (by default).
Future<List<Map<String, dynamic>>> listTeamMembers(
  AuthenticatedHttpClient client,
  String teamId,
) async {
  final uri = Uri.parse('${client.baseUrl}/teams/$teamId/members');
  final res = await client.get(uri);
  if (res.statusCode != 200) {
    throw Exception('List team members failed: ${res.statusCode}');
  }
  final list = jsonDecode(res.body) as List<dynamic>;
  return list.map((e) => e as Map<String, dynamic>).toList();
}

