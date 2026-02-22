import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../auth/auth_providers.dart';
import '../../auth/auth_session.dart';
import '../../auth/bootstrap_api.dart';
import '../../config/backend_config.dart';
import '../../data/sync/bootstrap_upsert.dart';
import '../../core/theme.dart';
import '../../core/feature_flags.dart';
import '../../widgets/team_logo_avatar.dart';
import '../../widgets/team_logo_picker.dart';
import '../../data/isar/models/join_request.dart';
import '../../data/isar/models/player.dart';
import '../../data/isar/models/team.dart';
import '../../domain/authorization/team_auth.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../providers/current_user_provider.dart';
import '../../providers/join_request_provider.dart';
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

    final teamPlayersAsync = team != null
        ? ref.watch(playersForTeamProvider(team!.uuid))
        : AsyncValue.data(<Player>[]);
    final authAsync = ref.watch(authStateProvider);
    final installId = ref.watch(installIdProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        title: team != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TeamLogoAvatar(team: team!, size: 36),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${team!.name} Players', overflow: TextOverflow.ellipsis)),
                ],
              )
            : null,
        centerTitle: true,
      ),
      body: team == null
          ? const Center(child: Text('Team not found'))
          : authAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _teamDetailContent(
                ref, context, team!, teamPlayersAsync, playersAsync, _nameController,
                installId,
              ),
              data: (_) => _teamDetailContent(
                ref, context, team!, teamPlayersAsync, playersAsync, _nameController,
                installId,
              ),
            ),
    );
  }

  Widget _teamDetailContent(
    WidgetRef ref,
    BuildContext context,
    Team team,
    AsyncValue<List<Player>> teamPlayersAsync,
    AsyncValue<List<Player>> playersAsync,
    TextEditingController nameController,
    String? installId,
  ) {
    return teamPlayersAsync.when(
      data: (assignedPlayers) {
        final players = assignedPlayers as List<Player>;
        final currentUserId = ref.watch(currentUserIdProvider);
        final pendingAsync = ref.watch(pendingJoinRequestsProvider(team.uuid));
        final approvedAsync = ref.watch(approvedMembersProvider(team.uuid));
        final pendingRequests = pendingAsync.valueOrNull ?? [];
        final approvedMembers = approvedAsync.valueOrNull ?? [];
        final isApprovedMember = approvedMembers.any((m) => m.userId == currentUserId);
        final canView = TeamAuth.canViewTeam(team, currentUserId, isApprovedMember, installId);
        final canManage = TeamAuth.canManageTeam(team, currentUserId, installId);
        if (!canView) {
          // Migrate: team may have been created with Firebase UID or 'local'; reclaim ownership for this device.
          final canMigrate = team.ownerUserId != null &&
              team.ownerUserId != currentUserId &&
              team.ownerUserId != installId &&
              (team.ownerUserId == 'local' || TeamAuth.looksLikeFirebaseUid(team.ownerUserId));
          if (canMigrate) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _migrateTeamOwnerToCurrentUser(ref, team);
            });
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "You don't have access to this team.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return _TeamDetailBody(
          team: team,
          assignedPlayers: players,
          allPlayersAsync: playersAsync,
          nameController: nameController,
          onSaveName: () => _saveName(ref, team),
          onSaveLogo: (kind, templateId, paletteId, monogramText) => _saveLogo(ref, team, kind, templateId, paletteId, monogramText),
          onRemovePlayer: (uuid) => _removePlayer(ref, team, uuid),
          onEditPlayer: (p) => _showEditPlayer(context, ref, p),
          onAddPlayer: () => _showAddPlayerChoice(context, ref, team, players),
          canManage: canManage,
          pendingRequests: pendingRequests,
          approvedMembers: approvedMembers,
          onApproveRequest: (r) => _approveRequest(context, ref, r),
          onRejectRequest: (r) => _rejectRequest(context, ref, r),
          onRevokeMember: (r) => _revokeMember(context, ref, r),
          onRotateCode: () => _rotateCode(context, ref, team),
          onRotateCoachCode: () => _rotateCoachCode(context, ref, team),
          onRotateParentCode: () => _rotateParentCode(context, ref, team),
          onSetDisplayName: () => _showSetDisplayName(context, ref),
          onEnableSync: (team.syncEnabled == true || !canManage) ? null : () => _confirmAndEnableSync(context, ref, team),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _confirmAndEnableSync(BuildContext context, WidgetRef ref, Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Sync'),
        content: const Text(
          'Enable Sync for this team? This will upload your roster and schedule to the cloud.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enable Sync')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _enableSync(context, ref, team);
  }

  Future<void> _enableSync(BuildContext context, WidgetRef ref, Team team) async {
    final baseUrl = ref.read(apiBaseUrlProvider);
    final state = await AuthSession.registerIfNeeded(baseUrl);
    if (state?.token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in required. Check network and try again.')),
        );
      }
      return;
    }
    final isar = await ref.read(isarProvider.future);
    final players = await PlayerRepository(isar).listByTeamId(team.uuid);
    final scheduleEvents = await ScheduleRepository(isar).listByTeamId(team.uuid);
    final client = ref.read(authenticatedHttpClientProvider);
    try {
      final cloudTeams = await listCloudTeams(client);
      if (!cloudTeams.any((t) => t['uuid'] == team.uuid)) {
        await createCloudTeam(client, team.uuid, team.name);
      }
      final response = await bootstrapUpload(client, team.uuid, players, scheduleEvents);
      await upsertBootstrapResponse(isar, response);
      team.syncEnabled = true;
      await TeamRepository(isar).update(team, updatedBy: ref.read(currentUserIdProvider));
      ref.invalidate(teamsStreamProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync enabled. Roster and schedule now use the cloud.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enable sync failed: $e')),
        );
      }
    }
  }

  Future<void> _migrateTeamOwnerToCurrentUser(WidgetRef ref, Team team) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId.isEmpty || userId == 'local') return;
    team.ownerUserId = userId;
    final isar = await ref.read(isarProvider.future);
    await TeamRepository(isar).update(team, updatedBy: userId);
    ref.invalidate(teamsStreamProvider);
    ref.invalidate(playersForTeamProvider(team.uuid));
  }

  Future<void> _saveName(WidgetRef ref, Team team) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    team.name = name;
    final isar = await ref.read(isarProvider.future);
    await TeamRepository(isar).update(team, updatedBy: ref.read(currentUserIdProvider));
  }

  Future<void> _saveLogo(
    WidgetRef ref,
    Team team,
    String kind,
    String? templateId,
    String? paletteId,
    String? monogramText,
  ) async {
    team.logoKind = kind;
    team.templateId = templateId;
    team.paletteId = paletteId;
    team.monogramText = monogramText;
    final isar = await ref.read(isarProvider.future);
    await TeamRepository(isar).update(team, updatedBy: ref.read(currentUserIdProvider));
    ref.invalidate(teamsStreamProvider);
  }

  Future<void> _removePlayer(WidgetRef ref, Team team, String playerUuid) async {
    final isar = await ref.read(isarProvider.future);
    final player = await PlayerRepository(isar).getByUuid(playerUuid);
    if (player == null) return;
    player.teamId = null;
    player.updatedAt = DateTime.now();
    player.updatedBy = ref.read(currentUserIdProvider);
    await PlayerRepository(isar).update(player);
    ref.invalidate(playersForTeamProvider(team.uuid));
    ref.invalidate(playersFutureProvider);
  }

  Future<void> _showAddFromRoster(
    BuildContext context,
    WidgetRef ref,
    Team team,
    List<Player> assignedPlayers,
  ) async {
    final playersAsync = ref.read(playersFutureProvider);
    final allPlayers = playersAsync.valueOrNull ?? [];
    final assignedIds = assignedPlayers.map((p) => p.uuid).toSet();
    final available = allPlayers.where((p) => p.teamId != team.uuid && !assignedIds.contains(p.uuid)).toList();
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
    final isar = await ref.read(isarProvider.future);
    final repo = PlayerRepository(isar);
    final userId = ref.read(currentUserIdProvider);
    for (final uuid in chosen) {
      final p = await repo.getByUuid(uuid);
      if (p != null) {
        p.teamId = team.uuid;
        p.updatedAt = DateTime.now();
        p.updatedBy = userId;
        await repo.update(p);
      }
    }
    ref.invalidate(playersForTeamProvider(team.uuid));
    ref.invalidate(playersFutureProvider);
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
    final player = Player.create(
      uuid: const Uuid().v4(),
      name: result.name,
      skill: result.skill,
      teamId: team.uuid,
    );
    await PlayerRepository(isar).add(player);
    ref.invalidate(playersForTeamProvider(team.uuid));
    ref.invalidate(playersFutureProvider);
  }

  Future<void> _approveRequest(
    BuildContext context,
    WidgetRef ref,
    JoinRequest request,
  ) async {
    final isar = await ref.read(isarProvider.future);
    final approvedBy = ref.read(currentUserIdProvider);
    await JoinRequestRepository(isar).approve(request.uuid, approvedBy);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.coachName} approved')),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    WidgetRef ref,
    JoinRequest request,
  ) async {
    final isar = await ref.read(isarProvider.future);
    await JoinRequestRepository(isar).reject(request.uuid, updatedBy: ref.read(currentUserIdProvider));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request from ${request.coachName} rejected')),
      );
    }
  }

  Future<void> _revokeMember(
    BuildContext context,
    WidgetRef ref,
    JoinRequest member,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          '${member.coachName} will be removed from the team. They can request to join again after 24 hours or with a new team code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final isar = await ref.read(isarProvider.future);
    await JoinRequestRepository(isar).revoke(member.uuid, updatedBy: ref.read(currentUserIdProvider));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.coachName} removed from team')),
      );
    }
  }

  Future<void> _rotateCode(BuildContext context, WidgetRef ref, Team team) async {
    final isar = await ref.read(isarProvider.future);
    final newCode = await TeamRepository(isar).rotateInviteCode(team.uuid);
    if (!context.mounted || newCode == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New code generated. Share it for new join requests.')),
    );
  }

  Future<void> _rotateCoachCode(BuildContext context, WidgetRef ref, Team team) async {
    final isar = await ref.read(isarProvider.future);
    final newCode = await TeamRepository(isar).rotateCoachCode(team.uuid);
    if (!context.mounted || newCode == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coach code rotated. Share the new code for coach join requests.')),
    );
  }

  Future<void> _rotateParentCode(BuildContext context, WidgetRef ref, Team team) async {
    final isar = await ref.read(isarProvider.future);
    final newCode = await TeamRepository(isar).rotateParentCode(team.uuid);
    if (!context.mounted || newCode == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parent code rotated. Share the new code for parent join requests.')),
    );
  }

  Future<void> _showSetDisplayName(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authStateProvider).valueOrNull;
    final current = auth?.displayName ?? '';
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Coach Mike (2–40 characters)',
            border: OutlineInputBorder(),
          ),
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.length >= 2) Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.length >= 2 && context.mounted) {
      try {
        await ref.read(authStateProvider.notifier).updateDisplayName(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Display name updated')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update. Check network.')));
        }
      }
    }
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

  void _showAddPlayerChoice(BuildContext context, WidgetRef ref, Team team, List<Player> assignedPlayers) {
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
                  _showAddFromRoster(context, ref, team, assignedPlayers);
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
    required this.assignedPlayers,
    required this.allPlayersAsync,
    required this.nameController,
    required this.onSaveName,
    this.onSaveLogo,
    required this.onRemovePlayer,
    required this.onEditPlayer,
    required this.onAddPlayer,
    required this.canManage,
    required this.pendingRequests,
    required this.approvedMembers,
    required this.onApproveRequest,
    required this.onRejectRequest,
    required this.onRevokeMember,
    this.onRotateCode,
    this.onRotateCoachCode,
    this.onRotateParentCode,
    this.onSetDisplayName,
    this.onEnableSync,
  });

  final VoidCallback? onSetDisplayName;
  final VoidCallback? onEnableSync;

  final Team team;
  final List<Player> assignedPlayers;
  final AsyncValue<List<Player>> allPlayersAsync;
  final TextEditingController nameController;
  final VoidCallback onSaveName;
  final void Function(String kind, String? templateId, String? paletteId, String? monogramText)? onSaveLogo;
  final void Function(String uuid) onRemovePlayer;
  final void Function(Player p) onEditPlayer;
  final VoidCallback onAddPlayer;
  final bool canManage;
  final List<JoinRequest> pendingRequests;
  final List<JoinRequest> approvedMembers;
  final void Function(JoinRequest request) onApproveRequest;
  final void Function(JoinRequest request) onRejectRequest;
  final void Function(JoinRequest member) onRevokeMember;
  final VoidCallback? onRotateCode;
  final VoidCallback? onRotateCoachCode;
  final VoidCallback? onRotateParentCode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onSetDisplayName != null) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Display name', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12)),
            subtitle: const Text('How you appear to others (e.g. Coach Mike)', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
            onTap: onSetDisplayName,
          ),
          const SizedBox(height: 16),
        ],
        if (onEnableSync != null) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Sync', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12)),
            subtitle: const Text('Upload roster and schedule to the cloud', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.cloud_upload, size: 20, color: AppColors.textSecondary),
            onTap: onEnableSync,
          ),
          const SizedBox(height: 16),
        ],
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
          readOnly: !canManage,
          decoration: InputDecoration(
            hintText: 'Team name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: canManage
                ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: onSaveName,
                  )
                : null,
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => canManage ? onSaveName() : null,
        ),
        if (canManage && onSaveLogo != null) ...[
          const SizedBox(height: 24),
          TeamLogoPicker(
            teamName: nameController.text.trim().isEmpty ? team.name : nameController.text.trim(),
            logoKind: team.logoKind ?? 'none',
            templateId: team.templateId,
            paletteId: team.paletteId,
            monogramText: team.monogramText,
            onSelect: onSaveLogo!,
          ),
        ],
        if (canManage) ...[
          const SizedBox(height: 24),
          Text(
            'Team code (share to join)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SelectableText(
                  team.inviteCode.isEmpty ? '—' : team.inviteCode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: team.inviteCode.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                ),
              ),
              if (team.inviteCode.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 22),
                  tooltip: 'Copy code',
                  color: AppColors.textSecondary,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: team.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                ),
              if (onRotateCode != null)
                TextButton.icon(
                  onPressed: onRotateCode,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: Text(team.inviteCode.isEmpty ? 'Generate code' : 'Rotate code'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                  ),
                ),
            ],
          ),
          if (FeatureFlags.enableMembershipAuthV2) ...[
            const SizedBox(height: 12),
            Text(
              'Coach code',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SelectableText(
                    team.coachCode.isEmpty ? '—' : team.coachCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: team.coachCode.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
                if (team.coachCode.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 22),
                    tooltip: 'Copy coach code',
                    color: AppColors.textSecondary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: team.coachCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coach code copied')),
                      );
                    },
                  ),
                if (onRotateCoachCode != null)
                  TextButton.icon(
                    onPressed: onRotateCoachCode,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(team.coachCode.isEmpty ? 'Generate code' : 'Rotate'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryOrange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Parent code',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SelectableText(
                    team.parentCode.isEmpty ? '—' : team.parentCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: team.parentCode.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
                if (team.parentCode.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 22),
                    tooltip: 'Copy parent code',
                    color: AppColors.textSecondary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: team.parentCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Parent code copied')),
                      );
                    },
                  ),
                if (onRotateParentCode != null)
                  TextButton.icon(
                    onPressed: onRotateParentCode,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(team.parentCode.isEmpty ? 'Generate code' : 'Rotate'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryOrange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
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
                    if (canManage) ...[
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
                  ],
                ),
              )),
        if (FeatureFlags.enableMembershipAuthV2 &&
            canManage &&
            pendingRequests.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Pending requests',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...pendingRequests.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.chipInactive),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.coachName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_roleRequestedLabel(r.role)} • ${_formatRequestedAt(r.requestedAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (r.note != null && r.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              r.note!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onRejectRequest(r),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => onApproveRequest(r),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              )),
        ],
        if (FeatureFlags.enableMembershipAuthV2 &&
            canManage &&
            approvedMembers.isNotEmpty) ...[
          const SizedBox(height: 24),
          ..._membersGroupedByRole(team, approvedMembers).entries.map((e) {
            final sectionTitle = e.key;
            final members = e.value;
            if (members.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ...members.map((m) => Container(
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
                                Text(
                                  m.coachName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _roleRequestedLabel(m.role),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onCourtGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (team.ownerUserId != m.userId)
                            TextButton(
                              onPressed: () => onRevokeMember(m),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Remove'),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
        if (canManage) ...[
          const SizedBox(height: 16),
          _AddPlayerCard(onTap: onAddPlayer),
        ],
      ],
    );
  }

  static String _roleRequestedLabel(TeamMemberRole role) {
    switch (role) {
      case TeamMemberRole.owner:
        return 'Owner';
      case TeamMemberRole.coach:
        return 'Coach';
      case TeamMemberRole.parent:
        return 'Parent';
    }
  }

  /// Returns members grouped by role: Coaches (owner + coach), then Parents.
  static Map<String, List<JoinRequest>> _membersGroupedByRole(
    Team team,
    List<JoinRequest> approvedMembers,
  ) {
    final coaches = approvedMembers
        .where((m) => m.role == TeamMemberRole.owner || m.role == TeamMemberRole.coach)
        .toList();
    final parents =
        approvedMembers.where((m) => m.role == TeamMemberRole.parent).toList();
    coaches.sort((a, b) {
      final aOwner = a.userId == team.ownerUserId ? 1 : 0;
      final bOwner = b.userId == team.ownerUserId ? 1 : 0;
      return bOwner.compareTo(aOwner);
    });
    return {'Coaches': coaches, 'Parents': parents};
  }

  static String _formatRequestedAt(DateTime at) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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
