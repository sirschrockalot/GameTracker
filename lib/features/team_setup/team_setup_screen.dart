import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../providers/isar_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/players_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/app_bottom_nav.dart';

class TeamSetupScreen extends ConsumerStatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  ConsumerState<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends ConsumerState<TeamSetupScreen> {
  final _nameController = TextEditingController();
  String? _editingUuid;
  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final isar = await ref.read(isarProvider.future);
    final player = Player.create(uuid: _uuid.v4(), name: name);
    await PlayerRepository(isar).add(player);
    _nameController.clear();
    setState(() => _editingUuid = null);
  }

  Future<void> _updatePlayer(Player p) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    p.name = name;
    final isar = await ref.read(isarProvider.future);
    await PlayerRepository(isar).update(p);
    _nameController.clear();
    setState(() => _editingUuid = null);
  }

  void _togglePresent(String playerUuid) {
    ref.read(presentPlayerIdsProvider.notifier).update((state) {
      final next = Set<String>.from(state);
      if (next.contains(playerUuid)) {
        next.remove(playerUuid);
      } else {
        next.add(playerUuid);
      }
      return next;
    });
  }

  Future<void> _toggleSkill(Player p) async {
    p.skill = p.skill == Skill.strong ? Skill.developing : Skill.strong;
    final isar = await ref.read(isarProvider.future);
    await PlayerRepository(isar).update(p);
  }

  Future<void> _startGame() async {
    final presentIds = ref.read(presentPlayerIdsProvider);
    if (presentIds.length < AppConstants.playersOnCourt) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mark at least 5 players present to start.',
            ),
          ),
        );
      }
      return;
    }
    final isar = await ref.read(isarProvider.future);
    final game = Game.create(
      uuid: _uuid.v4(),
      startedAt: DateTime.now(),
      currentQuarter: 0,
      presentPlayerIds: presentIds.toList(),
    );
    await GameRepository(isar).createGame(game);
    ref.read(currentGameUuidProvider.notifier).state = game.uuid;
    ref.read(suggestedLineupProvider.notifier).state = null;
    ref.read(suggestedQuarterProvider.notifier).state = null;
    ref.read(swapSelectionProvider.notifier).state = null;
    if (mounted) context.go(AppRoute.gameDashboard.path);
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersStreamProvider);
    final presentIds = ref.watch(presentPlayerIdsProvider);
    final presentCount = presentIds.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Team Setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$presentCount players present today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Add or edit player',
                        filled: true,
                        fillColor: AppColors.chipInactive.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_editingUuid != null) {
                          try {
                            final players = playersAsync.valueOrNull ?? [];
                            final p = players.firstWhere((x) => x.uuid == _editingUuid);
                            _updatePlayer(p);
                          } catch (_) {}
                        } else {
                          _addPlayer();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      if (_editingUuid != null) {
                        try {
                          final players = playersAsync.valueOrNull ?? [];
                          final p = players.firstWhere((x) => x.uuid == _editingUuid);
                          _updatePlayer(p);
                        } catch (_) {}
                      } else {
                        _addPlayer();
                      }
                    },
                    icon: Icon(_editingUuid != null ? Icons.check : Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: playersAsync.when(
                data: (players) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: players.length,
                    itemBuilder: (context, i) {
                      final p = players[i];
                      final present = presentIds.contains(p.uuid);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.chipInactive.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _togglePresent(p.uuid),
                              borderRadius: BorderRadius.circular(20),
                              child: Icon(
                                present ? Icons.check_circle : Icons.cancel_outlined,
                                color: present
                                    ? AppColors.onCourtGreen
                                    : AppColors.textSecondary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _nameController.text = p.name;
                                setState(() => _editingUuid = p.uuid);
                              },
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 22,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: p.skill == Skill.strong
                                  ? AppColors.skillStrong
                                  : AppColors.skillDev,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => _toggleSkill(p),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Text(
                                    p.skill == Skill.strong
                                        ? 'Strong'
                                        : 'Dev',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow, size: 24),
                  label: Text('Start Game ($presentCount players)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/'),
    );
  }
}
