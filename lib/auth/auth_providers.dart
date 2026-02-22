import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_init.dart';

/// Whether Firebase was initialized successfully (config files present).
final firebaseConfiguredProvider = Provider<bool>((ref) => firebaseConfigured);

/// Auth state stream. Empty stream when Firebase not configured to avoid errors.
final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseConfiguredProvider)) {
    return const Stream.empty();
  }
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user ID for ownership/approval. Falls back to 'local' when not signed in (minimal refactor).
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.uid ?? 'local';
});

/// Last sign-in error; clear on retry. Used to show retry banner.
final authErrorProvider = StateProvider<Object?>((ref) => null);

/// Call to sign in anonymously. Sets [authErrorProvider] on failure.
final signInAnonymouslyProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    if (!ref.read(firebaseConfiguredProvider)) return;
    ref.read(authErrorProvider.notifier).state = null;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e;
    }
  };
});

/// Firebase ID token for Heroku API. Returns null if not signed in.
final idTokenProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return user.getIdToken();
});
