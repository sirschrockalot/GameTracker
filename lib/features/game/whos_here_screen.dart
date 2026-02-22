import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/game_repository.dart';
import '../../providers/isar_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/teams_provider.dart';
import '../../providers/players_provider.dart';
import '../../widgets/app_bottom_nav.dart';

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class WhosHereScreen extends ConsumerStatefulWidget {
  const WhosHereScreen({super.key, required this.teamUuid});

  final String teamUuid;

  @override
  ConsumerState<WhosHereScreen> createState() => _WhosHereScreenState();
}

class _WhosHereScreenState extends ConsumerState<WhosHereScreen> {
  final Set<String> _selectedPlayerIds = {};

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final playersAsync = ref.watch(playersFutureProvider);

    Team? team;
    try {
      team = teamsAsync.valueOrNull?.firstWhere((t) => t.uuid == widget.teamUuid);
    } catch (_) {}

    if (team == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Team not found'),
        ),
        body: const Center(child: Text('Team not found')),
        bottomNavigationBar: const AppBottomNav(currentPath: '/game'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('${team!.name} — Who\'s Here?'),
        centerTitle: true,
      ),
      body: playersAsync.when(
        data: (allPlayers) {
          final teamPlayers = team!.playerIds
              .map((uuid) => allPlayers.where((p) => p.uuid == uuid).firstOrNull)
              .whereType<Player>()
              .toList();

          if (teamPlayers.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No players on this team. Add players in team details first.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Tap players who are present today (${_selectedPlayerIds.length} selected)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: teamPlayers.length,
                  itemBuilder: (context, i) {
                    final p = teamPlayers[i];
                    final selected = _selectedPlayerIds.contains(p.uuid);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedPlayerIds.remove(p.uuid);
                              } else {
                                _selectedPlayerIds.add(p.uuid);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppColors.onCourtGreen : AppColors.chipInactive,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 28,
                                  color: selected ? AppColors.onCourtGreen : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                _SkillChip(skill: p.skill),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: FilledButton(
                  onPressed: _selectedPlayerIds.length >= AppConstants.playersOnCourt
                      ? () => _startGame(context, ref, team!, _selectedPlayerIds.toList())
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedPlayerIds.length >= AppConstants.playersOnCourt
                        ? 'Start Game (${_selectedPlayerIds.length} players)'
                        : 'Select at least ${AppConstants.playersOnCourt} players',
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/game'),
    );
  }

  Future<void> _startGame(
    BuildContext context,
    WidgetRef ref,
    Team team,
    List<String> presentPlayerIds,
  ) async {
    if (presentPlayerIds.length < AppConstants.playersOnCourt) return;
    final isar = await ref.read(isarProvider.future);
    final repo = GameRepository(isar);
    final game = Game.create(
      uuid: const Uuid().v4(),
      startedAt: DateTime.now(),
      currentQuarter: 0,
      presentPlayerIds: presentPlayerIds,
      teamId: team.uuid,
    );
    await repo.createGame(game);
    if (presentPlayerIds.length == AppConstants.playersOnCourt) {
      for (int q = 1; q <= AppConstants.quartersPerGame; q++) {
        await repo.updateLineupForQuarter(game.uuid, q, presentPlayerIds);
      }
      await repo.updateCurrentQuarter(game.uuid, AppConstants.quartersPerGame);
    }
    ref.read(currentGameUuidProvider.notifier).state = game.uuid;
    ref.read(suggestedLineupProvider.notifier).state = null;
    ref.read(suggestedQuarterProvider.notifier).state = null;
    ref.read(swapSelectionProvider.notifier).state = null;
    if (context.mounted) {
      context.go('/game');
    }
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final isStrong = skill == Skill.strong;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isStrong ? AppColors.skillStrong : AppColors.skillDev).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isStrong ? 'Strong' : 'Dev',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isStrong ? AppColors.skillStrong : AppColors.skillDev,
        ),
      ),
    );
  }
}
