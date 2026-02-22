import 'auth_api.dart' as auth_api;
import 'device_identity.dart' as device_identity;

/// Central auth session: token, userId, installId in secure storage; register/re-register.
abstract final class AuthSession {
  static Future<String?> getToken() => auth_api.getStoredToken();
  static Future<String?> getUserId() => auth_api.getStoredUserId();
  static Future<String> getInstallId() => device_identity.getInstallId();

  /// If no token, call /auth/register. On network failure returns null (local-only).
  static Future<({String userId, String? token, String? displayName})?> registerIfNeeded(String baseUrl) =>
      auth_api.ensureRegistered(baseUrl);

  /// Silent re-register and refresh stored token. Use after 401 to retry.
  static Future<void> forceReRegister(String baseUrl) => auth_api.forceReRegister(baseUrl);
}
