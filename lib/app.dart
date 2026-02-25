import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_providers.dart';
import 'core/theme.dart';
import 'router/app_router.dart';
import 'providers/notifications_provider.dart';
import 'providers/teams_provider.dart';

class UpwardLineupApp extends ConsumerStatefulWidget {
  const UpwardLineupApp({super.key});

  @override
  ConsumerState<UpwardLineupApp> createState() => _UpwardLineupAppState();
}

class _UpwardLineupAppState extends ConsumerState<UpwardLineupApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger device auth: ensureRegistered runs on first read of authStateProvider.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(authStateProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App foreground: refresh teams and pending notifications from backend.
      ref.invalidate(refreshTeamsFromServerProvider);
      ref.invalidate(pendingNotificationsSummaryProvider);
    }
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
