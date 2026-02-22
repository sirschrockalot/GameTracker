import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'auth/auth_session.dart';
import 'config/backend_config.dart';

/// Set to true to test if the Flutter engine paints at all on device (no router/Isar).
const bool _kMinimalLaunch = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Non-blocking: ensure we have a token at launch; on failure allow local-only.
  AuthSession.registerIfNeeded(backendBaseUrl).catchError((_) {});

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrint('FlutterError: ${details.exception}');
      debugPrint(details.stack?.toString() ?? '');
    }
  };

  runZonedGuarded(() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                'Something went wrong.\n\n${details.exception}',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    };
    if (_kMinimalLaunch) {
      runApp(const _MinimalTestApp());
    } else {
      runApp(
        const ProviderScope(
          child: UpwardLineupApp(),
        ),
      );
    }
  }, (error, stack) {
    debugPrint('Uncaught: $error');
    debugPrint(stack?.toString() ?? '');
  });
}

/// Minimal app to verify Flutter paints on device. No router, no Riverpod, no Isar.
class _MinimalTestApp extends StatelessWidget {
  const _MinimalTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hello',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'If you see this, Flutter is working.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
