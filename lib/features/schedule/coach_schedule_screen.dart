import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../data/isar/models/schedule_event.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../providers/current_user_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/team_logo_avatar.dart';

class CoachScheduleScreen extends ConsumerStatefulWidget {
  const CoachScheduleScreen({super.key});

  @override
  ConsumerState<CoachScheduleScreen> createState() => _CoachScheduleScreenState();
}

class _CoachScheduleScreenState extends ConsumerState<CoachScheduleScreen> {
  String? _selectedTeamUuid;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final teamUuid = _selectedTeamUuid;

    if (teamUuid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Schedule'),
          centerTitle: true,
        ),
        body: SafeArea(
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
                padding: const EdgeInsets.all(16),
                itemCount: teams.length,
                itemBuilder: (context, i) {
                  final team = teams[i];
                  return _TeamCard(
                    team: team,
                    onTap: () => setState(() => _selectedTeamUuid = team.uuid),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentPath: '/schedule'),
      );
    }

    return _EventListForTeam(
      teamUuid: teamUuid,
      onBack: () => setState(() => _selectedTeamUuid = null),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onTap});

  final Team team;
  final VoidCallback onTap;

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
        subtitle: const Text(
          'Manage schedule',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

enum _ScheduleFilter { all, practice, game }

class _EventListForTeam extends ConsumerStatefulWidget {
  const _EventListForTeam({
    required this.teamUuid,
    required this.onBack,
  });

  final String teamUuid;
  final VoidCallback onBack;

  @override
  ConsumerState<_EventListForTeam> createState() => _EventListForTeamState();
}

class _EventListForTeamState extends ConsumerState<_EventListForTeam> {
  _ScheduleFilter _filter = _ScheduleFilter.all;
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  List<ScheduleEvent> _filterEvents(List<ScheduleEvent> events) {
    switch (_filter) {
      case _ScheduleFilter.practice:
        return events.where((e) => e.type == ScheduleEventType.practice).toList();
      case _ScheduleFilter.game:
        return events.where((e) => e.type == ScheduleEventType.game).toList();
      case _ScheduleFilter.all:
        return events;
    }
  }

  Future<void> _bulkDelete(BuildContext context, WidgetRef ref, List<ScheduleEvent> eventsToDelete) async {
    final n = eventsToDelete.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete events?'),
        content: Text('$n event${n == 1 ? '' : 's'} will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final isar = await ref.read(isarProvider.future);
    final repo = ScheduleRepository(isar);
    final userId = ref.read(currentUserIdProvider);
    for (final e in eventsToDelete) {
      await repo.softDelete(e, deletedByUserId: userId);
    }
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$n event${n == 1 ? '' : 's'} deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final teams = teamsAsync.valueOrNull ?? [];
    final team = teams.where((t) => t.uuid == widget.teamUuid).firstOrNull;
    final teamName = team?.name ?? 'Team';
    final eventsAsync = ref.watch(scheduleEventsForTeamProvider(widget.teamUuid));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _selecting
              ? () => setState(() {
                    _selecting = false;
                    _selectedIds.clear();
                  })
              : widget.onBack,
          color: AppColors.textPrimary,
        ),
        title: _selecting
            ? Text(
                _selectedIds.isEmpty ? 'Select events' : '${_selectedIds.length} selected',
              )
            : (team != null
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
                : Text('$teamName — Schedule')),
        centerTitle: true,
        actions: [
          if (!_selecting)
            eventsAsync.valueOrNull != null && eventsAsync.valueOrNull!.isNotEmpty
                ? TextButton(
                    onPressed: () => setState(() => _selecting = true),
                    child: const Text('Select'),
                  )
                : const SizedBox.shrink(),
          if (_selecting) ...[
            if (_selectedIds.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  final all = eventsAsync.valueOrNull ?? [];
                  final toDelete = all.where((e) => _selectedIds.contains(e.uuid)).toList();
                  await _bulkDelete(context, ref, toDelete);
                },
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ],
      ),
      body: SafeArea(
        child: eventsAsync.when(
          data: (events) {
            events = events.toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            final filtered = _filterEvents(events);
            final material = MaterialLocalizations.of(context);
            final byDate = _groupByDate(filtered);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (events.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _filter == _ScheduleFilter.all,
                          onSelected: (_) => setState(() => _filter = _ScheduleFilter.all),
                          selectedColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Practice'),
                          selected: _filter == _ScheduleFilter.practice,
                          onSelected: (_) => setState(() => _filter = _ScheduleFilter.practice),
                          selectedColor: AppColors.onCourtGreen.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Games'),
                          selected: _filter == _ScheduleFilter.game,
                          onSelected: (_) => setState(() => _filter = _ScheduleFilter.game),
                          selectedColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: filtered.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                _filter == _ScheduleFilter.all
                                    ? 'No events yet. Tap + to add one.'
                                    : 'No ${_filter == _ScheduleFilter.practice ? 'practices' : 'games'} in this filter.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ]
                        : byDate.entries.expand((e) {
                            final date = e.key;
                            final dayEvents = e.value;
                            return [
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 6),
                                child: Text(
                                  material.formatFullDate(date),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ),
                              ...dayEvents.map((event) {
                                final selected = _selectedIds.contains(event.uuid);
                                return _CoachEventTile(
                                  event: event,
                                  dateLabel: material.formatFullDate(DateTime(event.startsAt.year, event.startsAt.month, event.startsAt.day)),
                                  selecting: _selecting,
                                  selected: selected,
                                  onTap: _selecting
                                      ? () => setState(() {
                                            if (selected) {
                                              _selectedIds.remove(event.uuid);
                                            } else {
                                              _selectedIds.add(event.uuid);
                                            }
                                          })
                                      : null,
                                  onEdit: () => _showEventForm(context, ref, widget.teamUuid, event: event),
                                  onDelete: () => _confirmDelete(context, ref, event),
                                );
                              }),
                            ];
                          }).toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: () => _showEventForm(context, ref, widget.teamUuid),
              backgroundColor: AppColors.primaryOrange,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/schedule'),
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

class _CoachEventTile extends StatelessWidget {
  const _CoachEventTile({
    required this.event,
    required this.dateLabel,
    this.selecting = false,
    this.selected = false,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleEvent event;
  final String dateLabel;
  final bool selecting;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final isGame = event.type == ScheduleEventType.game;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryOrange.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primaryOrange : AppColors.chipInactive,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selecting) ...[
                Checkbox(
                  value: selected,
                  onChanged: onTap != null ? (_) => onTap!() : null,
                  activeColor: AppColors.primaryOrange,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
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
                  children: [
                    Text(
                      material.formatTimeOfDay(TimeOfDay.fromDateTime(event.startsAt)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGame
                            ? AppColors.primaryOrange.withValues(alpha: 0.15)
                            : AppColors.onCourtGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGame ? 'Game' : 'Practice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isGame ? AppColors.primaryOrange : AppColors.onCourtGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.location!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isGame && event.opponent != null && event.opponent!.isNotEmpty)
                  Text(
                    'vs ${event.opponent}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!selecting) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22),
                color: AppColors.textSecondary,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppColors.textSecondary,
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    ));
  }
}

Future<void> _showEventForm(
  BuildContext context,
  WidgetRef ref,
  String teamUuid, {
  ScheduleEvent? event,
}) async {
  final result = await showDialog<List<ScheduleEvent>>(
    context: context,
    builder: (ctx) => _ScheduleEventFormDialog(teamUuid: teamUuid, event: event),
  );
  if (result == null || result.isEmpty || !context.mounted) return;
  final isar = await ref.read(isarProvider.future);
  final repo = ScheduleRepository(isar);
  final userId = ref.read(currentUserIdProvider);
  if (event == null) {
    for (final e in result) {
      await repo.add(e);
    }
  } else {
    final single = result.single;
    single.id = event.id;
    single.uuid = event.uuid;
    single.createdAt = event.createdAt;
    await repo.update(single, updatedByUserId: userId);
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          event == null
              ? (result.length == 1 ? 'Event added' : '${result.length} practices added')
              : 'Event updated',
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ScheduleEvent event) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete event?'),
      content: const Text('This event will be removed from the schedule.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  final isar = await ref.read(isarProvider.future);
  await ScheduleRepository(isar).softDelete(event, deletedByUserId: ref.read(currentUserIdProvider));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
  }
}

class _ScheduleEventFormDialog extends StatefulWidget {
  const _ScheduleEventFormDialog({required this.teamUuid, this.event});

  final String teamUuid;
  final ScheduleEvent? event;

  @override
  State<_ScheduleEventFormDialog> createState() => _ScheduleEventFormDialogState();
}

/// Weekday 1 = Monday, 7 = Sunday (DateTime.weekday).
const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _ScheduleEventFormDialogState extends State<_ScheduleEventFormDialog> {
  late ScheduleEventType _type;
  late DateTime _startsAt;
  DateTime? _endsAt;
  final _locationController = TextEditingController();
  final _opponentController = TextEditingController();
  final _notesController = TextEditingController();
  String? _startsAtError;
  String? _endsAtError;

  bool _isRepeating = false;
  final Set<int> _repeatOnDays = {};
  DateTime? _repeatUntil;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _type = e?.type ?? ScheduleEventType.practice;
    _startsAt = e?.startsAt ?? DateTime.now();
    _endsAt = e?.endsAt;
    _locationController.text = e?.location ?? '';
    _opponentController.text = e?.opponent ?? '';
    _notesController.text = e?.notes ?? '';
    _repeatUntil = _startsAt.add(const Duration(days: 60));
  }

  @override
  void dispose() {
    _locationController.dispose();
    _opponentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartsAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _startsAtError = null;
      if (_endsAt != null && !_endsAt!.isAfter(_startsAt)) _endsAt = null;
    });
  }

  Future<void> _pickEndsAt() async {
    final defaultEnd = _startsAt.add(const Duration(minutes: 60));
    final time = await showTimePicker(
      context: context,
      initialTime: _endsAt != null
          ? TimeOfDay.fromDateTime(_endsAt!)
          : TimeOfDay(hour: defaultEnd.hour, minute: defaultEnd.minute),
    );
    if (time == null || !mounted) return;
    final ends = DateTime(
      _startsAt.year,
      _startsAt.month,
      _startsAt.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _endsAt = ends;
      _endsAtError = ends.isAfter(_startsAt) ? null : 'End must be after start';
    });
  }

  bool _validate() {
    _startsAtError = null;
    _endsAtError = null;
    if (_endsAt != null && !_endsAt!.isAfter(_startsAt)) {
      _endsAtError = 'End must be after start';
      return false;
    }
    if (_isRepeating && _repeatOnDays.isEmpty) return false;
    if (_isRepeating && (_repeatUntil == null || _repeatUntil!.isBefore(_startsAt))) return false;
    return true;
  }

  void _submit() {
    if (!_validate()) {
      setState(() {});
      return;
    }
    final location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
    final opponent = _opponentController.text.trim().isEmpty ? null : _opponentController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final duration = _endsAt != null ? _endsAt!.difference(_startsAt) : const Duration(minutes: 0);

    if (widget.event != null) {
      final event = ScheduleEvent.create(
        uuid: widget.event!.uuid,
        teamId: widget.teamUuid,
        type: _type,
        startsAt: _startsAt,
        endsAt: _endsAt,
        location: location,
        opponent: opponent,
        notes: notes,
      );
      Navigator.of(context).pop(<ScheduleEvent>[event]);
      return;
    }

    if (_isRepeating && _type == ScheduleEventType.practice && _repeatOnDays.isNotEmpty && _repeatUntil != null) {
      final events = <ScheduleEvent>[];
      var date = DateTime(_startsAt.year, _startsAt.month, _startsAt.day);
      final endDate = DateTime(_repeatUntil!.year, _repeatUntil!.month, _repeatUntil!.day);
      final startTime = TimeOfDay(hour: _startsAt.hour, minute: _startsAt.minute);
      while (!date.isAfter(endDate)) {
        if (_repeatOnDays.contains(date.weekday)) {
          final startsAt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
          final endsAt = duration.inMinutes > 0 ? startsAt.add(duration) : null;
          events.add(ScheduleEvent.create(
            uuid: const Uuid().v4(),
            teamId: widget.teamUuid,
            type: ScheduleEventType.practice,
            startsAt: startsAt,
            endsAt: endsAt,
            location: location,
            opponent: null,
            notes: notes,
          ));
        }
        date = date.add(const Duration(days: 1));
      }
      if (events.isNotEmpty) {
        Navigator.of(context).pop(events);
        return;
      }
    }

    final event = ScheduleEvent.create(
      uuid: const Uuid().v4(),
      teamId: widget.teamUuid,
      type: _type,
      startsAt: _startsAt,
      endsAt: _endsAt,
      location: location,
      opponent: opponent,
      notes: notes,
    );
    Navigator.of(context).pop(<ScheduleEvent>[event]);
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.event == null ? 'Add event' : 'Edit event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Practice'),
                  selected: _type == ScheduleEventType.practice,
                  onSelected: (_) => setState(() => _type = ScheduleEventType.practice),
                  selectedColor: AppColors.onCourtGreen.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Game'),
                  selected: _type == ScheduleEventType.game,
                  onSelected: (_) => setState(() => _type = ScheduleEventType.game),
                  selectedColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Start', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: _pickStartsAt,
              child: Text(material.formatMediumDate(_startsAt) + ' ' + material.formatTimeOfDay(TimeOfDay.fromDateTime(_startsAt))),
            ),
            if (_startsAtError != null) ...[
              const SizedBox(height: 4),
              Text(_startsAtError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            const Text('End time (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: _pickEndsAt,
              child: Text(_endsAt == null
                  ? 'Set end time'
                  : material.formatTimeOfDay(TimeOfDay.fromDateTime(_endsAt!))),
            ),
            if (_endsAtError != null) ...[
              const SizedBox(height: 4),
              Text(_endsAtError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            if (widget.event == null && _type == ScheduleEventType.practice) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isRepeating,
                    onChanged: (v) => setState(() => _isRepeating = v ?? false),
                    activeColor: AppColors.primaryOrange,
                  ),
                  const Expanded(
                    child: Text(
                      'Repeating practice',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (_isRepeating) ...[
                const SizedBox(height: 8),
                const Text('Repeat on', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (i) {
                    final weekday = i + 1;
                    final selected = _repeatOnDays.contains(weekday);
                    return FilterChip(
                      label: Text(_weekdayLabels[i]),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) _repeatOnDays.add(weekday);
                        else _repeatOnDays.remove(weekday);
                      }),
                      selectedColor: AppColors.onCourtGreen.withValues(alpha: 0.3),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                const Text('End date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _repeatUntil ?? _startsAt.add(const Duration(days: 60)),
                      firstDate: _startsAt,
                      lastDate: DateTime(2030),
                    );
                    if (d != null && mounted) setState(() => _repeatUntil = d);
                  },
                  child: Text(
                    _repeatUntil == null
                        ? 'Pick end date'
                        : MaterialLocalizations.of(context).formatMediumDate(_repeatUntil!),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _opponentController,
              decoration: const InputDecoration(
                labelText: 'Opponent (for games)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryOrange),
          child: Text(widget.event == null ? 'Add' : 'Save'),
        ),
      ],
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
