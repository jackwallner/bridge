---
paths:
  - "Shared/Services/MetaAds.swift"
  - "Shared/Services/RemoteConfig.swift"
  - "Bridge/Views/HomeView.swift"
  - "Bridge/Info.plist"
  - "project.yml"
---

# Bridge: Meta SDK, ATT and remote switches (inert)

Ported from Mahj 1.4.1. Mahj's `.claude/rules/meta-ads.md` and
`project-docs/marketing/meta-ads.md` hold the full story.

- `MetaAds` is inert while `META_APP_ID` and `META_CLIENT_TOKEN` are empty in
  `project.yml` (they are empty): no SDK start, no ATT prompt, nothing sent. It
  never starts on a simulator either. The Facebook SDK (exact 18.1.1,
  `FacebookCore`) is linked and its Info.plist keys are present, so turning it on
  is two strings. Change the App Store privacy labels and add a Meta section to
  the privacy page in the SAME submission that sets the ids, never before.
- `MetaAds.start` runs in `AppDelegate`, `linkRevenueCat()` right after
  `Purchases.configure`, `activateApp()` on every foreground.
- ATT is asked only by `HomeView.askForTrackingIfNeeded`: onboarded, a finished
  practice of the player's own after the tour (`hasPracticedSinceOnboarding`),
  bare Home, 1.2s settle, not in a launch that showed What's New
  (`WhatsNew.shownThisLaunch`), after the offering loaded
  (`remoteConfigKnown`), and `att_prompt` not `off`. Never move it to launch or
  onboarding. `askApple()` stays `nonisolated` (Swift 6 trap).
- StartTrial belongs to a server relay, never to RevenueCat's Meta integration.
  The relay lives in the Mahj repo (`supabase/functions/meta-trial-relay`) and is
  NOT ported. When Bridge gets a Meta app id the relay needs a per-app
  row/config (its Meta dataset id, token and RevenueCat webhook entry) before
  the ids go into `project.yml`, or trials are never reported.
- `RemoteConfig` reads the current RevenueCat offering's metadata: `trial_cta`
  (`seven_day` control, `my`, `your`) and the switches `att_prompt`,
  `rating_prompt`, `challenge` (on unless exactly `off`; set the same on every
  offering). The `challenge` switch is declared but nothing reads it yet: phase 2
  gates the challenge card and deep link on it. DEBUG builds pin any key with
  `-bridge.rc.<key> <value>`; `-bridge.previewMetaATT` shows the real ATT alert in
  captures.
