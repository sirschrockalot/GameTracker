import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/isar/models/game.dart';
import '../../domain/services/season_totals.dart';
import '../../providers/game_provider.dart';
import '../../widgets/app_bottom_nav.dart';

enum _SortBy { quarters, totalAwards, awardType }

class SeasonTotalsScreen extends ConsumerStatefulWidget {
  const SeasonTotalsScreen({super.key});

  @override
  ConsumerState<SeasonTotalsScreen> createState() => _SeasonTotalsScreenState();
}

class _SeasonTotalsScreenState extends ConsumerState<SeasonTotalsScreen> {
  AwardType? _filterAwardType;
  _SortBy _sortBy = _SortBy.quarters;
  AwardType? _sortAwardType;

  @override
  Widget build(BuildContext context) {
    final totalsAsync = ref.watch(seasonTotalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Season Totals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
      ),
      body: totalsAsync.when(
        data: (list) {
          var filtered = list;
          if (_filterAwardType != null) {
            filtered = list
                .where((t) =>
                    (t.totalAwardsByType[_filterAwardType!] ?? 0) > 0)
                .toList();
          }
          filtered = List.from(filtered)
            ..sort((a, b) {
              switch (_sortBy) {
                case _SortBy.quarters:
                  return b.totalQuartersPlayed.compareTo(a.totalQuartersPlayed);
                case _SortBy.totalAwards:
                  return b.totalAwards.compareTo(a.totalAwards);
                case _SortBy.awardType:
                  final type = _sortAwardType ?? AwardType.christlikeness;
                  final va = a.totalAwardsByType[type] ?? 0;
                  final vb = b.totalAwardsByType[type] ?? 0;
                  return vb.compareTo(va);
              }
            });

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by award',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filterAwardType == null,
                              onTap: () =>
                                  setState(() => _filterAwardType = null),
                            ),
                            ...AwardType.values.map((t) => _FilterChip(
                                  label: _awardLabel(t),
                                  selected: _filterAwardType == t,
                                  onTap: () =>
                                      setState(() => _filterAwardType = t),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sort by',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Quarters'),
                            selected: _sortBy == _SortBy.quarters,
                            onSelected: (_) => setState(() {
                              _sortBy = _SortBy.quarters;
                              _sortAwardType = null;
                            }),
                            selectedColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                          ),
                          ChoiceChip(
                            label: const Text('Total awards'),
                            selected: _sortBy == _SortBy.totalAwards,
                            onSelected: (_) => setState(() {
                              _sortBy = _SortBy.totalAwards;
                              _sortAwardType = null;
                            }),
                            selectedColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                          ),
                          ...AwardType.values.map((t) => ChoiceChip(
                                label: Text(_awardLabel(t)),
                                selected: _sortBy == _SortBy.awardType &&
                                    _sortAwardType == t,
                                onSelected: (_) => setState(() {
                                  _sortBy = _SortBy.awardType;
                                  _sortAwardType = t;
                                }),
                                selectedColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No players match the filter.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final t = filtered[i];
                        return _SeasonTotalsCard(totals: t);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/history'),
    );
  }

  static String _awardLabel(AwardType t) {
    return switch (t) {
      AwardType.christlikeness => 'Christlikeness',
      AwardType.defense => 'Defense',
      AwardType.effort => 'Effort',
      AwardType.offense => 'Offense',
      AwardType.sportsmanship => 'Sportsmanship',
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryOrange.withValues(alpha: 0.3),
      ),
    );
  }
}

class _SeasonTotalsCard extends StatelessWidget {
  const _SeasonTotalsCard({required this.totals});

  final PlayerSeasonTotals totals;

  @override
  Widget build(BuildContext context) {
    final awardsList = totals.totalAwardsByType.entries
        .where((e) => e.value > 0)
        .map((e) => '${_label(e.key)}: ${e.value}')
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.chipInactive),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    totals.playerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${totals.gamesPlayedCount} games',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                  icon: Icons.sports_basketball,
                  value: '${totals.totalQuartersPlayed} qtrs',
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.emoji_events,
                  value: '${totals.totalAwards} awards',
                ),
              ],
            ),
            if (awardsList.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: awardsList
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.saveAwardsGold.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _label(AwardType t) {
    return switch (t) {
      AwardType.christlikeness => 'Christlikeness',
      AwardType.defense => 'Defense',
      AwardType.effort => 'Effort',
      AwardType.offense => 'Offense',
      AwardType.sportsmanship => 'Sportsmanship',
    };
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
