import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_providers.dart';
import '../../auth/join_team_api.dart';
import '../../auth/team_members_api.dart';
import '../../core/feature_flags.dart';
import '../../core/theme.dart';
import '../../data/isar/models/join_request.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../domain/authorization/team_auth.dart';
import '../../providers/current_user_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/join_request_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/teams_provider.dart';

class TeamAccessScreen extends ConsumerWidget {
  const TeamAccessScreen({super.key, required this.teamUuid});

  final String teamUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsStreamProvider).valueOrNull ?? [];
    final team = teams.where((t) => t.uuid == teamUuid).firstOrNull;
    if (team == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Team access'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Team not found')),
      );
    }

    final currentUserId = ref.watch(currentUserIdProvider);
    final installId = ref.watch(installIdProvider).valueOrNull;
    final isOwner = TeamAuth.isOwner(team, currentUserId, installId);
    final isCoachViewOnly = FeatureFlags.enableMembershipAuthV2 && !isOwner;

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
        title: const Text('Team access'),
        centerTitle: true,
      ),
      body: _TeamAccessBody(team: team, isOwner: isOwner, isCoachViewOnly: isCoachViewOnly),
    );
  }
}

class _TeamAccessBody extends ConsumerStatefulWidget {
  const _TeamAccessBody({
    required this.team,
    required this.isOwner,
    required this.isCoachViewOnly,
  });

  final Team team;
  final bool isOwner;
  final bool isCoachViewOnly;

  @override
  ConsumerState<_TeamAccessBody> createState() => _TeamAccessBodyState();
}

class _TeamAccessBodyState extends ConsumerState<_TeamAccessBody> {
  bool _loading = true;
  List<JoinRequest> _localApproved = [];
  List<JoinRequest> _localPending = [];

  @override
  void initState() {
    super.initState();
    // Always fetch latest pending list from backend when this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(serverPendingRequestsProvider(widget.team.uuid));
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isar = await ref.read(isarProvider.future);
    final joinRepo = JoinRequestRepository(isar);
    final approved = await joinRepo.watchApprovedByTeamId(widget.team.uuid).first;
    final pending = await joinRepo.watchPendingByTeamId(widget.team.uuid).first;
    setState(() {
      _localApproved = approved;
      _localPending = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOwner && !widget.isCoachViewOnly) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Only coaches and owners can view team access.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final baseUrl = ref.watch(apiBaseUrlProvider);
    final hasBackend = baseUrl.isNotEmpty;

    final serverPendingAsync =
        ref.watch(serverPendingRequestsProvider(widget.team.uuid));
    final serverPending = serverPendingAsync.valueOrNull ?? [];
    final serverMembersAsync = ref.watch(serverTeamMembersProvider(widget.team.uuid));
    final serverActive = (serverMembersAsync.valueOrNull ?? [])
        .where((m) => m['status'] == 'active')
        .toList();
    final localApprovedUserIds = _localApproved.map((m) => m.userId).toSet();

    final localOwnersAndCoaches = _localApproved
        .where((m) => m.role == TeamMemberRole.owner || m.role == TeamMemberRole.coach)
        .toList()
      ..sort((a, b) => a.role.index.compareTo(b.role.index));
    final serverCoaches = serverActive
        .where((m) =>
            (m['role'] == 'owner' || m['role'] == 'coach') &&
            !localApprovedUserIds.contains(m['userId'] as String?))
        .toList();

    final localParents = _localApproved.where((m) => m.role == TeamMemberRole.parent).toList();
    final serverParents = serverActive
        .where((m) =>
            m['role'] == 'parent' &&
            !localApprovedUserIds.contains(m['userId'] as String?))
        .toList();

    final ownersAndCoachesEmpty = localOwnersAndCoaches.isEmpty && serverCoaches.isEmpty;
    final parentsEmpty = localParents.isEmpty && serverParents.isEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.isOwner) ...[
            const Text(
              'Coaches',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (ownersAndCoachesEmpty)
              _EmptySection(text: 'No coaches yet. Share the coach code to invite another coach.')
            else ...[
              ...localOwnersAndCoaches.map((m) => _MemberTile(
                    member: m,
                    isOwner: m.role == TeamMemberRole.owner,
                    canRevoke: widget.isOwner && m.role != TeamMemberRole.owner,
                    onRevoke: () => _revokeMember(context, m),
                  )),
              ...serverCoaches.map((m) => _ServerMemberTile(
                    member: m,
                    onRevoke: widget.isOwner && m['role'] != 'owner'
                        ? () => _revokeServerMember(context, m)
                        : null,
                  )),
            ],
            const SizedBox(height: 24),
            const Text(
              'Parents',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (parentsEmpty)
              _EmptySection(text: 'No parents yet. Share the parent code to invite parents.')
            else ...[
              ...localParents.map((m) => _MemberTile(
                    member: m,
                    isOwner: false,
                    canRevoke: widget.isOwner,
                    onRevoke: () => _revokeMember(context, m),
                  )),
              ...serverParents.map((m) => _ServerMemberTile(
                    member: m,
                    onRevoke: widget.isOwner ? () => _revokeServerMember(context, m) : null,
                  )),
            ],
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
            if (hasBackend) ...[
              if (serverPendingAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (serverPendingAsync.hasError)
                _ErrorBanner(
                  message: 'Could not load pending requests from the cloud.',
                  onRetry: () {
                    ref.invalidate(
                        serverPendingRequestsProvider(widget.team.uuid));
                  },
                )
              else if (serverPending.isEmpty)
                const _EmptySection(text: 'No pending requests.')
              else ...[
                ...serverPending.map(
                  (m) => _ServerPendingTile(
                    member: m,
                    onApprove: () => _approveServerRequest(context, m),
                    onReject: () => _rejectServerRequest(context, m),
                  ),
                ),
              ],
            ] else ...[
              if (_localPending.isEmpty && serverPending.isEmpty)
                const _EmptySection(text: 'No pending requests.')
              else ...[
                ...serverPending.map(
                  (m) => _ServerPendingTile(
                    member: m,
                    onApprove: () => _approveServerRequest(context, m),
                    onReject: () => _rejectServerRequest(context, m),
                  ),
                ),
                ..._localPending.map(
                  (r) => _PendingTile(
                    request: r,
                    onApprove: () => _approveRequest(context, r),
                    onReject: () => _rejectRequest(context, r),
                  ),
                ),
              ],
            ],
          ],
          if (!widget.isOwner && widget.isCoachViewOnly) ...[
            const Text(
              'Members',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (ownersAndCoachesEmpty && parentsEmpty)
              _EmptySection(text: 'No active members yet.')
            else ...[
              ...localOwnersAndCoaches.map((m) => _MemberTile(
                    member: m,
                    isOwner: m.role == TeamMemberRole.owner,
                    canRevoke: false,
                  )),
              ...serverCoaches.map((m) => _ServerMemberTile(member: m, onRevoke: null)),
              const SizedBox(height: 16),
              ...localParents.map((m) => _MemberTile(
                    member: m,
                    isOwner: false,
                    canRevoke: false,
                  )),
              ...serverParents.map((m) => _ServerMemberTile(member: m, onRevoke: null)),
            ]
          ],
        ],
      ),
    );
  }

  Future<void> _revokeMember(BuildContext context, JoinRequest member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove access?'),
        content: Text(
          '${member.coachName} will lose access to this team.',
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
        SnackBar(content: Text('${member.coachName} removed')),
      );
    }
    await _load();
  }

  Future<void> _approveRequest(BuildContext context, JoinRequest request) async {
    final isar = await ref.read(isarProvider.future);
    final approvedBy = ref.read(currentUserIdProvider);
    await JoinRequestRepository(isar).approve(request.uuid, approvedBy);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.coachName} approved')),
      );
    }
    await _load();
    ref.invalidate(serverPendingRequestsProvider(widget.team.uuid));
    ref.invalidate(pendingNotificationsSummaryProvider);
  }

  Future<void> _rejectRequest(BuildContext context, JoinRequest request) async {
    final isar = await ref.read(isarProvider.future);
    await JoinRequestRepository(isar).reject(request.uuid, updatedBy: ref.read(currentUserIdProvider));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request from ${request.coachName} rejected')),
      );
    }
    await _load();
    ref.invalidate(serverPendingRequestsProvider(widget.team.uuid));
    ref.invalidate(pendingNotificationsSummaryProvider);
  }

  Future<void> _approveServerRequest(BuildContext context, Map<String, dynamic> member) async {
    final requestId = member['uuid'] as String?;
    if (requestId == null) return;
    try {
      final client = ref.read(authenticatedHttpClientProvider);
      await approveRequest(client, widget.team.uuid, requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member['coachName'] ?? 'Coach'} approved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approve failed: $e')),
        );
      }
    }
    ref.invalidate(serverPendingRequestsProvider(widget.team.uuid));
    ref.invalidate(serverTeamMembersProvider(widget.team.uuid));
    ref.invalidate(pendingNotificationsSummaryProvider);
  }

  Future<void> _rejectServerRequest(BuildContext context, Map<String, dynamic> member) async {
    final requestId = member['uuid'] as String?;
    if (requestId == null) return;
    try {
      final client = ref.read(authenticatedHttpClientProvider);
      await rejectRequest(client, widget.team.uuid, requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request from ${member['coachName'] ?? 'coach'} rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reject failed: $e')),
        );
      }
    }
    ref.invalidate(serverPendingRequestsProvider(widget.team.uuid));
    ref.invalidate(serverTeamMembersProvider(widget.team.uuid));
    ref.invalidate(pendingNotificationsSummaryProvider);
  }

  Future<void> _revokeServerMember(BuildContext context, Map<String, dynamic> member) async {
    final memberId = member['uuid'] as String?;
    if (memberId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove access?'),
        content: Text(
          '${member['coachName'] ?? 'This member'} will lose access to this team.',
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
    try {
      final client = ref.read(authenticatedHttpClientProvider);
      await revokeMember(client, widget.team.uuid, memberId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member['coachName'] ?? 'Member'} removed')),
        );
      }
      ref.invalidate(serverTeamMembersProvider(widget.team.uuid));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove failed: $e')),
        );
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.canRevoke,
    this.onRevoke,
  });

  final JoinRequest member;
  final bool isOwner;
  final bool canRevoke;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final roleLabel = member.role == TeamMemberRole.owner
        ? 'Owner'
        : member.role == TeamMemberRole.coach
            ? 'Coach'
            : 'Parent';
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
                Text(
                  member.coachName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel • Active',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (canRevoke && onRevoke != null)
            TextButton(
              onPressed: onRevoke,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
        ],
      ),
    );
  }
}

class _ServerMemberTile extends StatelessWidget {
  const _ServerMemberTile({
    required this.member,
    this.onRevoke,
  });

  final Map<String, dynamic> member;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final coachName = member['coachName'] as String? ?? 'Unknown';
    final roleRaw = member['role'] as String? ?? 'coach';
    final roleLabel = roleRaw == 'owner'
        ? 'Owner'
        : roleRaw == 'parent'
            ? 'Parent'
            : 'Coach';
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
                Text(
                  coachName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel • Active',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onRevoke != null)
            TextButton(
              onPressed: onRevoke,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final JoinRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final roleLabel = request.role == TeamMemberRole.parent ? 'Parent' : 'Coach';
    return Container(
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
              children: [
                Text(
                  request.coachName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel • Requested',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (request.note != null && request.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.note!,
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
            onPressed: onReject,
            child: const Text('Reject'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}

class _ServerPendingTile extends StatelessWidget {
  const _ServerPendingTile({
    required this.member,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> member;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final coachName = member['coachName'] as String? ?? 'Unknown coach';
    final roleRaw = member['role'] as String? ?? 'coach';
    final roleLabel = roleRaw == 'parent' ? 'Parent' : 'Coach';
    final requestedAt = member['requestedAt'] as String?;
    final requestedAtText = _formatRequestedAt(requestedAt);
    return Container(
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
              children: [
                Text(
                  coachName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel • $requestedAtText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (member['note'] is String && (member['note'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    member['note'] as String,
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
            onPressed: onReject,
            child: const Text('Reject'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  static String _formatRequestedAt(String? iso) {
    if (iso == null) return 'Requested';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Requested';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.redAccent,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
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

