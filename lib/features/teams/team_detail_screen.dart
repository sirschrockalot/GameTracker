import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../data/isar/models/player.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../providers/isar_provider.dart';
import '../../providers/teams_provider.dart';
import '../../providers/players_provider.dart';

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class TeamDetailScreen extends ConsumerStatefulWidget {
  const TeamDetailScreen({super.key, required this.teamUuid});

  final String teamUuid;

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  late TextEditingController _nameController;
  bool _initialNameSet = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final playersAsync = ref.watch(playersFutureProvider);

    Team? team;
    try {
      team = teamsAsync.valueOrNull?.firstWhere(
        (t) => t.uuid == widget.teamUuid,
      );
    } catch (_) {}

    if (team != null && !_initialNameSet) {
      _initialNameSet = true;
      final name = team.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _nameController.text.isEmpty) {
          _nameController.text = name;
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, size: 22),
            label: const Text('Back to Teams'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
        title: team != null ? Text('${team!.name} Players') : null,
        centerTitle: true,
      ),
      body: team == null
          ? const Center(child: Text('Team not found'))
          : playersAsync.when(
              data: (allPlayers) => _TeamDetailBody(
                team: team!,
                allPlayers: allPlayers,
                nameController: _nameController,
                onSaveName: () => _saveName(ref, team!),
                onRemovePlayer: (uuid) => _removePlayer(ref, team!, uuid),
                onEditPlayer: (p) => _showEditPlayer(context, ref, p),
                onAddPlayer: () => _showAddPlayerChoice(context, ref, team!, allPlayers),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
    );
  }

  Future<void> _saveName(WidgetRef ref, Team team) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    team.name = name;
    final isar = await ref.read(isarProvider.future);
    await TeamRepository(isar).update(team);
  }

  Future<void> _removePlayer(WidgetRef ref, Team team, String playerUuid) async {
    team.playerIds = team.playerIds.where((id) => id != playerUuid).toList();
    final isar = await ref.read(isarProvider.future);
    await TeamRepository(isar).update(team);
  }

  Future<void> _showAddFromRoster(
    BuildContext context,
    WidgetRef ref,
    Team team,
    List<Player> allPlayers,
  ) async {
    final assigned = team.playerIds.toSet();
    final available = allPlayers.where((p) => !assigned.contains(p.uuid)).toList();
    if (available.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All players are already on this team. Add a new player below.'),
          ),
        );
      }
      return;
    }
    final chosen = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddPlayersSheet(available: available),
    );
    if (chosen == null || chosen.isEmpty || !context.mounted) return;
    team.playerIds = List<String>.from(team.playerIds)..addAll(chosen);
    final isar = await ref.read(isarProvider.future);
    await TeamRepository(isar).update(team);
  }

  Future<void> _showAddNewPlayer(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    final result = await showDialog<({String name, Skill skill})>(
      context: context,
      builder: (ctx) => _NewPlayerDialog(initialSkill: Skill.developing),
    );
    if (result == null || result.name.isEmpty || !context.mounted) return;
    final isar = await ref.read(isarProvider.future);
    final player = Player.create(uuid: const Uuid().v4(), name: result.name, skill: result.skill);
    await PlayerRepository(isar).add(player);
    team.playerIds = List<String>.from(team.playerIds)..add(player.uuid);
    await TeamRepository(isar).update(team);
    ref.invalidate(playersFutureProvider);
  }

  Future<void> _showEditPlayer(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    final result = await showDialog<({String name, Skill skill})>(
      context: context,
      builder: (ctx) => _NewPlayerDialog(
        initialName: player.name,
        initialSkill: player.skill,
        isEdit: true,
      ),
    );
    if (result == null || result.name.isEmpty || !context.mounted) return;
    player.name = result.name;
    player.skill = result.skill;
    final isar = await ref.read(isarProvider.future);
    await PlayerRepository(isar).update(player);
    ref.invalidate(playersFutureProvider);
  }

  void _showAddPlayerChoice(BuildContext context, WidgetRef ref, Team team, List<Player> allPlayers) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Player',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showAddFromRoster(context, ref, team, allPlayers);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add from roster'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showAddNewPlayer(context, ref, team);
                },
                icon: const Icon(Icons.add),
                label: const Text('New player'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPlayersSheet extends StatefulWidget {
  const _AddPlayersSheet({required this.available});

  final List<Player> available;

  @override
  State<_AddPlayersSheet> createState() => _AddPlayersSheetState();
}

class _AddPlayersSheetState extends State<_AddPlayersSheet> {
  /// Track selection by list index so each row is independent (avoids duplicate-uuid issues).
  final Set<int> _selectedIndices = {};

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
                      'Add players',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    if (_selectedIndices.isNotEmpty)
                      Text(
                        '${_selectedIndices.length} selected',
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
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.available.length,
                  itemBuilder: (context, index) {
                    final p = widget.available[index];
                    final isSelected = _selectedIndices.contains(index);
                    return Material(
                      color: isSelected
                          ? AppColors.primaryOrange.withValues(alpha: 0.12)
                          : Colors.transparent,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIndices.add(index);
                            } else {
                              _selectedIndices.remove(index);
                            }
                          });
                        },
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        activeColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _selectedIndices.isEmpty
                          ? null
                          : () {
                              final uuids = _selectedIndices
                                  .map((i) => widget.available[i].uuid)
                                  .toSet()
                                  .toList();
                              Navigator.of(context).pop(uuids);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedIndices.isEmpty
                            ? 'Add players'
                            : _selectedIndices.length == 1
                                ? 'Add 1 player'
                                : 'Add ${_selectedIndices.length} players',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamDetailBody extends StatelessWidget {
  const _TeamDetailBody({
    required this.team,
    required this.allPlayers,
    required this.nameController,
    required this.onSaveName,
    required this.onRemovePlayer,
    required this.onEditPlayer,
    required this.onAddPlayer,
  });

  final Team team;
  final List<Player> allPlayers;
  final TextEditingController nameController;
  final VoidCallback onSaveName;
  final void Function(String uuid) onRemovePlayer;
  final void Function(Player p) onEditPlayer;
  final VoidCallback onAddPlayer;

  @override
  Widget build(BuildContext context) {
    final assignedPlayers = team.playerIds
        .map((uuid) => allPlayers.where((p) => p.uuid == uuid).firstOrNull)
        .whereType<Player>()
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Team name',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Team name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: onSaveName,
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => onSaveName(),
        ),
        const SizedBox(height: 20),
        Text(
          '${assignedPlayers.length} players',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        if (assignedPlayers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No players yet. Add from your roster or create a new player.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...assignedPlayers.map((p) => Container(
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
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _SkillChip(skill: p.skill),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 22),
                      color: AppColors.textSecondary,
                      onPressed: () => onEditPlayer(p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      color: AppColors.textSecondary,
                      onPressed: () => onRemovePlayer(p.uuid),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 16),
        _AddPlayerCard(onTap: onAddPlayer),
      ],
    );
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

class _AddPlayerCard extends StatelessWidget {
  const _AddPlayerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.chipInactive, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              'Add Player',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPlayerDialog extends StatefulWidget {
  const _NewPlayerDialog({
    this.initialName = '',
    required this.initialSkill,
    this.isEdit = false,
  });

  final String initialName;
  final Skill initialSkill;
  final bool isEdit;

  @override
  State<_NewPlayerDialog> createState() => _NewPlayerDialogState();
}

class _NewPlayerDialogState extends State<_NewPlayerDialog> {
  late TextEditingController _controller;
  late Skill _skill;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _skill = widget.initialSkill;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit player' : 'New player'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Player name',
                hintText: 'e.g. Alex',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            const Text('Skill', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Strong'),
                  selected: _skill == Skill.strong,
                  onSelected: (_) => setState(() => _skill = Skill.strong),
                  selectedColor: AppColors.skillStrong.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Developing'),
                  selected: _skill == Skill.developing,
                  onSelected: (_) => setState(() => _skill = Skill.developing),
                  selectedColor: AppColors.skillDev.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(),
          child: Text(widget.isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, skill: _skill));
  }
}
