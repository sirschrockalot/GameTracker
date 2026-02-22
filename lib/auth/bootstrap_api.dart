import 'dart:convert';

import '../data/isar/models/player.dart';
import '../data/isar/models/schedule_event.dart';
import 'api_client.dart';

/// GET /teams. Returns list of team maps.
Future<List<Map<String, dynamic>>> listCloudTeams(AuthenticatedHttpClient client) async {
  final uri = Uri.parse('${client.baseUrl}/teams');
  final res = await client.get(uri);
  if (res.statusCode != 200) throw Exception('List teams failed: ${res.statusCode}');
  final list = jsonDecode(res.body) as List<dynamic>;
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// Create cloud team with same [uuid] and [name]. Returns response body.
Future<Map<String, dynamic>> createCloudTeam(
  AuthenticatedHttpClient client,
  String uuid,
  String name,
) async {
  final uri = Uri.parse('${client.baseUrl}/teams');
  final res = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'uuid': uuid, 'name': name}),
  );
  if (res.statusCode != 201) {
    throw Exception('Create team failed: ${res.statusCode}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Upload players and schedule events for bootstrap. Returns { players, scheduleEvents }.
Future<Map<String, dynamic>> bootstrapUpload(
  AuthenticatedHttpClient client,
  String teamId,
  List<Player> players,
  List<ScheduleEvent> scheduleEvents,
) async {
  final payload = {
    'players': players
        .map((p) => {
              'uuid': p.uuid,
              'teamId': teamId,
              'name': p.name,
              'skill': p.skill.name,
              if (p.createdAt != null) 'createdAt': p.createdAt!.toIso8601String(),
              if (p.deletedAt != null) 'deletedAt': p.deletedAt!.toIso8601String(),
              'schemaVersion': p.schemaVersion,
            })
        .toList(),
    'scheduleEvents': scheduleEvents
        .map((e) => {
              'uuid': e.uuid,
              'teamId': teamId,
              'type': e.type.name,
              'startsAt': e.startsAt.toIso8601String(),
              'endsAt': e.endsAt?.toIso8601String(),
              'location': e.location,
              'opponent': e.opponent,
              'notes': e.notes,
              if (e.deletedAt != null) 'deletedAt': e.deletedAt!.toIso8601String(),
              'schemaVersion': e.schemaVersion,
            })
        .toList(),
  };
  final uri = Uri.parse('${client.baseUrl}/teams/$teamId/bootstrap');
  final res = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );
  if (res.statusCode != 200) {
    throw Exception('Bootstrap failed: ${res.statusCode}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}
