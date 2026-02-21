# Deploy RosterFlow to the Apple App Store

Follow these steps in order. You need an **Apple Developer Program** account ($99/year).

---

## 1. Before you start

- [ ] **Bundle ID**: Replace the placeholder in Xcode. Open `ios/Runner.xcodeproj` in Xcode (or the `.xcworkspace`), select the **Runner** target → **Signing & Capabilities**. The project is currently set to `com.example.lineupcoach` — change it to your real bundle ID (e.g. `com.yourcompany.lineupcoach`). It must match the App ID you create in App Store Connect.
- [ ] **App icon**: Ensure `assets/icon_1024.png` exists (1024×1024 PNG, no transparency) and run `flutter pub run flutter_launcher_icons` (see [docs/ios_release_checklist.md](ios_release_checklist.md)).
- [ ] **Version**: In `pubspec.yaml`, set `version: 1.0.0+1` (or higher). The part after `+` is the build number; increment it for each upload.

---

## 2. App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com) and sign in with your developer account.
2. **Apps** → **+** → **New App**.
   - **Platform**: iOS  
   - **Name**: e.g. **RosterFlow** (user-facing name).  
   - **Primary Language**: your choice.  
   - **Bundle ID**: Choose the App ID that matches your app (e.g. `com.yourcompany.lineupcoach`). If it’s not listed, create it first in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) → **Identifiers** → **+** → **App IDs** → **App** → enter the same bundle ID and description.
   - **SKU**: any unique string (e.g. `lineupcoach-ios`).
3. In the new app’s page, fill in what you can now (you can change most of it later):
   - **App Information**: Category (e.g. Sports), Subtitle (optional).
   - **Pricing and Availability**: Free or Paid, countries.
   - **App Privacy**: Privacy Policy URL (required), and answer the data collection questions.

---

## 3. Xcode: signing and team

1. Open the **iOS** project in Xcode (use the workspace so CocoaPods is included):
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In the left sidebar, select the **Runner** project (blue icon), then the **Runner** target.
3. Open **Signing & Capabilities**.
   - Check **Automatically manage signing**.
   - **Team**: Select your Apple Developer team.
   - Confirm the **Bundle Identifier** matches the one you use in App Store Connect (e.g. `com.yourcompany.lineupcoach`).
4. Pick the **Runner** scheme and set the run destination to **Any iOS Device (arm64)** (not a simulator).

---

## 4. Build an archive (release build)

1. In Xcode menu: **Product** → **Archive**.
2. Wait for the archive to finish. If it fails:
   - Fix any signing errors (Team, provisioning).
   - Ensure you’re not building for a simulator (destination must be a device or “Any iOS Device”).
   - From the project folder you can also run:  
     `flutter build ipa`  
     then open the generated `.ipa` or the Xcode Organizer and use **Distribute App** as below.

3. When the archive is done, the **Organizer** window opens (or open it via **Window** → **Organizer** → **Archives**).
4. Select the new archive → **Distribute App**.
5. Choose **App Store Connect** → **Upload** → Next.
6. Leave options as default (e.g. upload symbols, manage version/build) → Next.
7. Select your **Distribution certificate** and **Provisioning profile** (Xcode usually picks the right one if signing is automatic) → Next.
8. Review and click **Upload**. Wait until the upload completes.

---

## 5. App Store Connect: version and build

1. In App Store Connect, open your app → **App Store** tab (left).
2. Under **iOS App**, click **+ Version or Platform** → **iOS** if this is the first version, or add a new version (e.g. 1.0.0).
3. **Version Information**:
   - **What’s New in This Version**: e.g. “Initial release of RosterFlow.”
   - **Promotional Text** (optional).
   - **Description**: Full app description.
   - **Keywords**: Comma-separated, no spaces after commas.
   - **Support URL**: Your support or website URL.
   - **Marketing URL** (optional).
4. **Build**: Click **+** next to **Build**. After processing (often 5–15 minutes), your uploaded build appears. Select it and click **Done**.
5. **App Review Information**:
   - **Sign-in required**: If the app doesn’t need a login, say “No” and add a demo account only if you have one.
   - **Contact info**: Phone and email for Apple to reach you.
   - **Notes**: Any instructions for the reviewer (e.g. “No login required; all data is local.”).

---

## 6. Submit for review

1. Set **Age Rating** (questionnaire).
2. Complete **App Privacy** if not already done (data types and usage).
3. Click **Add for Review** (or **Submit for Review**). Confirm the build and version, then submit.
4. Apple will email you when the status changes. Typical review time is 24–48 hours.

---

## 7. After approval

- The app goes **Ready for Sale** in the countries you selected. You can release manually or set to auto-release.
- For future updates: bump version/build in `pubspec.yaml`, create a new archive, upload, then add a new version in App Store Connect and submit again.

---

## Quick reference

| Step              | Where / What |
|------------------|--------------|
| Bundle ID        | Xcode → Runner target → Signing & Capabilities; must match App Store Connect App ID. |
| Create App ID     | [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) → Identifiers → + → App IDs. |
| Create App       | App Store Connect → Apps → + → New App. |
| Archive          | Xcode: Product → Archive (destination: Any iOS Device). |
| Upload            | Organizer → Distribute App → App Store Connect → Upload. |
| Select build     | App Store Connect → app → Version → Build → +. |
| Submit            | Complete metadata, Age Rating, Privacy → Add for Review → Submit. |
