import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentPath});

  final String currentPath;

  int get _selectedIndex {
    if (currentPath.startsWith('/teams')) return 0;
    if (currentPath == '/game') return 1;
    if (currentPath == '/awards') return 2;
    if (currentPath == '/history') return 3;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'Teams'),
      (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Game'),
      (icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Awards'),
      (icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'History'),
    ];
    const paths = ['/teams', '/game', '/awards', '/history'];

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
            children: List.generate(4, (i) {
              final selected = _selectedIndex == i;
              final item = items[i];
              return InkWell(
                onTap: () => context.go(paths[i]),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 26,
                        color: selected
                            ? AppColors.primaryOrange
                            : AppColors.navInactive,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryOrange
                              : AppColors.navInactive,
                        ),
                      ),
                    ],
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
