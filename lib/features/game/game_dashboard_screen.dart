import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/services/lineup_suggester.dart';
import '../../providers/isar_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/players_provider.dart';
import '../../providers/teams_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/app_bottom_nav.dart';

class GameDashboardScreen extends ConsumerStatefulWidget {
  const GameDashboardScreen({super.key});

  @override
  ConsumerState<GameDashboardScreen> createState() =>
      _GameDashboardScreenState();
}

class _GameDashboardScreenState extends ConsumerState<GameDashboardScreen> {
  int _selectedQuarter = 0;
  /// In-progress lineup per quarter (1-based) before confirm. Used when < 5 saved.
  final Map<int, List<String>> _draftLineups = {};

  @override
  Widget build(BuildContext context) {
    final gameUuid = ref.watch(currentGameUuidProvider);
    final playersAsync = ref.watch(playersStreamProvider);
    final suggested = ref.watch(suggestedLineupProvider);
    final suggestedQuarter = ref.watch(suggestedQuarterProvider);

    if (gameUuid == null) {
      final teamsAsync = ref.watch(teamsStreamProvider);
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Game Day',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select a team to start a game',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: teamsAsync.when(
                  data: (teams) {
                    if (teams.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No teams yet. Create a team in the Teams tab first.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: teams.length,
                      itemBuilder: (context, i) {
                        final team = teams[i];
                        return _GameDayTeamCard(team: team);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentPath: '/game'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Game Day',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showEndGameDialog(context, gameUuid),
              icon: const Icon(Icons.stop_circle_outlined, size: 20),
              label: const Text('End Game'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: playersAsync.when(
          data: (allPlayers) {
            final games = ref.watch(gamesStreamProvider).valueOrNull ?? [];
            Game? game;
            try {
              game = games.firstWhere((g) => g.uuid == gameUuid);
            } catch (_) {
              game = null;
            }
            if (game == null) {
              return const Center(child: Text('Game not found'));
            }
            final presentIds = game.presentPlayerIds.toSet();
            final presentPlayers =
                allPlayers.where((p) => presentIds.contains(p.uuid)).toList();
            final quarterNum = _selectedQuarter + 1;
            final lineups = game.quarterLineups;
            final currentQuarter = game.currentQuarter.clamp(0, AppConstants.quartersPerGame);
            final saved = lineups[quarterNum];
            List<String> onCourt;
            if (_draftLineups.containsKey(quarterNum)) {
              onCourt = List<String>.from(_draftLineups[quarterNum]!);
            } else if (saved != null && saved.length == AppConstants.playersOnCourt) {
              onCourt = List.from(saved);
            } else if (suggested != null &&
                suggestedQuarter == quarterNum &&
                suggested.length == AppConstants.playersOnCourt) {
              onCourt = List.from(suggested);
            } else {
              onCourt = List<String>.from(_draftLineups[quarterNum] ?? []);
            }
            final sitting = presentIds
                .where((uuid) => !onCourt.contains(uuid))
                .toList();
            // First quarter (1..6) that has no full lineup yet
            int? firstEmptyQuarter;
            for (int q = 1; q <= AppConstants.quartersPerGame; q++) {
              final sq = lineups[q];
              if (sq == null || sq.length != AppConstants.playersOnCourt) {
                firstEmptyQuarter = q;
                break;
              }
            }
            final allQuartersSet = firstEmptyQuarter == null;
            final canSuggest = !allQuartersSet &&
                presentPlayers.length >= AppConstants.playersOnCourt &&
                firstEmptyQuarter != null;
            final suggestTargetQuarter = firstEmptyQuarter ?? quarterNum;
            final showConfirmForThisQuarter = onCourt.length == AppConstants.playersOnCourt &&
                currentQuarter < quarterNum;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _QuarterTabs(
                    selected: _selectedQuarter,
                    onSelect: (q) => setState(() => _selectedQuarter = q),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<Map<String, int>>(
                    future: getQuartersPlayedForGame(
                        ref.read(isarProvider.future), gameUuid),
                    builder: (context, snap) {
                      final played = snap.data ?? {};
                      return _FairnessSection(
                        presentUuids: presentIds.toList(),
                        quartersPlayed: played,
                        players: presentPlayers,
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.onCourtGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ON COURT (${onCourt.length}/${AppConstants.playersOnCourt})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: onCourt.map((uuid) {
                        Player p;
                        try {
                          p = allPlayers.firstWhere((x) => x.uuid == uuid);
                        } catch (_) {
                          p = Player.create(uuid: uuid, name: '?');
                        }
                        return _GamePlayerChip(
                          name: p.name,
                          skillTag: p.skill,
                          onCourt: true,
                          selected: false,
                          onTap: () => _onChipTap(uuid, onCourt, sitting, gameUuid),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.chipInactive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SITTING (${sitting.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sitting.map((uuid) {
                        Player p2;
                        try {
                          p2 = allPlayers.firstWhere((x) => x.uuid == uuid);
                        } catch (_) {
                          p2 = Player.create(uuid: uuid, name: '?');
                        }
                        return _GamePlayerChip(
                          name: p2.name,
                          skillTag: p2.skill,
                          onCourt: false,
                          selected: false,
                          onTap: () => _onChipTap(uuid, onCourt, sitting, gameUuid),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.lightbulb_outline, size: 22),
                            label: Text(
                              canSuggest
                                  ? 'Suggest Q$suggestTargetQuarter Lineup'
                                  : 'All quarters set',
                            ),
                            onPressed: canSuggest
                                ? () => _suggestNextQuarter(
                                        gameUuid, presentPlayers, game!,
                                        forQuarter: suggestTargetQuarter)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (suggested != null &&
                            suggested.length == AppConstants.playersOnCourt) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: () => _applySuggestion(gameUuid),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Apply Suggestion'),
                            ),
                          ),
                        ],
                        if (showConfirmForThisQuarter) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () =>
                                  _confirmLineup(gameUuid, quarterNum, onCourt),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Confirm lineup for Q$quarterNum'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/game'),
    );
  }

  void _onChipTap(
      String playerUuid,
      List<String> onCourtIds,
      List<String> sittingIds,
      String gameUuid) {
    final quarterNum = _selectedQuarter + 1;

    if (onCourtIds.contains(playerUuid)) {
      _removeFromCourt(quarterNum, playerUuid, onCourtIds);
      return;
    }

    if (onCourtIds.length < AppConstants.playersOnCourt) {
      _addToCourt(quarterNum, playerUuid, onCourtIds);
    }
  }

  void _addToCourt(int quarterNum, String playerUuid, List<String> currentOnCourt) {
    if (currentOnCourt.length >= AppConstants.playersOnCourt) return;
    if (ref.read(suggestedQuarterProvider) == quarterNum) {
      ref.read(suggestedLineupProvider.notifier).state = null;
      ref.read(suggestedQuarterProvider.notifier).state = null;
    }
    setState(() {
      _draftLineups[quarterNum] = List<String>.from(currentOnCourt)..add(playerUuid);
    });
  }

  void _removeFromCourt(int quarterNum, String playerUuid, List<String> currentOnCourt) {
    if (ref.read(suggestedQuarterProvider) == quarterNum) {
      ref.read(suggestedLineupProvider.notifier).state = null;
      ref.read(suggestedQuarterProvider.notifier).state = null;
    }
    setState(() {
      final next = List<String>.from(currentOnCourt)..remove(playerUuid);
      _draftLineups[quarterNum] = next;
    });
  }

  void _suggestNextQuarter(
    String gameUuid,
    List<Player> presentPlayers,
    Game game, {
    required int forQuarter,
  }) {
    if (forQuarter < 1 || forQuarter > AppConstants.quartersPerGame) return;
    final lineups = game.quarterLineups;
    final lastLineup = lineups[forQuarter - 1] ?? [];
    final presentIds = game.presentPlayerIds.toSet();
    final lastSitting =
        presentIds.where((id) => !lastLineup.contains(id)).toList();
    final suggestion = suggestLineup(
      presentPlayers: presentPlayers,
      quartersPlayed: Map.from(game.quartersPlayed),
      lastQuarterLineup: lastLineup,
      lastQuarterSitting: lastSitting,
      nextQuarter: forQuarter,
      requiredOnCourt: AppConstants.playersOnCourt,
    );
    ref.read(suggestedLineupProvider.notifier).state = suggestion.onCourt;
    ref.read(suggestedQuarterProvider.notifier).state = forQuarter;
    setState(() => _selectedQuarter = forQuarter - 1);
  }

  Future<void> _applySuggestion(String gameUuid) async {
    final suggested = ref.read(suggestedLineupProvider);
    final q = ref.read(suggestedQuarterProvider);
    if (suggested == null ||
        suggested.length != AppConstants.playersOnCourt ||
        q == null) {
      return;
    }
    final isar = await ref.read(isarProvider.future);
    final gameRepo = GameRepository(isar);
    final game = await gameRepo.getByUuid(gameUuid);
    if (game == null) return;
    await gameRepo.updateLineupForQuarter(gameUuid, q, suggested);
    final played = Map<String, int>.from(game.quartersPlayed);
    for (final uuid in suggested) {
      played[uuid] = (played[uuid] ?? 0) + 1;
    }
    await gameRepo.updateQuartersPlayed(gameUuid, played);
    await gameRepo.updateCurrentQuarter(gameUuid, q);
    ref.read(suggestedLineupProvider.notifier).state = null;
    ref.read(suggestedQuarterProvider.notifier).state = null;
    // Switch to next quarter that has no lineup so user can suggest again
    final updated = await gameRepo.getByUuid(gameUuid);
    final lineupsAfter = updated?.quarterLineups ?? {};
    int nextTab = q - 1;
    for (int qn = q + 1; qn <= AppConstants.quartersPerGame; qn++) {
      final sq = lineupsAfter[qn];
      if (sq == null || sq.length != AppConstants.playersOnCourt) {
        nextTab = qn - 1;
        break;
      }
    }
    setState(() {
      _draftLineups.remove(q);
      _selectedQuarter = nextTab;
    });
  }

  Future<void> _showEndGameDialog(BuildContext context, String gameUuid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End game?'),
        content: const Text(
          'All lineups and playing time are saved. You can view the full summary with who played which quarters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            child: const Text('End game'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    ref.read(currentGameUuidProvider.notifier).state = null;
    ref.read(suggestedLineupProvider.notifier).state = null;
    ref.read(suggestedQuarterProvider.notifier).state = null;
    ref.read(swapSelectionProvider.notifier).state = null;
    if (context.mounted) {
      context.go('/history');
      context.push('/history/$gameUuid');
    }
  }

  Future<void> _confirmLineup(
      String gameUuid, int quarterNum, List<String> onCourt) async {
    if (onCourt.length != AppConstants.playersOnCourt) return;
    final isar = await ref.read(isarProvider.future);
    final gameRepo = GameRepository(isar);
    final game = await gameRepo.getByUuid(gameUuid);
    if (game == null) return;
    await gameRepo.updateLineupForQuarter(gameUuid, quarterNum, onCourt);
    final played = Map<String, int>.from(game.quartersPlayed);
    for (final uuid in onCourt) {
      played[uuid] = (played[uuid] ?? 0) + 1;
    }
    await gameRepo.updateQuartersPlayed(gameUuid, played);
    await gameRepo.updateCurrentQuarter(gameUuid, quarterNum);
    setState(() => _draftLineups.remove(quarterNum));
    if (ref.read(suggestedQuarterProvider) == quarterNum) {
      ref.read(suggestedLineupProvider.notifier).state = null;
      ref.read(suggestedQuarterProvider.notifier).state = null;
    }
  }
}

class _QuarterTabs extends StatelessWidget {
  const _QuarterTabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(AppConstants.quartersPerGame, (i) {
          final isSelected = selected == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.chipInactive,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text(
                    'Q${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FairnessSection extends StatelessWidget {
  const _FairnessSection({
    required this.presentUuids,
    required this.quartersPlayed,
    required this.players,
  });

  final List<String> presentUuids;
  final Map<String, int> quartersPlayed;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final counts =
        presentUuids.map((uuid) => quartersPlayed[uuid] ?? 0).toList();
    final sum = counts.isEmpty ? 0 : counts.reduce((a, b) => a + b);
    final n = presentUuids.length;
    final floorAvg = n > 0 ? sum ~/ n : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAIRNESS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presentUuids.map((uuid) {
              final p = players.where((x) => x.uuid == uuid).firstOrNull;
              final name = p?.name ?? '?';
              final played = quartersPlayed[uuid] ?? 0;
              final behind = played < floorAvg;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: behind
                      ? AppColors.fairnessBehind.withValues(alpha: 0.4)
                      : AppColors.chipInactive,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (behind)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    Text(
                      '$name · Played: $played',
                      style: TextStyle(
                        color: behind
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GamePlayerChip extends StatelessWidget {
  const _GamePlayerChip({
    required this.name,
    required this.skillTag,
    required this.onCourt,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Skill skillTag;
  final bool onCourt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onCourt ? AppColors.onCourtGreen : AppColors.chipInactive,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: selected
                ? Border.all(color: AppColors.primaryOrange, width: 2)
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: skillTag == Skill.strong
                      ? AppColors.skillStrong
                      : AppColors.skillDev,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: onCourt ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameDayTeamCard extends StatelessWidget {
  const _GameDayTeamCard({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.chipInactive),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.groups,
            color: AppColors.primaryOrange,
            size: 24,
          ),
        ),
        title: Text(
          team.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${team.playerIds.length} players',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => context.push('/game/whos-here/${team.uuid}'),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
