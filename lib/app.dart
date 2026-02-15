import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'router/app_router.dart';

class UpwardLineupApp extends ConsumerWidget {
  const UpwardLineupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Upward Lineup',
      theme: appTheme,
      routerConfig: goRouter,
    );
  }
}
