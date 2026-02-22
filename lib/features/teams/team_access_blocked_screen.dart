import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/isar/models/join_request.dart';
import '../../providers/join_request_provider.dart';

/// Resolves membership status and shows blocked message (rejected/revoked).
class TeamBlockedScreen extends ConsumerWidget {
  const TeamBlockedScreen({super.key, required this.teamUuid});

  final String teamUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(userTeamMembershipProvider(teamUuid));
    return membershipAsync.when(
      data: (m) {
        final status = m.membership?.status ?? JoinRequestStatus.rejected;
        final teamName = m.team?.name;
        return TeamAccessBlockedScreen(
          teamUuid: teamUuid,
          status: status,
          teamName: teamName,
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => TeamAccessBlockedScreen(
        teamUuid: teamUuid,
        status: JoinRequestStatus.rejected,
      ),
    );
  }
}

/// Shown when user has no access or request is pending/rejected/revoked.
class TeamAccessBlockedScreen extends StatelessWidget {
  const TeamAccessBlockedScreen({
    super.key,
    required this.teamUuid,
    required this.status,
    this.teamName,
  });

  final String teamUuid;
  final JoinRequestStatus status;
  final String? teamName;

  @override
  Widget build(BuildContext context) {
    final (title, message) = _messageFor(status);
    final displayName = teamName ?? 'This team';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teams'),
          color: AppColors.textPrimary,
        ),
        title: Text(displayName),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _iconFor(status),
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (String, String) _messageFor(JoinRequestStatus status) {
    switch (status) {
      case JoinRequestStatus.pending:
        return (
          'Request pending',
          'The team owner will approve your request. You can check back later.',
        );
      case JoinRequestStatus.rejected:
        return (
          'Request declined',
          'Your request to join was declined. You can request again with a new code from the owner.',
        );
      case JoinRequestStatus.revoked:
        return (
          'Access removed',
          'Your access to this team was removed. You can request to join again with a new code from the owner.',
        );
      case JoinRequestStatus.approved:
        return (
          'Access',
          'You have access to this team.',
        );
    }
  }

  static IconData _iconFor(JoinRequestStatus status) {
    switch (status) {
      case JoinRequestStatus.pending:
        return Icons.schedule;
      case JoinRequestStatus.rejected:
      case JoinRequestStatus.revoked:
        return Icons.block;
      case JoinRequestStatus.approved:
        return Icons.check_circle_outline;
    }
  }
}
