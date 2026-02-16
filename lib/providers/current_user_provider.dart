import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Authenticated user ID (internal; keys all ownership and approval).
/// Placeholder until auth is integrated; replace with real auth provider.
final currentUserIdProvider = Provider<String>((ref) => 'local');
