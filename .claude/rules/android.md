---
paths:
  - "android/**"
  - "docs/android-*.html"
  - "scripts/android-export/**"
  - "scripts/sync-android-content.sh"
  - "scripts/play_screenshot_compositor.py"
  - "scripts/play-products.py"
  - "scripts/play-upload.sh"
  - "scripts/make_android_icon.py"
---

# Bridge Trainer Android rules

## Identity and products

- Native Android code is in `android/`, a screen-for-screen port of the iOS app
  (same copy, tokens, flows, product IDs). When iOS changes, port the change.
  It started from `~/cribbage/android` (itself from `~/mahj/android`); every
  cribbage screen, string and asset was replaced.
- Package `com.jackwallner.bridge`, launcher label "Bridge Trainer", Play title
  "Bridge Trainer: Learn & Bid", paid tier "Bridge+". Feedback and Play
  contact email `jackwallner+b@gmail.com` (same as the iOS feedback sheet).
  Never imply ACBL or any league affiliation.
- Products (same IDs as iOS): subscriptions `com.jackwallner.bridge.monthly`
  and `com.jackwallner.bridge.yearly` (base plans `monthly` / `yearly`, 7-day
  `trial-7d` new-customer offer), lifetime one-time product
  `com.jackwallner.bridge.lifetime` (purchase option `lifetime`). Android US
  ladder $6.99 / $29.99 / $69.99, about 20% under iOS ($8.99 / $34.99 /
  $79.99); local prices are Play's conversion plus the fleet PPP curve. Never
  put prices in listing copy or app literals (`TrialCopyTest` pins the
  fallback strings).
- RevenueCat project `proj71e29dd0`: Test Store app `app8ab6f6fb84` (Debug key
  `apikey6953d9a9d4`), Play app `app9f03f1fe32` (`goog_` key
  `apikeyb7881f6931`, release only), App Store app `appde08658136`.
  Entitlement `Bridge+` (`entl524bd39bf2`) holds the Play, App Store and Test
  Store products. The app reads offering `android` (`ofrngdc8ee90146`, not
  current; iOS keeps `default`) with `$rc_monthly` (`pkge8a833a45ef`),
  `$rc_annual` (`pkge2893ffe17a`) and `$rc_lifetime` (`pkge5e4367d966`), each
  holding the Play product (`...monthly:monthly`, `...yearly:yearly`,
  `...lifetime`) and the Test Store twin (`monthly`, `yearly`, `lifetime`).
- Play reviewers unlock Bridge+ with a code (long-press Settings > Version).
  Only its SHA-256 is in the build (`PLAY_REVIEW_CODE_SHA256` in
  `local.properties`); the code is `BRIDGE_PLAY_REVIEW_CODE` in
  `~/.bridge_credentials` and goes in Play Console App access. Never commit it.

## Content and parity

- Content and engine fixtures come from Swift, never hand-edited:
  `scripts/sync-android-content.sh` runs `scripts/android-export/` and writes
  `app/src/main/resources/bridge-content.json` and the test fixture
  `bridge-parity.json`. Rerun it after changing `Shared/Models`,
  `Shared/Content`, `WhatsNew.swift` or `ChoiceShuffle.swift`.
- `SeededRandom.kt` is the Swift RNG bit for bit (FNV-1a seed, xorshift64*,
  Lemire bounded draw, forward Fisher-Yates), so generated hands, choice order
  and the daily Bridge Minute match iOS. `GeneratorParityTest` compares the
  classifier, generated hands and six days of Bridge Minute against the
  fixture, and keeps the `testAuthoredHandsMatchTheClassifier` rule: authored
  opening drills must agree with the engine that grades Endless Practice.
- The daily declarer question comes from the authored `PlayScenario`s, never
  through `SessionBuilder.choiceItems` (which skips Play drills).

## Deliberate differences from iOS

- Purchase copy names Google Play and has no "24 hours before the end of the
  period" clause (Play has no such rule).
- The review prompt keeps the iOS gates (second launch on, 30-day cooldown) and
  calls `launchReviewFlow` with no enjoyment question. Settings says "Rate
  Bridge Trainer" and opens the Play listing.

## Build

- JDK 17, checked-in Gradle wrapper, AGP 9.4.1, Kotlin 2.4.20, minSdk 26,
  target/compile 36.
- `android/local.properties` (ignored, mode 600) holds `REVENUECAT_TEST_KEY`,
  `REVENUECAT_PLAY_KEY`, `PLAY_REVIEW_CODE_SHA256` and `PLAY_UPLOAD_*` (upload
  keystore `~/.android/keystores/bridge-upload.p12`, backup in
  `~/.android/keystores/backups/`, alias `upload`, password
  `BRIDGE_PLAY_UPLOAD_PASSWORD` in `~/.bridge_credentials`). Release builds
  fail without them. Upload cert SHA-256
  `4F:55:49:0C:01:1B:FE:40:7E:48:1C:42:B2:FA:85:5A:4E:45:2C:68:C1:E1:3D:07:8E:00:1C:2B:D4:55:32:33`.
- `scripts/make_android_icon.py` derives the adaptive icon layers, legacy and
  round icons and `play-assets/icon-512.png` from the iOS AppIcon.
- Increment `versionCode` on every Play upload. 1.2.5 is versionCode 1.
- `scripts/play-upload.sh [validate|internal|internal-draft|production-draft]`
  and `scripts/play-products.py [--dry-run]` need `PLAY_SERVICE_ACCOUNT_JSON`.
  Neither has been run yet.

## Emulator (remote MacBook Pro only)

Follow the `android-dev` skill's Remote MacBook Pro section. Host
`jackwallner@192.168.4.25` (strict host keys), SDK
`/Users/jackwallner/Library/Android/sdk`. The Pro has no cmdline-tools. Build and
test with `fm-gradle <tasks>` from `android/` (jmbp is the Pro), never
`./gradlew` on the Air. It syncs the source with a debug-only
`local.properties` (no Play key or upload secrets), uses the Pro's JDK 17 and
forwards `ANDROID_SERIAL`, so connected tests need no hand sync. Create the temporary AVD
`bridge_agent_test` by hand (`.ini` plus a `config.ini` cloned from another
agent AVD, `android-36` `google_apis_playstore` x86_64, 1080x2400), boot it
headless on port 5572:

```sh
ssh jackwallner@192.168.4.25 'mkdir -p ~/bridge-agent-test && nohup ~/Library/Android/sdk/emulator/emulator -avd bridge_agent_test -port 5572 -no-window -no-audio -no-boot-anim -no-metrics -gpu swiftshader_indirect > ~/bridge-agent-test/emulator.log 2>&1 &'
ssh jackwallner@192.168.4.25 '~/Library/Android/sdk/platform-tools/adb -s emulator-5572 shell getprop sys.boot_completed'
```

Disable Digital Wellbeing (`pm disable-user --user 0
com.google.android.apps.wellbeing`) and set the three animation scales to 0
before tests. Run connected tests from `android/` with
`ANDROID_SERIAL=emulator-5572 fm-gradle --max-workers=2 connectedDebugAndroidTest`. Afterwards
`adb -s emulator-5572 emu kill`, then delete only
`~/.android/avd/bridge_agent_test.{avd,ini}` and `~/bridge-agent-test`. Never
touch `small_phone` (emulator-5554) or other agents' AVDs. The Pro is a 2-core
2015 i7: a cold boot takes about 5 minutes; let it settle before a connected
run.

Debug launch extras (`DebugLaunchOptions`, debug builds only): `resetAll`, `onboarded`, `skillLevel`, `seedProgress`, `forcePro`,
`appearance`, `uiTest`. Test tags are exposed as resource ids.

## Store assets

`StoreScreenshotTest` (excluded from the connected suite; run it with
`am instrument -w -e class com.jackwallner.bridge.StoreScreenshotTest com.jackwallner.bridge.test/androidx.test.runner.AndroidJUnitRunner`)
writes six raw 1080x2400 captures to
`/sdcard/Android/data/com.jackwallner.bridge/files/screens/`: quick session,
opening bid, lead or hold, declarer, Home and the Auction Room. Turn System UI
demo mode on first. Pull them into `android/play-assets/raw/` and run
`python3 scripts/play_screenshot_compositor.py` for the 1080x1920 frames and
the 1024x500 feature graphic. Listing text and the changelog are in
`android/play-assets/metadata/android/en-US/` (English only, no prices, no em
dashes, worded apart from the other card trainers). Privacy and terms pages
are `docs/android-privacy.html` and `docs/android-terms.html` on GitHub Pages.

## Play state (2026-10-17)

Ready to send (verified 2026-10-17): review code saved in App access, RevenueCat
Play credentials set. Only Send for review remains, in this app's pacing slot.

Staged, not sent for review. Play app id `4972397687798213539` (E3 Apps). versionCode 1
(1.2.5) uploaded with `~/docs/android/tools/play_stage.py`; listing, icon,
feature graphic and 6 screenshots committed by API; draft releases on
internal and production, production targets all 178 countries. Products from
`scripts/play-products.py` are active (two subscriptions with `trial-7d`, one
lifetime). App content is complete: privacy policy, no ads, no ad ID, not a
government app, no financial features, App access (instructions only),
18 and over, data safety (RevenueCat: purchase history, app interactions,
device IDs), IARC, category Education. Publishing overview shows
"Submit 11 changes for review".

Left for Jack: paste `BRIDGE_PLAY_REVIEW_CODE` from `~/.bridge_credentials`
into App access > Bridge+ review unlock > Password, then press Send for review
when this app's pacing slot comes. Review codes: `~/docs/android/tools/play_handoff.py review-codes`. RevenueCat Play
credentials were uploaded with `play_handoff.py rc-credentials --apply`
on  2026-10-17. The RevenueCat service account already has
account-wide Play permissions, so no per-app grant is needed.

## Pro test runner checks

The Pro's `connectedDebugAndroidTest` returned `BUILD SUCCESSFUL` with zero
tests on 2026-10-17 after its device runner was killed. Require a nonzero count
in the XML report. If the runner fails, install the debug app and test APK on
`emulator-5572` and invoke `AppFlowTest` directly on the Pro:

```sh
~/Library/Android/sdk/platform-tools/adb -s emulator-5572 shell am instrument -w -r -e class com.jackwallner.bridge.AppFlowTest com.jackwallner.bridge.test/androidx.test.runner.AndroidJUnitRunner
```

Require `OK (8 tests)` in its output. Never infer a pass from Gradle's exit
code alone.

On this temporary AVD only, Play Store and Play services can be disabled for
UI tests that do not exercise billing. This AVD showed System UI ANRs during
startup on the 2015 Pro. UI tests can use `wm size 720x1600` and
`wm density 280` to reduce software rendering work, with the same effective
screen width as 1080x2400 at density 420. Reset both before store captures.
Preserve `small_phone` and its Google Play account.

`forcePro` launch extras honor both true and false so member and free tests
remain isolated when run in one instrumentation process. The free card quiz
uses drill ID `card-check`, exported from Swift.


## Verified build (2026-10-17)

- Unit tests: 56 passed. Release APK and signed AAB: `assembleRelease` and
  `bundleRelease` passed for version 1.2.5, versionCode 1, target SDK 36.
- Pro device tests: 8 passed with direct instrumentation. The local report is
  `android/app/build/reports/pro-20261017/AppFlowTest.xml` and its sibling log.
  Six `StoreScreenshotTest` cases also passed; its log is in the same folder.
- Verified AAB signature and upload certificate above, all four native-library
  ELF load alignments at 16 KB, and release APK ZIP alignment at 16 KB.
- Visually reviewed light and dark Home plus the six captured drill/room
  screens. The six RGB Play frames and feature graphic are generated in
  `android/play-assets/`; no store upload was performed in this build session.
- Shut down the Pro emulator, verified its serial and process were absent,
  then removed this task's temporary Bridge AVD and test checkout.
