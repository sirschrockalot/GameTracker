import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'device_identity.dart';

const _keyToken = 'jwt_token';
const _keyUserId = 'auth_user_id';
const _keyDisplayName = 'auth_display_name';

final _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// POST /auth/register with [installId], [displayName]. Stores returned token, userId, displayName.
Future<({String userId, String token, String displayName})> register(
  String baseUrl,
  String installId,
  String displayName,
) async {
  final uri = Uri.parse('$baseUrl/auth/register');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'installId': installId, 'displayName': displayName}),
  );
  if (res.statusCode != 200) {
    throw Exception('Register failed: ${res.statusCode}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final token = data['token'] as String?;
  final userId = data['userId'] as String?;
  final name = data['displayName'] as String?;
  if (token == null || userId == null || name == null) {
    throw Exception('Invalid register response');
  }
  await _storage.write(key: _keyToken, value: token);
  await _storage.write(key: _keyUserId, value: userId);
  await _storage.write(key: _keyDisplayName, value: name);
  return (userId: userId, token: token, displayName: name);
}

Future<String?> getStoredToken() => _storage.read(key: _keyToken);
Future<String?> getStoredUserId() => _storage.read(key: _keyUserId);
Future<String?> getStoredDisplayName() => _storage.read(key: _keyDisplayName);

/// If no stored token, registers with "Coach" + last 4 of installId. On network failure
/// returns null (caller should use installId as temp userId).
Future<({String userId, String? token, String? displayName})?> ensureRegistered(String baseUrl) async {
  final token = await getStoredToken();
  if (token != null && token.isNotEmpty) {
    final userId = await getStoredUserId();
    final displayName = await getStoredDisplayName();
    if (userId != null) return (userId: userId, token: token, displayName: displayName);
  }
  final installId = await getInstallId();
  final defaultName = 'Coach${installId.length >= 4 ? installId.substring(installId.length - 4) : installId}';
  try {
    final r = await register(baseUrl, installId, defaultName);
    return (userId: r.userId, token: r.token, displayName: r.displayName);
  } catch (_) {
    return null;
  }
}
