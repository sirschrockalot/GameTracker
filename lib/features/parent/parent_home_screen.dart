import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/isar/models/schedule_event.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/team_logo_avatar.dart';

/// Schedule-only home for active parents. Coach tools and nav are not available.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key, required this.teamUuid});

  final String teamUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final teams = teamsAsync.valueOrNull ?? [];
    final team = teams.where((t) => t.uuid == teamUuid).firstOrNull;
    final teamName = team?.name ?? 'Team';
    final scheduleAsync = ref.watch(scheduleEventsForTeamProvider(teamUuid));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teams'),
          color: AppColors.textPrimary,
        ),
        title: team != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeamLogoAvatar(team: team!, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('$teamName — Schedule', overflow: TextOverflow.ellipsis),
                  ),
                ],
              )
            : Text('$teamName — Schedule'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: scheduleAsync.when(
          data: (allEvents) {
            final now = DateTime.now();
            final upcoming = allEvents
                .where((e) => !e.startsAt.isBefore(now))
                .toList()
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            final byDate = _groupByDate(upcoming);
            if (byDate.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Upcoming',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No upcoming events.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            final material = MaterialLocalizations.of(context);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Upcoming',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                ...byDate.entries.expand((e) {
                  final date = e.key;
                  final events = e.value;
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Text(
                        material.formatFullDate(date),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    ...events.map((event) => _ScheduleEventTile(
                          event: event,
                          dateLabel: material.formatFullDate(DateTime(event.startsAt.year, event.startsAt.month, event.startsAt.day)),
                          timeFormat: material.formatTimeOfDay(
                            TimeOfDay.fromDateTime(event.startsAt),
                          ),
                        )),
                  ];
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/teams'),
    );
  }

  static Map<DateTime, List<ScheduleEvent>> _groupByDate(List<ScheduleEvent> events) {
    final map = <DateTime, List<ScheduleEvent>>{};
    for (final e in events) {
      final key = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    final keys = map.keys.toList()..sort();
    return Map.fromEntries(keys.map((k) => MapEntry(k, map[k]!)));
  }
}

class _ScheduleEventTile extends StatelessWidget {
  const _ScheduleEventTile({
    required this.event,
    required this.dateLabel,
    required this.timeFormat,
  });

  final ScheduleEvent event;
  final String dateLabel;
  final String timeFormat;

  @override
  Widget build(BuildContext context) {
    final isGame = event.type == ScheduleEventType.game;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chipInactive),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeFormat,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isGame
                      ? AppColors.primaryOrange.withValues(alpha: 0.15)
                      : AppColors.onCourtGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isGame ? 'Game' : 'Practice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isGame
                        ? AppColors.primaryOrange
                        : AppColors.onCourtGreen,
                  ),
                ),
              ),
            ],
          ),
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isGame && event.opponent != null && event.opponent!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'vs ${event.opponent}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.notes!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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
