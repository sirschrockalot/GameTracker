import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isar/models/schedule_event.dart';
import '../data/repositories/schedule_repository.dart';
import 'isar_provider.dart';

/// All events for a team (reactive). Filter to upcoming in UI.
final scheduleEventsForTeamProvider =
    StreamProvider.family<List<ScheduleEvent>, String>((ref, teamId) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return ScheduleRepository(isar).watchByTeamId(teamId);
});
