import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/feature_flags.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/team_repository.dart';
import '../../providers/isar_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/team_logo_avatar.dart';

class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'My Teams',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            teamsAsync.when(
              data: (teams) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${teams.length} team${teams.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: teamsAsync.when(
                data: (teams) {
                  final showJoin = FeatureFlags.enableMembershipAuthV2;
                  final extraCards = showJoin ? 2 : 1;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: teams.length + extraCards,
                    itemBuilder: (context, i) {
                      if (showJoin && i == teams.length) {
                        return _JoinTeamCard(
                          onTap: () => context.push('/teams/join'),
                        );
                      }
                      if (i == teams.length + (showJoin ? 1 : 0)) {
                        return _AddTeamCard(
                          onTap: () => context.push('/teams/new'),
                        );
                      }
                      final team = teams[i];
                      return _TeamCard(team: team, onDelete: () => _deleteTeam(context, ref, team));
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/teams'),
    );
  }

  Future<void> _deleteTeam(BuildContext context, WidgetRef ref, Team team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete team?'),
        content: Text('${team.name} will be removed. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
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
    await TeamRepository(isar).deleteByUuid(team.uuid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${team.name} deleted')),
      );
    }
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onDelete});

  final Team team;
  final VoidCallback onDelete;

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
        subtitle: Text(
          '${team.playerIds.length} players',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 22),
              color: AppColors.textSecondary,
              onPressed: () => context.push('/teams/${team.uuid}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 22),
              color: AppColors.textSecondary,
              onPressed: onDelete,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 28),
              color: AppColors.textSecondary,
              onPressed: () => context.push('/teams/${team.uuid}'),
            ),
          ],
        ),
        onTap: () => context.push('/teams/${team.uuid}'),
      ),
    );
  }
}

class _JoinTeamCard extends StatelessWidget {
  const _JoinTeamCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.chipInactive, width: 2, strokeAlign: BorderSide.strokeAlignInside),
      ),
      color: Colors.white.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_add, size: 32, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                'Join team',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTeamCard extends StatelessWidget {
  const _AddTeamCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.chipInactive, width: 2, strokeAlign: BorderSide.strokeAlignInside),
      ),
      color: Colors.white.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 32, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                'Add Team',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
