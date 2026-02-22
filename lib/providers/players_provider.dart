import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isar/models/player.dart';
import '../data/repositories/player_repository.dart';
import 'isar_provider.dart';

final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  final repo = PlayerRepository(isar);
  return repo.watchAll();
});

final playersFutureProvider = FutureProvider<List<Player>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return PlayerRepository(isar).getAll();
});

/// Players for a given team (by teamId). Authoritative source for "team roster".
final playersForTeamProvider =
    StreamProvider.family<List<Player>, String>((ref, teamId) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return PlayerRepository(isar).watchByTeamId(teamId);
});

Future<List<Player>> getPlayers(WidgetRef ref) async {
  final isar = await ref.read(isarProvider.future);
  return PlayerRepository(isar).getAll();
}

Future<Player?> getPlayerByUuid(WidgetRef ref, String uuid) async {
  final isar = await ref.read(isarProvider.future);
  return PlayerRepository(isar).getByUuid(uuid);
}
