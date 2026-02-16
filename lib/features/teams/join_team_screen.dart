import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../core/feature_flags.dart';
import '../../data/isar/models/join_request.dart';
import '../../data/isar/models/team.dart';
import '../../domain/validation/join_request_validators.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../providers/current_user_provider.dart';
import '../../providers/isar_provider.dart';
import '../../widgets/app_bottom_nav.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  final _coachNameController = TextEditingController();
  final _teamCodeController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _coachNameController.dispose();
    _teamCodeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _teamCodeController.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your name and team code')),
        );
      }
      return;
    }
    final coachNameResult = JoinRequestValidators.validateCoachName(_coachNameController.text);
    if (coachNameResult.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(coachNameResult.error!)),
        );
      }
      return;
    }
    final coachName = coachNameResult.value!;
    final note = JoinRequestValidators.validateNote(_noteController.text);
    setState(() => _submitting = true);
    final isar = await ref.read(isarProvider.future);
    final teamRepo = TeamRepository(isar);
    final normalizedCode = code.toUpperCase();
    Team? team;
    TeamMemberRole? requestedRole;
    final byCoach = await teamRepo.getByCoachCode(normalizedCode);
    if (byCoach != null) {
      team = byCoach;
      requestedRole = TeamMemberRole.coach;
    } else {
      final byParent = await teamRepo.getByParentCode(normalizedCode);
      if (byParent != null) {
        team = byParent;
        requestedRole = TeamMemberRole.parent;
      }
    }
    if (team == null || requestedRole == null || !mounted) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Use the coach or parent code from the team.')),
        );
      }
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    final joinRepo = JoinRequestRepository(isar);

    final blockMessage =
        await _checkJoinGuards(joinRepo, team, userId, requestedRole);
    if (blockMessage != null) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blockMessage)));
      }
      return;
    }

    final request = JoinRequest.create(
      uuid: const Uuid().v4(),
      teamId: team.uuid,
      userId: userId,
      coachName: coachName,
      note: note,
      role: requestedRole,
      status: JoinRequestStatus.pending,
    );
    await joinRepo.add(request);
    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent. The owner will approve.')),
    );
    context.go('/teams');
  }

  static const _cooldownHours = 24;

  /// Returns a friendly block message if the user may not submit; null if allowed.
  Future<String?> _checkJoinGuards(
    JoinRequestRepository joinRepo,
    Team team,
    String userId,
    TeamMemberRole requestedRole,
  ) async {
    final hasPendingForRole =
        await joinRepo.hasPendingRequestForTeamAndRole(team.uuid, userId, requestedRole);
    final hasApproved = await joinRepo.hasApprovedRequest(team.uuid, userId);
    if (hasApproved) {
      return "You're already a member of this team.";
    }
    if (hasPendingForRole) {
      final roleLabel = requestedRole == TeamMemberRole.coach ? 'Coach' : 'Parent';
      return 'You already have a pending $roleLabel request for this team. Wait for the owner to respond.';
    }
    final rejected = await joinRepo.getLatestRejectedOrRevokedRequest(team.uuid, userId);
    if (rejected != null && rejected.role == requestedRole) {
      final cooldownPassed =
          DateTime.now().difference(rejected.requestedAt).inHours >= _cooldownHours;
      final rotatedAt = requestedRole == TeamMemberRole.coach
          ? team.coachCodeRotatedAt
          : team.parentCodeRotatedAt;
      final codeRotatedAfterReject =
          rotatedAt != null && rotatedAt.isAfter(rejected.requestedAt);
      if (!cooldownPassed && !codeRotatedAfterReject) {
        return 'You can request again after 24 hours, or ask the owner for a new team code.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.enableMembershipAuthV2) {
      // Phase 1: hide join-by-code flow in production builds until auth is rolled out.
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
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
          title: const Text('Join team'),
          centerTitle: true,
        ),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Join-by-code is not enabled in this build.\n\nFor the initial coach-only release, team access is managed directly by the owner.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentPath: '/teams'),
      );
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
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
        title: const Text('Join team'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Your display name (coach name)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _coachNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Coach Mike (2–40 characters)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
                maxLength: JoinRequestValidators.coachNameMaxLength,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              Text(
                'Team code',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _teamCodeController,
                decoration: const InputDecoration(
                  hintText: 'e.g. ABC123',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
              ),
              const SizedBox(height: 20),
              Text(
                'Note (optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Chris – Wednesday assistant coach',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
                maxLines: 2,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Request to join'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentPath: '/teams'),
    );
  }
}
