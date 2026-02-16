import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/sync/sync_provider.dart';
import '../providers/sync_provider.dart';

/// Small sync status indicator (offline / syncing / up to date).
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusStreamProvider);
    return statusAsync.when(
      data: (status) => _Indicator(status: status),
      loading: () => const _Indicator(status: SyncStatus.offline),
      error: (_, __) => const _Indicator(status: SyncStatus.offline),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (status) {
      SyncStatus.offline => (Icons.cloud_off_outlined, 'Offline'),
      SyncStatus.syncing => (Icons.sync, 'Syncing…'),
      SyncStatus.upToDate => (Icons.cloud_done_outlined, 'Up to date'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status == SyncStatus.offline
            ? AppColors.chipInactive
            : status == SyncStatus.syncing
                ? AppColors.skillDev.withValues(alpha: 0.2)
                : AppColors.onCourtGreen.withValues(alpha: 0.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
