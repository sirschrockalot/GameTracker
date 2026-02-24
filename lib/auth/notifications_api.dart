import 'dart:convert';

import 'api_client.dart';

class PendingRequestsSummary {
  PendingRequestsSummary({
    required this.pendingByTeam,
    required this.totalPending,
  });

  final Map<String, int> pendingByTeam;
  final int totalPending;
}

Future<PendingRequestsSummary> fetchPendingRequestsSummary(
  AuthenticatedHttpClient client,
) async {
  final uri = Uri.parse('${client.baseUrl}/me/notifications/summary');
  final res = await client.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Summary failed: ${res.statusCode}');
  }
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final list = (body['pendingRequestsByTeam'] as List<dynamic>? ?? [])
      .map((e) => e as Map<String, dynamic>)
      .toList();
  final map = <String, int>{};
  for (final item in list) {
    final teamId = item['teamId'] as String?;
    final count = item['count'] as int? ?? 0;
    if (teamId != null) map[teamId] = count;
  }
  final total = body['totalPending'] as int? ?? 0;
  return PendingRequestsSummary(pendingByTeam: map, totalPending: total);
}

