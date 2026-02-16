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
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_today, color: AppColors.primaryOrange, size: 22),
        ),
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

class _EventListForTeam extends ConsumerWidget {
  const _EventListForTeam({
    required this.teamUuid,
    required this.onBack,
  });

  final String teamUuid;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final teams = teamsAsync.valueOrNull ?? [];
    final team = teams.where((t) => t.uuid == teamUuid).firstOrNull;
    final teamName = team?.name ?? 'Team';
    final eventsAsync = ref.watch(scheduleEventsForTeamProvider(teamUuid));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 22),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
        title: Text('$teamName — Schedule'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: eventsAsync.when(
          data: (events) {
            events = events.toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.isEmpty ? 1 : events.length,
              itemBuilder: (context, i) {
                if (events.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No events yet. Tap + to add one.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final event = events[i];
                return _CoachEventTile(
                  event: event,
                  onEdit: () => _showEventForm(context, ref, teamUuid, event: event),
                  onDelete: () => _confirmDelete(context, ref, event),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventForm(context, ref, teamUuid),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/schedule'),
    );
  }
}

class _CoachEventTile extends StatelessWidget {
  const _CoachEventTile({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final isGame = event.type == ScheduleEventType.game;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chipInactive),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
      ),
    );
  }
}

Future<void> _showEventForm(
  BuildContext context,
  WidgetRef ref,
  String teamUuid, {
  ScheduleEvent? event,
}) async {
  final result = await showDialog<ScheduleEvent?>(
    context: context,
    builder: (ctx) => _ScheduleEventFormDialog(teamUuid: teamUuid, event: event),
  );
  if (result == null || !context.mounted) return;
  final isar = await ref.read(isarProvider.future);
  final repo = ScheduleRepository(isar);
  final userId = ref.read(currentUserIdProvider);
  if (event == null) {
    await repo.add(result);
  } else {
    result.id = event.id;
    result.uuid = event.uuid;
    result.createdAt = event.createdAt;
    await repo.update(result, updatedByUserId: userId);
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(event == null ? 'Event added' : 'Event updated')),
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

class _ScheduleEventFormDialogState extends State<_ScheduleEventFormDialog> {
  late ScheduleEventType _type;
  late DateTime _startsAt;
  DateTime? _endsAt;
  final _locationController = TextEditingController();
  final _opponentController = TextEditingController();
  final _notesController = TextEditingController();
  String? _startsAtError;
  String? _endsAtError;

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
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? _startsAt,
      firstDate: _startsAt,
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final defaultEnd = _startsAt.add(const Duration(minutes: 30));
    final time = await showTimePicker(
      context: context,
      initialTime: _endsAt != null
          ? TimeOfDay.fromDateTime(_endsAt!)
          : TimeOfDay(hour: defaultEnd.hour, minute: defaultEnd.minute),
    );
    if (time == null || !mounted) return;
    final ends = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
    return true;
  }

  void _submit() {
    if (!_validate()) {
      setState(() {});
      return;
    }
    final event = ScheduleEvent.create(
      uuid: widget.event?.uuid ?? const Uuid().v4(),
      teamId: widget.teamUuid,
      type: _type,
      startsAt: _startsAt,
      endsAt: _endsAt,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      opponent: _opponentController.text.trim().isEmpty ? null : _opponentController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    Navigator.of(context).pop(event);
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
            const Text('End (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: _pickEndsAt,
              child: Text(_endsAt == null
                  ? 'Set end time'
                  : material.formatMediumDate(_endsAt!) + ' ' + material.formatTimeOfDay(TimeOfDay.fromDateTime(_endsAt!))),
            ),
            if (_endsAtError != null) ...[
              const SizedBox(height: 4),
              Text(_endsAtError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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
