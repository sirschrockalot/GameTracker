import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _keyInstallId = 'install_id';

final _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Returns a stable install ID (UUID). On first launch generates and stores it
/// so reinstall can restore from secure storage where supported.
Future<String> getInstallId() async {
  final existing = await _storage.read(key: _keyInstallId);
  if (existing != null && existing.isNotEmpty) return existing;
  final id = const Uuid().v4();
  await _storage.write(key: _keyInstallId, value: id);
  return id;
}
