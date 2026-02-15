import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';
import '../../providers/game_provider.dart';
import '../../providers/players_provider.dart';

extension _FirstOrNullSummary<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class GameSummaryScreen extends ConsumerWidget {
  const GameSummaryScreen({super.key, required this.gameUuid});

  final String gameUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameUuid));
    final playersAsync = ref.watch(playersFutureProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Game Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: gameAsync.when(
        data: (game) {
          if (game == null) {
            return const Center(child: Text('Game not found'));
          }
          return playersAsync.when(
            data: (allPlayers) {
              final presentUuids = game.presentPlayerIds.toSet();
              final players = allPlayers
                  .where((p) => presentUuids.contains(p.uuid))
                  .toList();
              return _SummaryBody(game: game, players: players);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.game,
    required this.players,
  });

  final Game game;
  final List<Player> players;

  String _name(String uuid) {
    final p = players.where((x) => x.uuid == uuid).firstOrNull;
    return p?.name ?? '?';
  }

  @override
  Widget build(BuildContext context) {
    final date = game.startedAt;
    final dateStr =
        '${_month(date.month)} ${date.day}, ${date.year} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    final played = game.quartersPlayed;
    final lineups = game.quarterLineups;
    final awards = game.awards;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Date & time',
          child: Text(
            dateStr,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Quarters played',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: played.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${_name(e.key)}: ${e.value}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Quarter lineups',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(AppConstants.quartersPerGame, (i) {
              final q = i + 1;
              final onCourt = lineups[q] ?? <String>[];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q$q',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      onCourt.isEmpty
                          ? '—'
                          : onCourt.map(_name).join(', '),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Awards',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AwardType.values.map((cat) {
              final list = awards[cat] ?? [];
              final label = switch (cat) {
                AwardType.christlike => 'Christlike',
                AwardType.offense => 'Offense',
                AwardType.defense => 'Defense',
                AwardType.hustle => 'Hustle',
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '$label: ${list.isEmpty ? '—' : list.map(_name).join(', ')}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.chipInactive),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
