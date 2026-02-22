import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_providers.dart';
import 'core/theme.dart';
import 'router/app_router.dart';

class UpwardLineupApp extends ConsumerStatefulWidget {
  const UpwardLineupApp({super.key});

  @override
  ConsumerState<UpwardLineupApp> createState() => _UpwardLineupAppState();
}

class _UpwardLineupAppState extends ConsumerState<UpwardLineupApp> {
  @override
  void initState() {
    super.initState();
    // Trigger device auth: ensureRegistered runs on first read of authStateProvider.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(authStateProvider));
  }

  @override
  Widget build(BuildContext context) {
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
