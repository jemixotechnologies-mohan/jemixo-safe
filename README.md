# Jemixo Safe

On-device scam protection, privacy check and cleanup companion for Android.
*Know Your Phone. Protect Your Privacy.*

Everything runs locally: no account, no server, no analytics, no paid APIs.
Scores are risk **indicators** derived from what Android exposes (permissions,
install source, signing info, brand names); the app never claims to detect
malware.

## What it does

| Area | Features |
| --- | --- |
| Scam checks | Message scanner (English + Hindi/Hinglish phrases), **screenshot check (on-device OCR, ML Kit, English + Devanagari)**, sender-ID check (TRAI DLT headers vs personal numbers), **caller-number check (140 / 1600 / foreign / personal)**, link checker with **verified official-domain badge** and **short-link reveal**, QR / UPI payment decoder ("you would PAY ₹X to …"), shareable result cards |
| App safety | Installed-app risk indicators, **fake bank / payment app detector**, **loan apps not on the regulated-lender list**, **apps with special access** (accessibility, notification access, device admin) and **hidden apps with spying-type permissions**, **"what changed" diff between checks** (new apps, permissions added by updates), APK inspector, optional "new app installed" alerts |
| Entry points | Share sheet (text or APK), **"Check with Jemixo Safe" in any app's text-selection toolbar**, Quick Settings tile (check clipboard), home-screen status widget |
| Help | **Scam-call panic card** (hang up, don't pay, tell someone, verify), "I think I got scammed" flow: dial 1930, bank / UPI helplines, first-hour checklist; weekly Scam Radar |
| Family | Simple mode: large text, big buttons, **Hindi** for simple mode and emergency screens |
| Clean | Storage overview, large files, duplicates, similar photos, screenshots, downloads (media permission only) |
| Device | Battery, memory, network state, security switches, hardware tests, PDF report, scan history |

## Data updates without a backend

`assets/data/threat_data.json` bundles scam phrases (10 categories, English +
Hindi), brand rules, official bank/UPI/government packages, regulated loan
apps, **official website domains**, UPI handles, suspicious calling-country
codes, helplines and radar items. Once a week the app fetches the
same file from `AppConstants.threatDataUrl` (a static file you host, e.g. on
GitHub Pages) and keeps it if `version` is higher. Publish a new JSON to
cover a new fake app without shipping an app update. The request carries no
device data.

## Play Console notes

- **No `MANAGE_EXTERNAL_STORAGE`.** All storage features use MediaStore with the
  media permissions (`READ_MEDIA_*` on 13+, `READ_EXTERNAL_STORAGE` on 12 and
  below).
- **`QUERY_ALL_PACKAGES`** needs the "device security" declaration. If it is
  refused, delete that one line from the manifest: the scanner already merges
  the launcher query, so every app with an icon is still reviewed and the UI
  says so.
- **No SMS, call-log, accessibility or notification-listener permissions.**
  Messages reach the app through the share sheet, text selection or clipboard.
- **`POST_NOTIFICATIONS`** is requested only when the user turns on "New app
  alerts" (WorkManager, every 30 minutes).
- Wording avoids "antivirus" / "malware"; results are "risk indicators".
- Privacy policy: `docs/privacy-policy.html` (publish it and set
  `AppConstants.privacyPolicyUrl`). Data Safety form: no data collected.

## Project layout

```
lib/
  app/                 root widget, providers, tab shell, hand-off routing
  core/                theme, constants, permission catalogue, formatters, haptics
  data/                drift database + repositories
  services/
    platform/          NativeBridge (MethodChannel) + typed models
    threat_data/       bundled + self-hosted JSON data set
    risk_engine/       risk & privacy engines, app identity (fake/loan), text,
                       UPI and sender-ID analyzers
    app_scanner/       installed-app inventory
    storage_analyzer/  MediaStore lists, delete flow, similar-photo finder
    device_service/    battery, network, sensors, security switches
    apk_analyzer/      APK inspection
  state/               controllers (safety scan, settings, history, tools)
  features/            one folder per screen (emergency, simple, privacy, ...)
  widgets/             shared UI incl. the shareable result card
android/app/src/main/kotlin/com/jemixo/jemixo_safe/
  MainActivity.kt        channel dispatch, background executor, hand-off intents
  AppScannerModule.kt    PackageManager inventory (+ launcher fallback)
  StorageModule.kt       MediaStore queries, thumbnails, deletion
  MediaDeleteHelper.kt   scoped-storage delete confirmation
  DeviceModule.kt        battery / network / sensors / security switches
  ApkAnalyzerModule.kt   getPackageArchiveInfo + zip inspection
  FileActionModule.kt    open / share / reveal through FileProvider
  InstallWatchWorker.kt  periodic new-app check + notification
  ClipboardTileService.kt, SafetyWidgetProvider.kt
docs/privacy-policy.html
```

## Building

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after editing app_database.dart
flutter analyze
flutter test
flutter build appbundle --release      # Play upload
flutter build apk --release            # sideload / testing
```

Release signing: create `android/key.properties` (`storeFile`, `storePassword`,
`keyAlias`, `keyPassword`). Without it the release build is signed with the
debug key. Minification and resource shrinking are on.

## Device test checklist

1. Fresh install → Home check completes without freezing the UI.
2. Select text in WhatsApp → "Check with Jemixo Safe" opens the scanner.
3. Share an APK from a file manager → analyzer opens with the result.
4. Scan a UPI QR → "You would PAY ₹…" screen, correct payee and handle.
5. Install a test APK with SMS permission while alerts are on → notification
   within 30 minutes, tap opens the app details.
6. Clean → Screenshots: permission prompt, thumbnails, delete removes the row
   (system confirmation appears on Android 11+).
7. Settings → Simple mode → four big buttons; "Full app" returns.
8. Add the home widget, run a check, widget text updates.
9. Share a WhatsApp screenshot to Jemixo Safe → text is read and scanned.
10. Enable TalkBack, run a check → it appears under "Apps with special access"
    as a system app; a third-party accessibility app appears as "Review".
11. Run two checks after installing an app → "What changed" lists it.
