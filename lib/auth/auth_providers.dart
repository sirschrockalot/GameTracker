import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_api.dart';
import 'device_identity.dart';
import 'api_client.dart';

class AuthState {
  const AuthState({required this.userId, this.token, this.displayName});
  final String userId;
  final String? token;
  final String? displayName;
}

final installIdProvider = FutureProvider<String>((ref) => getInstallId());

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async {
    final baseUrl = ref.read(apiBaseUrlProvider);
    final state = await ensureRegistered(baseUrl);
    if (state != null) {
      return AuthState(userId: state.userId, token: state.token, displayName: state.displayName);
    }
    final installId = await getInstallId();
    return AuthState(userId: installId, token: null, displayName: null);
  }

  /// Re-register with new displayName and refresh stored token.
  Future<void> updateDisplayName(String displayName) async {
    final baseUrl = ref.read(apiBaseUrlProvider);
    final installId = await getInstallId();
    await register(baseUrl, installId, displayName);
    ref.invalidateSelf();
  }
}

/// Current user ID from auth state; offline/backend unreachable uses installId as fallback.
final currentUserIdProvider = Provider<String>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  final installId = ref.watch(installIdProvider).valueOrNull;
  return auth?.userId ?? installId ?? 'local';
});

/// JWT for backend requests. Null when not registered (offline fallback).
final authTokenProvider = Provider<Future<String?>>((ref) async {
  final auth = ref.read(authStateProvider).valueOrNull;
  if (auth?.token != null) return auth!.token;
  return getStoredToken();
});

/// Shared authenticated client. Attaches Bearer JWT to requests.
final authenticatedHttpClientProvider = Provider<AuthenticatedHttpClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return AuthenticatedHttpClient(
    baseUrl: baseUrl,
    getToken: () => ref.read(authTokenProvider),
  );
});
