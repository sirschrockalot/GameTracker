import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../data/isar/models/player.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../providers/current_user_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/players_provider.dart';
import '../../providers/teams_provider.dart';

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedPlayerIds = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddPlayers(BuildContext context, List<Player> allPlayers) async {
    final assigned = _selectedPlayerIds.toSet();
    final available = allPlayers.where((p) => !assigned.contains(p.uuid)).toList();
    if (available.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All players are already added. Add a new player below.'),
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
    if (chosen != null && chosen.isNotEmpty && mounted) {
      setState(() => _selectedPlayerIds.addAll(chosen));
    }
  }

  Future<void> _showAddNewPlayer(BuildContext context) async {
    final result = await showDialog<({String name, Skill skill})>(
      context: context,
      builder: (ctx) => _CreateTeamNewPlayerDialog(),
    );
    if (result == null || result.name.isEmpty || !mounted) return;
    final isar = await ref.read(isarProvider.future);
    final player = Player.create(uuid: const Uuid().v4(), name: result.name, skill: result.skill);
    await PlayerRepository(isar).add(player);
    ref.invalidate(playersFutureProvider);
    if (mounted) setState(() => _selectedPlayerIds.add(player.uuid));
  }

  Future<void> _createTeam() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a team name')),
      );
      return;
    }
    final isar = await ref.read(isarProvider.future);
    final ownerUserId = ref.read(currentUserIdProvider);
    final team = Team.create(
      uuid: const Uuid().v4(),
      name: name,
      playerIds: List<String>.from(_selectedPlayerIds),
      ownerUserId: ownerUserId,
    );
    await TeamRepository(isar).add(team);
    if (!mounted) return;
    context.pop();
    context.push('/teams/${team.uuid}');
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersFutureProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New team'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: playersAsync.when(
        data: (allPlayers) {
          final assignedPlayers = _selectedPlayerIds
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
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Eagles',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Players',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showAddPlayers(context, allPlayers),
                        icon: const Icon(Icons.person_add, size: 20),
                        label: const Text('Add from roster'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showAddNewPlayer(context),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New player'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (assignedPlayers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
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
                        color: AppColors.chipInactive.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
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
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.textSecondary,
                            onPressed: () {
                              setState(() => _selectedPlayerIds.remove(p.uuid));
                            },
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _createTeam,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create team'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Could not load data',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(isarProvider);
                    ref.invalidate(playersFutureProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
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

class _CreateTeamNewPlayerDialog extends StatefulWidget {
  @override
  State<_CreateTeamNewPlayerDialog> createState() => _CreateTeamNewPlayerDialogState();
}

class _CreateTeamNewPlayerDialogState extends State<_CreateTeamNewPlayerDialog> {
  final TextEditingController _controller = TextEditingController();
  Skill _skill = Skill.developing;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, skill: _skill));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New player'),
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
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
