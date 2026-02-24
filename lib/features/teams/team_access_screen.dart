import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_providers.dart';
import '../../auth/team_members_api.dart';
import '../../core/feature_flags.dart';
import '../../core/theme.dart';
import '../../data/isar/models/join_request.dart';
import '../../data/isar/models/team.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../providers/current_user_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/join_request_provider.dart';
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
    final isOwner = team.ownerUserId == currentUserId;
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

    final ownersAndCoaches = _localApproved
        .where((m) => m.role == TeamMemberRole.owner || m.role == TeamMemberRole.coach)
        .toList()
      ..sort((a, b) => a.role.index.compareTo(b.role.index));
    final parents = _localApproved.where((m) => m.role == TeamMemberRole.parent).toList();

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
            if (ownersAndCoaches.isEmpty)
              _EmptySection(text: 'No coaches yet. Share the coach code to invite another coach.')
            else
              ...ownersAndCoaches.map((m) => _MemberTile(
                    member: m,
                    isOwner: m.role == TeamMemberRole.owner,
                    canRevoke: widget.isOwner && m.role != TeamMemberRole.owner,
                    onRevoke: () => _revokeMember(context, m),
                  )),
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
            if (parents.isEmpty)
              _EmptySection(text: 'No parents yet. Share the parent code to invite parents.')
            else
              ...parents.map((m) => _MemberTile(
                    member: m,
                    isOwner: false,
                    canRevoke: widget.isOwner,
                    onRevoke: () => _revokeMember(context, m),
                  )),
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
            if (_localPending.isEmpty)
              _EmptySection(text: 'No pending requests.')
            else
              ..._localPending.map((r) => _PendingTile(
                    request: r,
                    onApprove: () => _approveRequest(context, r),
                    onReject: () => _rejectRequest(context, r),
                  )),
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
            if (ownersAndCoaches.isEmpty && parents.isEmpty)
              _EmptySection(text: 'No active members yet.')
            else ...[
              ...ownersAndCoaches.map((m) => _MemberTile(
                    member: m,
                    isOwner: m.role == TeamMemberRole.owner,
                    canRevoke: false,
                  )),
              const SizedBox(height: 16),
              ...parents.map((m) => _MemberTile(
                    member: m,
                    isOwner: false,
                    canRevoke: false,
                  )),
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

