import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/team_logo_avatar.dart';

const String _kAppName = 'Upward Lineup';

/// Generates the share sheet message for coach or parent invite.
String shareInviteMessage({
  required String role,
  required String code,
  String appName = _kAppName,
}) {
  final isCoach = role == 'coach';
  final label = isCoach ? 'Coach code' : 'Parent code';
  const steps = '1. Open Upward Lineup\n2. Go to Teams → Join team\n3. Enter your name and paste the code\n4. Owner will approve.';
  return '$label: $code\n\n$steps';
}

/// Deep link payload for QR: rosterflow://join?code=<CODE>&role=coach|parent
String joinDeepLink(String code, String role) =>
    'rosterflow://join?code=${Uri.encodeComponent(code)}&role=$role';

class ShareTeamScreen extends ConsumerWidget {
  const ShareTeamScreen({super.key, required this.teamUuid});

  final String teamUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final teams = teamsAsync.valueOrNull ?? [];
    final team = teams.where((t) => t.uuid == teamUuid).firstOrNull;

    if (team == null) {
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
          title: const Text('Share Team'),
          centerTitle: true,
        ),
        body: const Center(child: Text('Team not found')),
      );
    }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamLogoAvatar(team: team, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Share Team',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _InviteSection(
              title: 'Coach Invite',
              subtitle: 'Coaches can manage lineup, roster, games.',
              code: team.coachCode.isEmpty ? '—' : team.coachCode,
              role: 'coach',
              deepLink: joinDeepLink(team.coachCode, 'coach'),
            ),
            const SizedBox(height: 28),
            const Divider(height: 1, color: AppColors.chipInactive),
            const SizedBox(height: 28),
            _InviteSection(
              title: 'Parent Invite',
              subtitle: 'Parents can view schedule only.',
              code: team.parentCode.isEmpty ? '—' : team.parentCode,
              role: 'parent',
              deepLink: joinDeepLink(team.parentCode, 'parent'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteSection extends StatelessWidget {
  const _InviteSection({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.role,
    required this.deepLink,
  });

  final String title;
  final String subtitle;
  final String code;
  final String role;
  final String deepLink;

  @override
  Widget build(BuildContext context) {
    final canCopyShare = code.isNotEmpty && code != '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.chipInactive, width: 1),
          ),
          child: Center(
            child: SelectableText(
              code,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (canCopyShare) ...[
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: const Text('Copy'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Share.share(
                    shareInviteMessage(role: role, code: code),
                    subject: '$title – $_kAppName',
                  );
                },
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryOrange,
                  side: const BorderSide(color: AppColors.primaryOrange),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
        if (canCopyShare) ...[
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.chipInactive),
              ),
              child: QrImageView(
                data: deepLink,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textPrimary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
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
