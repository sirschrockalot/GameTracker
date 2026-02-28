import 'dart:convert';

import 'api_client.dart';

/// GET /me/memberships — all memberships for the caller (including revoked/rejected).
Future<List<Map<String, dynamic>>> fetchMyMemberships(AuthenticatedHttpClient client) async {
  final uri = Uri.parse('${client.baseUrl}/me/memberships');
  final res = await client.get(uri);
  if (res.statusCode != 200) throw Exception('My memberships failed: ${res.statusCode}');
  final list = jsonDecode(res.body) as List<dynamic>;
  return list.map((e) => e as Map<String, dynamic>).toList();
}
