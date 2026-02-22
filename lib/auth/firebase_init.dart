import 'package:firebase_core/firebase_core.dart';

/// Set by [initializeFirebase]. True if Firebase.initializeApp() succeeded.
/// Requires platform config: iOS: GoogleService-Info.plist in ios/Runner/;
/// Android: google-services.json in android/app/. See docs/firebase_setup.md.
/// Used to fail gracefully when config files are missing (no crash loops).
bool firebaseConfigured = false;

/// Call from main() before runApp.
/// On failure (e.g. missing GoogleService-Info.plist / google-services.json),
/// [firebaseConfigured] stays false; app can show a dev banner and avoid crash.
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    firebaseConfigured = true;
  } catch (_) {
    firebaseConfigured = false;
  }
}
