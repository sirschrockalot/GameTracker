import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/backend_config.dart';
import 'api_client.dart';
import 'auth_api.dart';
import 'auth_session.dart';
import 'device_identity.dart';

/// Backend base URL (no trailing slash). From [backend_config].
final apiBaseUrlProvider = Provider<String>((ref) => backendBaseUrl);

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
    final state = await AuthSession.registerIfNeeded(baseUrl);
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
  return AuthSession.getToken();
});

/// Shared authenticated client. Bearer JWT, 401 → re-register and retry once.
final authenticatedHttpClientProvider = Provider<AuthenticatedHttpClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return AuthenticatedHttpClient(
    baseUrl: baseUrl,
    getToken: AuthSession.getToken,
    forceReRegister: AuthSession.forceReRegister,
  );
});
