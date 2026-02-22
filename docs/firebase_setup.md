# Firebase setup for GameTracker

## 0. Prerequisites: Firebase CLI

The FlutterFire CLI requires the **official Firebase CLI** (`firebase` command) to be installed first.

- **Install:** <https://firebase.google.com/docs/cli#install_the_firebase_cli>
- **Via npm:** `npm install -g firebase-tools`
- **Verify:** `firebase --version` should print a version. Log in with `firebase login` if needed.

## 1. Create Firebase project (Console first)

**This app uses Firebase project:** `roster-flow-996b9`.

**Recommended:** Create the project in the [Firebase Console](https://console.firebase.google.com/) instead of via the CLI to avoid "Failed to add Firebase to Google Cloud Platform project" errors (often due to permissions or billing).

1. Go to [Firebase Console](https://console.firebase.google.com/) → **Add project** (or use existing `roster-flow-996b9`) → choose a project id if creating new.
2. In the project: **Project settings** → **Your apps** → add an **iOS** app (bundle id from Xcode) and/or **Android** app (application id from `android/app/build.gradle`). Download the config files if you want to place them manually.
3. Enable **Authentication** → **Sign-in method** → **Anonymous** (required; otherwise the app may show `firebase_auth/internal-error` on sign-in).

## 2. FlutterFire CLI (download config into app)

Install and run the configuration tool so FlutterFire can wire the app to your existing project (do not commit generated config files if they contain secrets; add them to `.gitignore` if needed):

```bash
# Install FlutterFire CLI (one-time)
dart pub global activate flutterfire_cli

# From project root: lists your Firebase projects and writes config into the app
dart pub global run flutterfire_cli:flutterfire configure
# Or add pub cache bin to PATH and run: flutterfire configure
```

This creates/updates:

- **iOS:** `ios/Runner/GoogleService-Info.plist`
- **Android:** `android/app/google-services.json`

Add these paths to `.gitignore` if you do not want to commit them (e.g. in a public repo). Do not commit API keys or other secrets to version control.

**Troubleshooting:** If you see "Failed to add Firebase to Google Cloud Platform project" when creating a project via the CLI, create the project in the Firebase Console (step 1) instead, then run `flutterfire configure` again and select that existing project.

## 3. Place config files

- **iOS:** Place `GoogleService-Info.plist` in `ios/Runner/` (Xcode will pick it up). Ensure the file is added to the Runner target.
- **Android:** Place `google-services.json` in `android/app/`. The root `android/build.gradle` and `android/app/build.gradle` should apply the Google services plugin as per Firebase docs.

If these files are missing, the app will not crash: it will show an orange developer banner in debug builds and continue with a fallback user id.

## 4. Auth behavior (app)

- The app uses **Anonymous Auth** by default: on first launch it calls `signInAnonymously()` if not already signed in.
- `currentUserIdProvider` exposes the Firebase UID (or `'local'` if not configured/signed in).
- An **ID token** is available via `idTokenProvider` for the Heroku API; the shared `AuthenticatedHttpClient` attaches `Authorization: Bearer <token>` to requests.
- Upgrade to email/social auth can be added later; no implementation in this step.

## 5. Backend / Heroku

Set the API base URL via environment or `--dart-define=API_BASE_URL=https://your-app.herokuapp.com/api` when building. The HTTP client in `lib/auth/api_client.dart` uses this and injects the Firebase ID token on each request.

---

## Checklist: what’s needed for Firebase to work

1. **GoogleService-Info.plist** in `ios/Runner/` and added to the Xcode **Runner** target (Copy Bundle Resources). Without this, `Firebase.initializeApp()` fails and the app shows the orange “Firebase not configured” banner.
2. **Anonymous Auth enabled** in [Firebase Console](https://console.firebase.google.com/) → project `roster-flow-996b9` → **Authentication** → **Sign-in method** → **Anonymous** = Enabled.
3. **Run the app** on a device or simulator. On first launch the app calls `signInAnonymously()`; if that succeeds, `currentUserIdProvider` returns the Firebase UID and the orange/red banners do not show.
4. **Android (when you add it):** Add `google-services.json` to `android/app/` and apply the Google services plugin in `android/app/build.gradle` (see Firebase Android setup docs).
