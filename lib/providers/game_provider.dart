import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../data/isar/models/game.dart';
import '../data/repositories/game_repository.dart';
import 'isar_provider.dart';

final gamesStreamProvider = StreamProvider<List<Game>>((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return GameRepository(isar).watchAllGames();
});

/// Current game by UUID (for awards, dashboard, summary).
final gameByUuidProvider =
    Provider.family<AsyncValue<Game?>, String>((ref, gameUuid) {
  final games = ref.watch(gamesStreamProvider);
  return games.when(
    data: (list) {
      try {
        return AsyncValue.data(list.firstWhere((g) => g.uuid == gameUuid));
      } catch (_) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Game detail by UUID via GameRepository (Isar query). Use for history detail.
final gameDetailProvider =
    FutureProvider.family<Game?, String>((ref, gameUuid) async {
  final isar = await ref.watch(isarProvider.future);
  return GameRepository(isar).getByUuid(gameUuid);
});

/// Present player UUIDs for the upcoming game (team setup screen).
final presentPlayerIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Present player Isar ids for team setup toggle (one per row; avoids duplicate-uuid issues).
final presentPlayerIsarIdsProvider = StateProvider<Set<int>>((ref) => {});

/// Current game UUID being played (dashboard).
final currentGameUuidProvider = StateProvider<String?>((ref) => null);

/// Suggestion for next quarter lineup (5 player UUIDs).
final suggestedLineupProvider = StateProvider<List<String>?>((ref) => null);

/// Quarter number (1..6) the current suggestion targets.
final suggestedQuarterProvider = StateProvider<int?>((ref) => null);

/// For quick swap: first selected player UUID. Null if none selected.
final swapSelectionProvider = StateProvider<String?>((ref) => null);

/// Compute quarters played per player for the current game (from Game.quartersPlayed).
Future<Map<String, int>> getQuartersPlayedForGame(
  Future<Isar> isarFuture,
  String gameUuid,
) async {
  final isar = await isarFuture;
  final game = await GameRepository(isar).getByUuid(gameUuid);
  if (game == null) return {};
  return Map.from(game.quartersPlayed);
}
