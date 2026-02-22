import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAuth(ref));
  }

  void _ensureAuth(WidgetRef r) {
    final configured = r.read(firebaseConfiguredProvider);
    final user = r.read(authStateProvider).valueOrNull;
    if (configured && user == null) {
      unawaited(r.read(signInAnonymouslyProvider)());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      next.whenData((user) {
        if (user == null && ref.read(firebaseConfiguredProvider)) {
          unawaited(ref.read(signInAnonymouslyProvider)());
        }
      });
    });

    final authError = ref.watch(authErrorProvider);
    final configured = ref.watch(firebaseConfiguredProvider);

    return MaterialApp.router(
      title: 'RosterFlow',
      theme: appTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Column(
          children: [
            if (!configured && kDebugMode)
              Material(
                color: Colors.orange.shade700,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Firebase not configured. Add GoogleService-Info.plist (iOS) / google-services.json (Android).',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            if (authError != null)
              Material(
                color: Colors.red.shade700,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            authError is FirebaseAuthException &&
                                    (authError as FirebaseAuthException).code == 'internal-error'
                                ? 'Enable Anonymous sign-in in Firebase Console (Authentication → Sign-in method).'
                                : 'Sign-in failed. Check network.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(authErrorProvider.notifier).state = null;
                            ref.read(signInAnonymouslyProvider)();
                          },
                          child: Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F5),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
