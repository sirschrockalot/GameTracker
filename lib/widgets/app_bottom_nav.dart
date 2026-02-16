import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/feature_flags.dart';
import '../providers/join_request_provider.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, required this.currentPath});

  final String currentPath;

  static const _allItems = [
    (icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'Teams'),
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Game'),
    (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Schedule'),
    (icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Awards'),
    (icon: Icons.history, activeIcon: Icons.history, label: 'History'),
  ];
  static const _allPaths = ['/teams', '/game', '/schedule', '/awards', '/history'];

  int _selectedIndex(List<String> paths) {
    if (currentPath.startsWith('/teams') || currentPath.startsWith('/parent')) {
      final i = paths.indexOf('/teams');
      if (i >= 0) return i;
    }
    if (currentPath.startsWith('/game')) {
      final i = paths.indexOf('/game');
      if (i >= 0) return i;
    }
    if (currentPath.startsWith('/schedule')) {
      final i = paths.indexOf('/schedule');
      if (i >= 0) return i;
    }
    if (currentPath.startsWith('/awards')) {
      final i = paths.indexOf('/awards');
      if (i >= 0) return i;
    }
    if (currentPath.startsWith('/history')) {
      final i = paths.indexOf('/history');
      if (i >= 0) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccessCoachAsync = ref.watch(canAccessCoachNavProvider);
    // If membership/auth is disabled, always show full coach nav.
    final showCoachTabs = !FeatureFlags.enableMembershipAuthV2
        ? true
        : (canAccessCoachAsync.valueOrNull ?? true);

    final items = showCoachTabs ? _allItems : [_allItems[0]];
    final paths = showCoachTabs ? _allPaths : [_allPaths[0]];
    final count = items.length;
    final selected = _selectedIndex(paths);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(count, (i) {
              final isSelected = selected == i;
              final item = items[i];
              return InkWell(
                onTap: () => context.go(paths[i]),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 26,
                          color: isSelected
                              ? AppColors.primaryOrange
                              : AppColors.navInactive,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryOrange
                                : AppColors.navInactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
