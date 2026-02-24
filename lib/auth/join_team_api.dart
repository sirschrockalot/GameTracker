import 'dart:convert';

import 'api_client.dart';

/// POST /teams/join. Body: code, coachName, note. Returns member map (teamId, role, status, uuid, requestedAt, ...).
/// 201 created, 200 already pending. Throws ApiException on 404 (invalid code), 409 (already member), etc.
Future<Map<String, dynamic>> requestJoin(
  AuthenticatedHttpClient client,
  String code,
  String coachName,
  String? note,
) async {
  final uri = Uri.parse('${client.baseUrl}/teams/join');
  final res = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'code': code.trim().toUpperCase(),
      'coachName': coachName,
      if (note != null && note.isNotEmpty) 'note': note,
    }),
  );
  if (res.statusCode == 404) {
    throw ApiException('not_found', 'Invalid or expired code');
  }
  if (res.statusCode == 409) {
    throw ApiException('already_member', "You're already a member of this team.");
  }
  if (res.statusCode != 200 && res.statusCode != 201) {
    final body = jsonDecode(res.body);
    final msg = body is Map && body['message'] != null ? body['message'] as String : 'Request failed';
    throw ApiException(body is Map && body['error'] != null ? body['error'] as String : 'error', msg);
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}
