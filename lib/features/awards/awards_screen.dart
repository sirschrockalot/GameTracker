import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../data/isar/models/player.dart';
import '../../data/repositories/game_repository.dart';
import '../../providers/isar_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/players_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/app_bottom_nav.dart';

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class AwardsScreen extends ConsumerStatefulWidget {
  const AwardsScreen({super.key});

  @override
  ConsumerState<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends ConsumerState<AwardsScreen> {
  String? _gameUuid;

  @override
  void initState() {
    super.initState();
    _gameUuid = ref.read(currentGameUuidProvider);
  }

  @override
  Widget build(BuildContext context) {
    final gameUuid = _gameUuid ?? ref.watch(currentGameUuidProvider);
    final playersAsync = ref.watch(playersFutureProvider);
    final gameAsync = gameUuid != null
        ? ref.watch(gameByUuidProvider(gameUuid))
        : const AsyncValue.data(null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: gameUuid == null
          ? SafeArea(
              child: Center(
                child: Text(
                  'No game selected. Start a game from Team.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : playersAsync.when(
              data: (allPlayers) {
                return gameAsync.when(
                  data: (game) {
                    if (game == null) {
                      return const Center(child: Text('Game not found'));
                    }
                    final awards = game.awards;
                    final totalGiven = awards.values
                        .fold<int>(0, (sum, list) => sum + list.length);
                    final presentUuids = game.presentPlayerIds.toSet();
                    final presentPlayers = allPlayers
                        .where((p) => presentUuids.contains(p.uuid))
                        .toList();

                    return SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: AppColors.saveAwardsGold, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Awards',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalGiven/${AppConstants.awardsPerCategory * AwardType.values.length} awards given',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                ...AwardType.values.map((category) {
                                  final list = awards[category] ?? [];
                                  final count = list.length;
                                  return _AwardCategoryCard(
                                    category: category,
                                    count: count,
                                    maxCount: AppConstants.awardsPerCategory,
                                    winnerUuids: list,
                                    presentPlayers: presentPlayers,
                                    allPlayers: allPlayers,
                                    onTap: () => _openCategoryPicker(
                                      context,
                                      gameUuid,
                                      category,
                                      game.awards,
                                      presentPlayers,
                                      allPlayers,
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),
                                _PlayersNotYetSelected(
                                  presentPlayers: presentPlayers,
                                  awards: awards,
                                ),
                                const SizedBox(height: 24),
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'Per-player summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _PlayerAwardsSummary(
                                  presentPlayers: presentPlayers,
                                  awards: awards,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: () {
                                  ref
                                      .read(currentGameUuidProvider.notifier)
                                      .state = null;
                                  context.go(AppRoute.teams.path);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.saveAwardsGold,
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Done'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/awards'),
    );
  }

  Future<void> _openCategoryPicker(
    BuildContext context,
    String gameUuid,
    AwardType category,
    Map<AwardType, List<String>> awards,
    List<Player> presentPlayers,
    List<Player> allPlayers,
  ) async {
    final selected = List<String>.from(awards[category] ?? []);
    final inThisCategory = (awards[category] ?? []).toSet();
    final inOtherCategories = <String>{};
    for (final entry in awards.entries) {
      if (entry.key != category) {
        inOtherCategories.addAll(entry.value);
      }
    }
    final playersToShow = presentPlayers
        .where((p) => inThisCategory.contains(p.uuid) || !inOtherCategories.contains(p.uuid))
        .toList();
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CategoryPickerSheet(
        category: category,
        selectedUuids: selected,
        presentPlayers: playersToShow,
        allPlayers: allPlayers,
        maxCount: AppConstants.awardsPerCategory,
      ),
    );
    if (result == null || !context.mounted) return;
    final isar = await ref.read(isarProvider.future);
    final gameRepo = GameRepository(isar);
    final g = await gameRepo.getByUuid(gameUuid);
    if (g == null) return;
    final updated = Map<AwardType, List<String>>.from(g.awards);
    updated[category] = result;
    await gameRepo.saveAwards(gameUuid, updated);
  }
}

class _AwardCategoryCard extends StatelessWidget {
  const _AwardCategoryCard({
    required this.category,
    required this.count,
    required this.maxCount,
    required this.winnerUuids,
    required this.presentPlayers,
    required this.allPlayers,
    required this.onTap,
  });

  final AwardType category;
  final int count;
  final int maxCount;
  final List<String> winnerUuids;
  final List<Player> presentPlayers;
  final List<Player> allPlayers;
  final VoidCallback onTap;

  IconData get _icon => Icons.star;

  Color get _color {
    switch (category) {
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

  String get _label {
    switch (category) {
      case AwardType.christlikeness:
        return 'Christlikeness';
      case AwardType.defense:
        return 'Defense';
      case AwardType.effort:
        return 'Effort';
      case AwardType.offense:
        return 'Offense';
      case AwardType.sportsmanship:
        return 'Sportsmanship';
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = winnerUuids
        .map((uuid) =>
            allPlayers.where((x) => x.uuid == uuid).firstOrNull?.name ?? '?')
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.chipInactive),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, color: _color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      if (names.isNotEmpty)
                        Text(
                          names.join(', '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '$count/$maxCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.category,
    required this.selectedUuids,
    required this.presentPlayers,
    required this.allPlayers,
    required this.maxCount,
  });

  final AwardType category;
  final List<String> selectedUuids;
  final List<Player> presentPlayers;
  final List<Player> allPlayers;
  final int maxCount;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedUuids);
  }

  String _label(AwardType c) {
    switch (c) {
      case AwardType.christlikeness:
        return 'Christlikeness';
      case AwardType.defense:
        return 'Defense';
      case AwardType.effort:
        return 'Effort';
      case AwardType.offense:
        return 'Offense';
      case AwardType.sportsmanship:
        return 'Sportsmanship';
    }
  }

  void _toggle(String uuid) {
    setState(() {
      if (_selected.contains(uuid)) {
        _selected.remove(uuid);
      } else if (_selected.length < widget.maxCount) {
        _selected.add(uuid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      _label(widget.category),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selected.length}/${widget.maxCount}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: widget.presentPlayers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'All other players have already been selected for an award. '
                          'Remove someone from another category to select them here.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: widget.presentPlayers.map((p) {
                          final isSelected = _selected.contains(p.uuid);
                          return ListTile(
                            title: Text(p.name),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.saveAwardsGold, size: 22)
                                : null,
                            onTap: () => _toggle(p.uuid),
                          );
                        }).toList(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saveAwardsGold,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayersNotYetSelected extends StatelessWidget {
  const _PlayersNotYetSelected({
    required this.presentPlayers,
    required this.awards,
  });

  final List<Player> presentPlayers;
  final Map<AwardType, List<String>> awards;

  @override
  Widget build(BuildContext context) {
    final awardedUuids = <String>{};
    for (final list in awards.values) {
      awardedUuids.addAll(list);
    }
    final notYetSelected =
        presentPlayers.where((p) => !awardedUuids.contains(p.uuid)).toList();
    if (notYetSelected.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          'All players have been selected for an award.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Players not yet selected for an award',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notYetSelected.map((p) => p.name).join(', '),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerAwardsSummary extends StatelessWidget {
  const _PlayerAwardsSummary({
    required this.presentPlayers,
    required this.awards,
  });

  final List<Player> presentPlayers;
  final Map<AwardType, List<String>> awards;

  String _categoryLabel(AwardType t) {
    switch (t) {
      case AwardType.christlikeness:
        return 'Christlikeness';
      case AwardType.defense:
        return 'Defense';
      case AwardType.effort:
        return 'Effort';
      case AwardType.offense:
        return 'Offense';
      case AwardType.sportsmanship:
        return 'Sportsmanship';
    }
  }

  Color _colorForAward(AwardType t) {
    switch (t) {
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
    final playerAwards = <String, List<AwardType>>{};
    for (final p in presentPlayers) {
      playerAwards[p.uuid] = [];
    }
    for (final entry in awards.entries) {
      for (final uuid in entry.value) {
        playerAwards[uuid] ??= [];
        playerAwards[uuid]!.add(entry.key);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: presentPlayers.map((p) {
        final list = playerAwards[p.uuid] ?? [];
        final text = list.isEmpty
            ? '—'
            : list.map(_categoryLabel).join(', ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (list.isNotEmpty) ...[
                ...list.map((awardType) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star,
                        size: 18,
                        color: _colorForAward(awardType),
                      ),
                    )),
                const SizedBox(width: 6),
              ],
              SizedBox(
                width: list.isEmpty ? 100 : null,
                child: Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
