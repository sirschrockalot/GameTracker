import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';
import '../../data/repositories/game_repository.dart';
import '../../providers/game_provider.dart';
import '../../providers/isar_provider.dart';
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
        actions: [
          if (gameAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteGameDialog(context, ref, gameUuid),
            ),
        ],
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

  Future<void> _showDeleteGameDialog(
    BuildContext context,
    WidgetRef ref,
    String gameUuid,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this game?'),
        content: const Text(
          'This cannot be undone. Schedule and players are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final isar = await ref.read(isarProvider.future);
    await GameRepository(isar).deleteGame(gameUuid);
    ref.invalidate(gameDetailProvider(gameUuid));
    ref.invalidate(gamesStreamProvider);
    if (context.mounted) context.go('/history');
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

  Color _colorForAward(AwardType cat) {
    switch (cat) {
      case AwardType.christlikeness:
        return Colors.grey.shade300;
      case AwardType.defense:
        return Colors.red;
      case AwardType.effort:
        return Colors.blue;
      case AwardType.offense:
        return Colors.grey.shade600;
      case AwardType.sportsmanship:
        return AppColors.saveAwardsGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = game.startedAt;
    final dateStr =
        '${_month(date.month)} ${date.day}, ${date.year} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    final played = game.quartersPlayedDerived;
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
        _FairnessSummarySection(
          played: played,
          players: players,
          nameForUuid: _name,
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
                AwardType.christlikeness => 'Christlikeness',
                AwardType.defense => 'Defense',
                AwardType.effort => 'Effort',
                AwardType.offense => 'Offense',
                AwardType.sportsmanship => 'Sportsmanship',
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: _colorForAward(cat),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label: ${list.isEmpty ? '—' : list.map(_name).join(', ')}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
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

class _FairnessSummarySection extends StatelessWidget {
  const _FairnessSummarySection({
    required this.played,
    required this.players,
    required this.nameForUuid,
  });

  final Map<String, int> played;
  final List<Player> players;
  final String Function(String) nameForUuid;

  Color _statusColor(int diff) {
    if (diff <= 0) return AppColors.onCourtGreen;
    if (diff == 1) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final quartersList = players.map((p) => played[p.uuid] ?? 0).toList();
    final maxQ = quartersList.isEmpty ? 0 : quartersList.reduce((a, b) => a > b ? a : b);
    final minQ = quartersList.isEmpty ? 0 : quartersList.reduce((a, b) => a < b ? a : b);
    final diff = maxQ - minQ;
    final statusColor = _statusColor(diff);

    return _SectionCard(
      title: 'Fairness summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: IntrinsicColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.chipInactive.withValues(alpha: 0.5),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text(
                      'Player',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text(
                      'Quarters',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              ...players.map((p) {
                final q = played[p.uuid] ?? 0;
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text(
                        nameForUuid(p.uuid),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text(
                        '$q',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Difference (max − min): ',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$diff',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      diff <= 0 ? 'Even' : diff == 1 ? '1 behind' : '$diff behind',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
