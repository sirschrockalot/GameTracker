import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'router/app_router.dart';

class UpwardLineupApp extends ConsumerWidget {
  const UpwardLineupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'RosterFlow',
      theme: appTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          color: const Color(0xFFF5F5F5),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
