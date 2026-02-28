import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_providers.dart';
import '../../auth/notifications_api.dart';
import '../../core/feature_flags.dart';
import '../../core/theme.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/team_repository.dart';
import '../../providers/isar_provider.dart';
import '../../providers/join_request_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/players_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/team_logo_avatar.dart';

class TeamsListScreen extends ConsumerWidget {
  const TeamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(visibleTeamsStreamProvider);
    final summaryAsync = ref.watch(pendingNotificationsSummaryProvider);
    final refreshTeamsAsync = ref.watch(refreshTeamsFromServerProvider);
    ref.watch(notificationsPollerProvider);

    ref.listen<AsyncValue<PendingRequestsSummary>>(
      pendingNotificationsSummaryProvider,
      (previous, next) {
        if (previous == null) return;
        if (previous is AsyncData && next is AsyncData) {
          final prevTotal = previous.valueOrNull?.totalPending ?? 0;
          final nextTotal = next.valueOrNull?.totalPending ?? 0;
          if (nextTotal > prevTotal && nextTotal > 0) {
            final contextMounted = context.mounted;
            if (contextMounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('New join request pending approval'),
                  action: SnackBarAction(
                    label: 'Review',
                    onPressed: () {
                      // Navigate to teams list; owner can open specific team access from there.
                      context.go('/teams');
                    },
                  ),
                ),
              );
            }
          }
        }
      },
    );
    final playersAsync = ref.watch(playersFutureProvider);
    final allPlayers = playersAsync.valueOrNull ?? [];

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${teams.length} team${teams.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    _SyncStatusLine(),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (FeatureFlags.enableMembershipAuthV2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (refreshTeamsAsync.isLoading)
                      const Text(
                        'Refreshing from cloud…',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else if (refreshTeamsAsync.hasError)
                      Flexible(
                        child: Text(
                          'Showing offline teams. Refresh to check cloud access.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    TextButton.icon(
                      onPressed: () async {
                        await ref.refresh(membershipSyncProvider.future);
                        await ref.refresh(refreshTeamsFromServerProvider.future);
                        await ref.refresh(pendingNotificationsSummaryProvider.future);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh teams'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      await ref.refresh(membershipSyncProvider.future);
                      await ref.refresh(refreshTeamsFromServerProvider.future);
                      await ref.refresh(pendingNotificationsSummaryProvider.future);
                    },
                    child: teamsAsync.when(
                      data: (teams) {
                        final summary = summaryAsync.valueOrNull;
                        final pendingMap = summary?.pendingByTeam ?? const {};
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
                            final playerCount = allPlayers.where((p) => p.teamId == team.uuid).length;
                            final pendingCount = pendingMap[team.uuid] ?? 0;
                            return _TeamCard(
                              team: team,
                              playerCount: playerCount,
                              pendingCount: pendingCount,
                              onDelete: () => _deleteTeam(context, ref, team),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ref.watch(pendingOutboxCountStreamProvider).when(
                      data: (count) => count > 0
                          ? Material(
                              color: Colors.amber.shade100,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  '$count pending sync op(s)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DebugAccessPanel(),
              ),
            ],
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

class _SyncStatusLine extends ConsumerWidget {
  const _SyncStatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRefresh = ref.watch(lastTeamsRefreshTimeProvider);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    if (baseUrl.isEmpty) return const SizedBox.shrink();
    String text;
    if (lastRefresh == null) {
      text = 'Offline';
    } else {
      final diff = DateTime.now().difference(lastRefresh);
      if (diff.inMinutes < 1) {
        text = 'Synced just now';
      } else if (diff.inHours < 1) {
        text = 'Synced ${diff.inMinutes}m ago';
      } else {
        text = 'Synced ${diff.inHours}h ago';
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.playerCount,
    required this.pendingCount,
    required this.onDelete,
  });

  final Team team;
  final int playerCount;
  final int pendingCount;
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
          '$playerCount players',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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

class _DebugAccessPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final lastTeamsRefresh = ref.watch(lastTeamsRefreshTimeProvider);
    final lastMembershipRefresh = ref.watch(lastMembershipRefreshTimeProvider);
    final lastPendingCount = ref.watch(lastPendingListFetchCountProvider);
    final lastSummaryCount = ref.watch(lastNotificationsSummaryCountProvider);
    final lastApiError = ref.watch(lastApiErrorProvider);
    final membershipCountsAsync = ref.watch(membershipCountsProvider);
    final visibleTeamsAsync = ref.watch(visibleTeamsStreamProvider);

    String _formatTime(DateTime? dt) {
      if (dt == null) return 'never';
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.chipInactive),
      ),
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug – Access state',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UserId: $userId',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'Backend: ${baseUrl.isEmpty ? 'disabled' : baseUrl}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            membershipCountsAsync.when(
              data: (c) => Text(
                'Memberships: active=${c.active} pending=${c.pending} revoked=${c.revoked}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            visibleTeamsAsync.when(
              data: (teams) => Text(
                'Teams visible: ${teams.length}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Text(
              'Last membership refresh: ${_formatTime(lastMembershipRefresh)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'Last /teams refresh: ${_formatTime(lastTeamsRefresh)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (visibleTeamsAsync.valueOrNull != null)
              ...visibleTeamsAsync.valueOrNull!.take(5).map((t) => Text(
                '  ${t.name}: hydrated ${_formatTime(t.lastSyncedAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              )),
            Text(
              'Last pending-list count: $lastPendingCount',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'Last summary totalPending: $lastSummaryCount',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (lastApiError != null && lastApiError.isNotEmpty)
              Text(
                'Last API error: $lastApiError',
                style: const TextStyle(fontSize: 11, color: Colors.red),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  ref.read(lastApiErrorProvider.notifier).state = null;
                  await ref.refresh(membershipSyncProvider.future);
                  await ref.refresh(refreshTeamsFromServerProvider.future);
                  await ref.refresh(pendingNotificationsSummaryProvider.future);
                  final lastTeamId = ref.read(lastPendingListFetchTeamIdProvider);
                  if (lastTeamId != null && lastTeamId.isNotEmpty) {
                    await ref.refresh(serverPendingRequestsProvider(lastTeamId).future);
                  }
                },
                icon: const Icon(Icons.bug_report, size: 18),
                label: const Text('Force refresh everything'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
