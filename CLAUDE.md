# CLAUDE.md

ColdChat — a Flutter Twitch chat client, forked from [chatsen/chatsen](https://github.com/chatsen/chatsen).
Ships as `com.plasmari.coldchat` (Apple team `RA25PYVUTF`), which is **not** the same app as upstream.

This file documents the build, install and release procedures. Everything below has been run and verified
on macOS with Xcode 26.5 / Flutter (stable).

## Localization

`lib/l10n/app_localizations*.dart` is **generated but checked in**. After editing any `lib/l10n/*.arb`:

```bash
flutter gen-l10n
```

Add new strings to `app_en.arb` (the template, see `l10n.yaml`) and ideally `app_de.arb`. The other ~23
locales fall back to English with an "N untranslated message(s)" warning — that warning is pre-existing
and not a failure. Translations are managed via Crowdin (`crowdin.yml`).

## Analyze baseline

`flutter analyze` is **not** clean on this repo — expect ~145 findings. Almost all are pre-existing:
`deprecated_member_use` (`onBackground`, `withOpacity`, `surfaceVariant`), unused `cookie_data.dart`
imports, `invalid_use_of_protected_member` for `bloc.emit()` calls, and errors in `test/widget_test.dart`
(stale scaffold test, references a non-existent `MyApp`).

What matters is that **your** changes add no new `error`. Check with:

```bash
flutter analyze 2>&1 | grep -E "^\s*error" | grep -v test/widget_test
```

Gotcha: `ConnectionState` collides with Flutter's own `ConnectionState` from `package:flutter/material.dart`.
In any widget file, import the TMI one with a prefix:

```dart
import '../tmi/connection/connection_state.dart' as tmi;
```

## iOS — install on a connected iPhone without wiping app data

**Never use `flutter install` for this.** It calls `installApp(uninstall: true)`, which uninstalls the
existing app first and takes all Hive boxes with it (accounts, channels, settings, emote cache, seen
mentions). Use `devicectl`, which does an in-place upgrade and preserves the data container.

```bash
# 1. Find the device. Wireless discovery of unreachable paired devices can time out and
#    hide the attached one, so restrict to attached and allow a longer timeout.
flutter devices --device-connection attached --device-timeout 30

# 2. Build, codesigned (automatic signing, team RA25PYVUTF from the Xcode project).
flutter build ios --release

# 3. Install in place. Data is preserved because the bundle ID and signing team are unchanged.
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app

# 4. Verify which build actually landed.
xcrun devicectl device info apps --device <UDID> | grep -i coldchat
```

Bump the build number in `pubspec.yaml` first if you want to tell the new install apart from the old one —
otherwise step 4 shows the same version and proves nothing.

Data survives an in-place upgrade only while the bundle ID and signing identity stay the same. Changing
either makes iOS refuse the install outright (it fails, it does not silently wipe), and the only way
forward is delete + install, which loses the data.

## iOS — TestFlight release

Prerequisites, one time: an app-specific password from
appleid.apple.com → Sign-In and Security → App-Specific Passwords (the regular Apple ID password does not
work), stored in the keychain. Note the `--item` flag — `altool`'s own `--help` omits it and the documented
form fails with `Expected item argument is missing, --item`:

```bash
xcrun altool --store-password-in-keychain-item --item COLDCHAT_ASC \
  -u <apple-id> -p <app-specific-password>
```

Never paste that password into a chat, a script, or a commit. To recover which Apple ID the item belongs to:

```bash
security find-generic-password -l COLDCHAT_ASC | grep '"acct"'
```

Then, per release:

```bash
# 1. Bump the build number — a build number can never be reused for a version once
#    App Store Connect has accepted it.
#    pubspec.yaml:  version: 2.0.0+<N>

# 2. Archive + export an App Store IPA. ios/ExportOptions.plist is ours
#    (method: app-store-connect, teamID: RA25PYVUTF).
flutter build ipa --export-options-plist=ios/ExportOptions.plist
# -> build/ios/ipa/ColdChat.ipa, build/ios/archive/Runner.xcarchive

# 3. Validate FIRST. Catches a missing app record, bad entitlements or a duplicate
#    build number without consuming the build number.
xcrun altool --validate-app --type ios -f build/ios/ipa/ColdChat.ipa \
  -u <apple-id> -p "@env:ASC_PW"

# 4. Upload.
xcrun altool --upload-app --type ios -f build/ios/ipa/ColdChat.ipa \
  -u <apple-id> -p "@env:ASC_PW"
```

For steps 3 and 4, supply the password from the keychain per-command so it never lands in your shell
history, in `ps` output, or in a transcript:

```bash
ASC_PW="$(security find-generic-password -l COLDCHAT_ASC -w)" xcrun altool --upload-app ... -p "@env:ASC_PW"
```

`-p "@keychain:COLDCHAT_ASC"` looks like the obvious alternative but **does not work** with Xcode 26.5's
`altool`: it stores the item under `--item <name>` and then fails to find it, with
`AuthenticationFailure("Failed to find item COLDCHAT_ASC ...")`. The `@env:` route above is the workaround.

Expect one non-blocking warning: `MinimumOSVersion too low ... 13.0` (90068). From Spring 2027 App Store
Connect requires 15.0+, so the deployment target needs raising before then. Processing on Apple's side
takes a few minutes after `UPLOAD SUCCEEDED` before the build appears in TestFlight.

Uploading is irreversible — a build can be expired in TestFlight but its number is spent.

## Android — APK

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk  (~61 MB universal APK)
```

**This APK is signed with the debug keystore.** `android/app/build.gradle.kts` has
`release { signingConfig = signingConfigs.getByName("debug") }`. It sideloads and runs fine, but it cannot
go to Play, and its signature will not match a properly signed build later — switching keys requires an
uninstall, which wipes app data. Wiring up a real release keystore is still an open task.

`flutter build appbundle` would produce a Play-ready `.aab`, but only once the signing config is fixed.

## Repo gotchas

- **`ios/fastlane/` belongs to upstream, not to this fork.** `Appfile` names `com.chatsen.chatsen`,
  upstream's Apple ID, team `6GNA923MZR`, and a `match` repo at `github.com/chatsen/fastlane`. Running
  `fastlane beta` would target upstream's App Store Connect app. Use the `flutter build ipa` + `altool`
  flow above instead. `ios/ExportOptions.plist` *is* ours.
- Remotes: `origin` is upstream `chatsen/chatsen`, `fork` is `c0ldplasma/chatsen`. Push to **`fork`**.
  `fork` is public — keep Apple IDs, device UDIDs, passwords and API keys out of committed files.
- `build/` is currently untracked but present in the working tree; don't commit it.
- Twitch login uses the OAuth **implicit grant** (`response_type=token` in `lib/modal/oauth_webview.dart`),
  so there is no refresh token and an expired login can only be fixed by signing in again. See
  `lib/widgets/login_expired_banner.dart` and `Client.validateCredentials`.
