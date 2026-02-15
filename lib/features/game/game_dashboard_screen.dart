import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/services/lineup_suggester.dart';
import '../../providers/isar_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/players_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final gameUuid = ref.watch(currentGameUuidProvider);
    final playersAsync = ref.watch(playersStreamProvider);
    final suggested = ref.watch(suggestedLineupProvider);
    final suggestedQuarter = ref.watch(suggestedQuarterProvider);
    final swapSelection = ref.watch(swapSelectionProvider);

    if (gameUuid == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No game in progress.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go(AppRoute.teamSetup.path),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                    child: const Text('Start from Team Setup'),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentPath: '/game'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
            List<String> onCourt = lineups[quarterNum] ?? [];
            if (onCourt.length != AppConstants.playersOnCourt &&
                suggested != null &&
                suggestedQuarter == quarterNum &&
                suggested.length == AppConstants.playersOnCourt) {
              onCourt = List.from(suggested);
            } else if (onCourt.length != AppConstants.playersOnCourt) {
              onCourt = [];
            }
            final sitting = presentIds
                .where((uuid) => !onCourt.contains(uuid))
                .toList();
            final nextQuarterForSuggest = (currentQuarter + 1).clamp(1, AppConstants.quartersPerGame);
            final canSuggest = currentQuarter < AppConstants.quartersPerGame && presentPlayers.length >= AppConstants.playersOnCourt;
            final showConfirmForThisQuarter = onCourt.length == AppConstants.playersOnCourt &&
                currentQuarter < quarterNum;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Game Day',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
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
                        final selected = swapSelection == uuid;
                        return _GamePlayerChip(
                          name: p.name,
                          skillTag: p.skill,
                          onCourt: true,
                          selected: selected,
                          onTap: () => _onChipTap(uuid, onCourt, sitting),
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
                        final selected = swapSelection == uuid;
                        return _GamePlayerChip(
                          name: p2.name,
                          skillTag: p2.skill,
                          onCourt: false,
                          selected: selected,
                          onTap: () => _onChipTap(uuid, onCourt, sitting),
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
                                  ? 'Suggest Q$nextQuarterForSuggest Lineup'
                                  : 'All quarters set',
                            ),
                            onPressed: canSuggest
                                ? () => _suggestNextQuarter(
                                        gameUuid, allPlayers, game!)
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
      String playerUuid, List<String> onCourtIds, List<String> sittingIds) {
    if (onCourtIds.length != AppConstants.playersOnCourt) {
      ref.read(swapSelectionProvider.notifier).state = null;
      return;
    }
    final current = ref.read(swapSelectionProvider);
    if (current == null) {
      ref.read(swapSelectionProvider.notifier).state = playerUuid;
      return;
    }
    final currentOnCourt = onCourtIds.contains(current);
    final tappedOnCourt = onCourtIds.contains(playerUuid);
    if (currentOnCourt && !tappedOnCourt) {
      _doSwap(current, playerUuid);
    } else if (!currentOnCourt && tappedOnCourt) {
      _doSwap(playerUuid, current);
    }
    ref.read(swapSelectionProvider.notifier).state = null;
  }

  Future<void> _doSwap(String fromOnCourt, String fromSitting) async {
    final gameUuid = ref.read(currentGameUuidProvider);
    if (gameUuid == null) return;
    final isar = await ref.read(isarProvider.future);
    final gameRepo = GameRepository(isar);
    final game = await gameRepo.getByUuid(gameUuid);
    if (game == null) return;
    final quarterNum = _selectedQuarter + 1;
    final lineups = Map<int, List<String>>.from(game.quarterLineups);
    final current = lineups[quarterNum] ?? [];
    final i = current.indexOf(fromOnCourt);
    if (i < 0) return;
    final next = List<String>.from(current);
    next[i] = fromSitting;
    lineups[quarterNum] = next;
    game.quarterLineups = lineups;
    await isar.writeTxn(() => isar.games.put(game));
    if (ref.read(suggestedQuarterProvider) == quarterNum) {
      ref.read(suggestedLineupProvider.notifier).state = null;
      ref.read(suggestedQuarterProvider.notifier).state = null;
    }
  }

  void _suggestNextQuarter(
      String gameUuid, List<Player> presentPlayers, Game game) {
    final currentQuarter =
        game.currentQuarter.clamp(1, AppConstants.quartersPerGame);
    final nextQuarter =
        (currentQuarter + 1).clamp(1, AppConstants.quartersPerGame);
    if (nextQuarter <= currentQuarter) return;
    final lineups = game.quarterLineups;
    final lastLineup = lineups[currentQuarter] ?? [];
    final presentIds = game.presentPlayerIds.toSet();
    final lastSitting =
        presentIds.where((id) => !lastLineup.contains(id)).toList();
    final suggestion = suggestLineup(
      presentPlayers: presentPlayers,
      quartersPlayed: Map.from(game.quartersPlayed),
      lastQuarterLineup: lastLineup,
      lastQuarterSitting: lastSitting,
      nextQuarter: nextQuarter,
      requiredOnCourt: AppConstants.playersOnCourt,
    );
    ref.read(suggestedLineupProvider.notifier).state = suggestion.onCourt;
    ref.read(suggestedQuarterProvider.notifier).state = nextQuarter;
    setState(() => _selectedQuarter = nextQuarter - 1);
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
    setState(() => _selectedQuarter = q - 1);
  }

  Future<void> _confirmLineup(
      String gameUuid, int quarterNum, List<String> onCourt) async {
    if (onCourt.length != AppConstants.playersOnCourt) return;
    final isar = await ref.read(isarProvider.future);
    final gameRepo = GameRepository(isar);
    final game = await gameRepo.getByUuid(gameUuid);
    if (game == null) return;
    final played = Map<String, int>.from(game.quartersPlayed);
    for (final uuid in onCourt) {
      played[uuid] = (played[uuid] ?? 0) + 1;
    }
    await gameRepo.updateQuartersPlayed(gameUuid, played);
    await gameRepo.updateCurrentQuarter(gameUuid, quarterNum);
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
