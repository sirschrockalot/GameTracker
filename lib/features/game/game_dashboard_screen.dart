import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/glass_tokens.dart';
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
import '../../widgets/confetti_overlay.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/team_logo_avatar.dart';

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
  /// When set, this quarter (1-based) is being edited even though it's locked (e.g. injury sub).
  int? _editingQuarter;

  @override
  Widget build(BuildContext context) {
    final gameUuid = ref.watch(currentGameUuidProvider);
    final playersAsync = ref.watch(playersStreamProvider);
    final suggested = ref.watch(suggestedLineupProvider);
    final suggestedQuarter = ref.watch(suggestedQuarterProvider);

    if (gameUuid == null) {
      final teamsAsync = ref.watch(teamsStreamProvider);
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: GlassBackground(
          child: SafeArea(
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
        ),
        bottomNavigationBar: const AppBottomNav(currentPath: '/game'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
      body: GlassBackground(
        child: SafeArea(
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
            final completedQuarters = game.completedQuarters;
            final allQuartersSet = firstEmptyQuarter == null;
            final suggestTargetQuarter = firstEmptyQuarter ?? quarterNum;
            final canSuggest = !allQuartersSet &&
                presentPlayers.length >= AppConstants.playersOnCourt &&
                firstEmptyQuarter != null &&
                !completedQuarters.contains(suggestTargetQuarter);
            // Lock indicator on tab: completed quarters (hard lock).
            final lockedQuarterIndices = <int>{
              for (int q in completedQuarters) q - 1
            };
            final isCurrentQuarterLocked = completedQuarters.contains(quarterNum) ||
                (lockedQuarterIndices.contains(_selectedQuarter) && _editingQuarter != quarterNum);
            final showConfirmForThisQuarter = !isCurrentQuarterLocked &&
                onCourt.length == AppConstants.playersOnCourt &&
                (currentQuarter < quarterNum || _editingQuarter == quarterNum);
            final showEditForLockedQuarter = lineups[quarterNum] != null &&
                lineups[quarterNum]!.length == AppConstants.playersOnCourt &&
                !completedQuarters.contains(quarterNum) &&
                _editingQuarter != quarterNum;
            final showCompleteQuarter = lineups[quarterNum] != null &&
                lineups[quarterNum]!.length == AppConstants.playersOnCourt &&
                !completedQuarters.contains(quarterNum);
            final showAutoFillRemaining = currentQuarter < AppConstants.quartersPerGame &&
                presentPlayers.length >= AppConstants.playersOnCourt;

            // Effective quarters played: saved + draft (including auto-fill) so fairness reflects current state
            final effectiveQuartersPlayed = <String, int>{};
            for (int q = 1; q <= AppConstants.quartersPerGame; q++) {
              final lineup = _draftLineups[q] ?? lineups[q];
              if (lineup != null && lineup.length == AppConstants.playersOnCourt) {
                for (final uuid in lineup) {
                  effectiveQuartersPlayed[uuid] = (effectiveQuartersPlayed[uuid] ?? 0) + 1;
                }
              }
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _QuarterTabs(
                    selected: _selectedQuarter,
                    lockedIndices: lockedQuarterIndices,
                    onSelect: (q) => setState(() {
                      if (_editingQuarter != null) {
                        _draftLineups.remove(_editingQuarter);
                        _editingQuarter = null;
                      }
                      _selectedQuarter = q;
                    }),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                      child: _FairnessSection(
                        presentUuids: presentIds.toList(),
                        quartersPlayed: effectiveQuartersPlayed,
                        players: presentPlayers,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: Wrap(
                              key: ValueKey<String>('onCourt-${onCourt.join(',')}'),
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
                                  onTap: isCurrentQuarterLocked ? null : () => _onChipTap(uuid, onCourt, sitting, gameUuid),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: Wrap(
                              key: ValueKey<String>('sitting-${sitting.join(',')}'),
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
                                  onTap: isCurrentQuarterLocked ? null : () => _onChipTap(uuid, onCourt, sitting, gameUuid),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
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
                            suggested.length == AppConstants.playersOnCourt &&
                            suggestedQuarter != null &&
                            !completedQuarters.contains(suggestedQuarter)) ...[
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
                        if (showCompleteQuarter) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _showCompleteQuarterDialog(context, gameUuid, quarterNum),
                              icon: const Icon(Icons.lock, size: 20),
                              label: Text('Complete Q$quarterNum'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                        if (showEditForLockedQuarter) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final saved = lineups[quarterNum];
                                if (saved != null && saved.length == AppConstants.playersOnCourt) {
                                  _startEditingQuarter(quarterNum, List.from(saved));
                                }
                              },
                              icon: const Icon(Icons.edit_outlined, size: 22),
                              label: Text('Edit Q$quarterNum lineup'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (showAutoFillRemaining) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.auto_fix_high, size: 22),
                              label: const Text('Auto Fill Remaining'),
                              onPressed: () => _autoFillRemaining(gameUuid, game!, presentPlayers),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/game'),
    );
  }

  void _startEditingQuarter(int quarterNum, List<String> savedLineup) {
    setState(() {
      _editingQuarter = quarterNum;
      _draftLineups[quarterNum] = List<String>.from(savedLineup);
    });
  }

  void _hapticForAction() {
    if (!mounted) return;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _onChipTap(
      String playerUuid,
      List<String> onCourtIds,
      List<String> sittingIds,
      String gameUuid) {
    final quarterNum = _selectedQuarter + 1;

    if (onCourtIds.contains(playerUuid)) {
      _removeFromCourt(quarterNum, playerUuid, onCourtIds);
      _hapticForAction();
      return;
    }

    if (onCourtIds.length < AppConstants.playersOnCourt) {
      _addToCourt(quarterNum, playerUuid, onCourtIds);
      _hapticForAction();
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
      quartersPlayed: Map.from(game.quartersPlayedDerived),
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
    final existing = game.quarterLineups[q];
    if (existing != null && existing.length == AppConstants.playersOnCourt) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Overwrite lineup?'),
          content: Text('Q$q already has a lineup. Replace it with this suggestion?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    await gameRepo.updateLineupForQuarter(gameUuid, q, suggested);
    await gameRepo.updateCurrentQuarter(gameUuid, q);
    _hapticForAction();
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lineup applied')),
      );
    }
  }

  Future<void> _showCompleteQuarterDialog(
    BuildContext context,
    String gameUuid,
    int quarterNum,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Complete Q$quarterNum?'),
        content: const Text(
          'Lock this quarter? No more changes to its lineup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final isar = await ref.read(isarProvider.future);
    final ok = await GameRepository(isar).markQuarterCompleted(gameUuid, quarterNum);
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Q$quarterNum completed')),
        );
      }
    }
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
    if (!context.mounted) return;
    showConfettiOverlay(
      context,
      onComplete: () {
        ref.read(currentGameUuidProvider.notifier).state = null;
        ref.read(suggestedLineupProvider.notifier).state = null;
        ref.read(suggestedQuarterProvider.notifier).state = null;
        ref.read(swapSelectionProvider.notifier).state = null;
        if (context.mounted) {
          context.go('/history');
          context.push('/history/$gameUuid');
        }
      },
    );
  }

  Future<void> _autoFillRemaining(
    String gameUuid,
    Game game,
    List<Player> presentPlayers,
  ) async {
    final startQ = game.currentQuarter + 1;
    if (startQ > AppConstants.quartersPerGame) return;
    final presentIds = game.presentPlayerIds.toSet();
    if (presentIds.length < AppConstants.playersOnCourt) return;
    final completed = game.completedQuarters;

    Map<String, int> quartersPlayed = Map.from(game.quartersPlayedDerived);
    List<String> lastLineup = game.quarterLineups[startQ - 1] ?? [];
    final suggested = <int, List<String>>{};
    for (int q = startQ; q <= AppConstants.quartersPerGame; q++) {
      if (completed.contains(q)) {
        lastLineup = game.quarterLineups[q] ?? lastLineup;
        continue;
      }
      final lastSitting =
          presentIds.difference(lastLineup.toSet()).toList();
      final suggestion = suggestLineup(
        presentPlayers: presentPlayers,
        quartersPlayed: quartersPlayed,
        lastQuarterLineup: lastLineup,
        lastQuarterSitting: lastSitting,
        nextQuarter: q,
        requiredOnCourt: AppConstants.playersOnCourt,
      );
      suggested[q] = List.from(suggestion.onCourt);
      for (final uuid in suggestion.onCourt) {
        quartersPlayed[uuid] = (quartersPlayed[uuid] ?? 0) + 1;
      }
      lastLineup = suggestion.onCourt;
    }

    final lineups = game.quarterLineups;
    final existingQuarters = <int>[
      for (int q = startQ; q <= AppConstants.quartersPerGame; q++)
        if (!completed.contains(q) &&
            lineups[q] != null &&
            lineups[q]!.length == AppConstants.playersOnCourt) q
    ];

    Map<int, List<String>> toApply;
    if (existingQuarters.isEmpty) {
      toApply = suggested;
    } else {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Overwrite existing quarters?'),
          content: Text(
            'Quarter${existingQuarters.length == 1 ? '' : 's'} '
            'Q${existingQuarters.join(', Q')} already '
            '${existingQuarters.length == 1 ? 'has' : 'have'} a lineup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('skip'),
              child: const Text('Skip Existing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('overwrite'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              child: const Text('Overwrite All'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel' || !mounted) return;
      if (choice == 'skip') {
        toApply = {for (final e in suggested.entries) if (!existingQuarters.contains(e.key)) e.key: e.value};
      } else {
        toApply = suggested;
      }
    }

    if (toApply.isEmpty) return;

    ref.read(suggestedLineupProvider.notifier).state = null;
    ref.read(suggestedQuarterProvider.notifier).state = null;
    setState(() {
      for (final e in toApply.entries) _draftLineups[e.key] = e.value;
      final firstFilled = toApply.keys.reduce((a, b) => a < b ? a : b);
      _selectedQuarter = (firstFilled - 1).clamp(0, AppConstants.quartersPerGame - 1);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Remaining quarters filled. Edit lineups as needed, then confirm each quarter when ready.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmLineup(
      String gameUuid, int quarterNum, List<String> onCourt) async {
    if (onCourt.length != AppConstants.playersOnCourt) return;
    final isar = await ref.read(isarProvider.future);
    final gameRepo = GameRepository(isar);
    final game = await gameRepo.getByUuid(gameUuid);
    if (game == null) return;
    final existing = game.quarterLineups[quarterNum];
    if (existing != null && existing.length == AppConstants.playersOnCourt) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Overwrite lineup?'),
          content: Text(
            'Q$quarterNum already has a lineup. Replace it with the current on-court players?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    await gameRepo.updateLineupForQuarter(gameUuid, quarterNum, onCourt);
    await gameRepo.updateCurrentQuarter(gameUuid, quarterNum);
    _hapticForAction();
    setState(() {
      _draftLineups.remove(quarterNum);
      if (_editingQuarter == quarterNum) _editingQuarter = null;
    });
    if (ref.read(suggestedQuarterProvider) == quarterNum) {
      ref.read(suggestedLineupProvider.notifier).state = null;
      ref.read(suggestedQuarterProvider.notifier).state = null;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Q$quarterNum lineup confirmed')),
      );
    }
  }
}

class _QuarterTabs extends StatelessWidget {
  const _QuarterTabs({
    required this.selected,
    required this.lockedIndices,
    required this.onSelect,
  });

  final int selected;
  final Set<int> lockedIndices;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(AppConstants.quartersPerGame, (i) {
          final isSelected = selected == i;
          final isLocked = lockedIndices.contains(i);
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Q${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ],
                      ],
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

  /// Behind if played < floor(avg) OR (max - played) >= 1.
  static bool _isBehind(int played, int floorAvg, int maxPlayed) {
    return played < floorAvg || (maxPlayed - played) >= 1;
  }

  @override
  Widget build(BuildContext context) {
    final counts =
        presentUuids.map((uuid) => quartersPlayed[uuid] ?? 0).toList();
    final sum = counts.isEmpty ? 0 : counts.reduce((a, b) => a + b);
    final n = presentUuids.length;
    final floorAvg = n > 0 ? sum ~/ n : 0;
    final avg = n > 0 ? sum / n : 0.0;
    final maxP = counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
    final minP = counts.isEmpty ? 0 : counts.reduce((a, b) => a < b ? a : b);
    final gap = maxP - minP;
    final teamBalanced = gap <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'FAIRNESS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'avg ${avg.toStringAsFixed(1)} · gap $gap',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...presentUuids.map((uuid) {
            final p = players.where((x) => x.uuid == uuid).firstOrNull;
            final name = p?.name ?? '?';
            final played = quartersPlayed[uuid] ?? 0;
            final behind = _isBehind(played, floorAvg, maxP);
            final statusColor = behind
                ? AppColors.fairnessBehind
                : (teamBalanced ? AppColors.onCourtGreen : AppColors.textSecondary);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _MiniBar(played: played),
                  const SizedBox(width: 6),
                  Text(
                    '$played',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  if (behind) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.fairnessBehind),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.played});

  final int played;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(AppConstants.quartersPerGame, (i) {
        final filled = i < played;
        return Container(
          width: 8,
          height: 10,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: filled
                ? Theme.of(context).colorScheme.primary
                : AppColors.chipInactive,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

class _GamePlayerChip extends StatelessWidget {
  const _GamePlayerChip({
    required this.name,
    required this.skillTag,
    required this.onCourt,
    required this.selected,
    this.onTap,
  });

  final String name;
  final Skill skillTag;
  final bool onCourt;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onCourt ? AppColors.onCourtGreen : AppColors.chipInactive,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        leading: TeamLogoAvatar(team: team, size: 40),
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
