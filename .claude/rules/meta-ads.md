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
- ATT is asked only after a trial start or a purchase (Jack 2026-10-19), so
  only paying players are prompted and the relay can count a consented trial
  within its 15 minutes. `SubscriptionService.purchase` calls
  `MetaAds.notePurchase()` on every completed purchase (onboarding page,
  paywall; restore is not a purchase), which stores `meta.askAfterPurchase`;
  `HomeView.askForTrackingIfNeeded` asks on the next bare Home and
  `requestTracking` clears the flag. A player who never starts a trial or buys
  never sees the prompt. Guards kept: onboarded, bare Home, 1.2s settle, not in
  a launch that showed What's New (`WhatsNew.shownThisLaunch`), after the
  offering loaded (`remoteConfigKnown`), and `att_prompt` not `off`. Never move
  it to launch or onboarding. `askApple()` stays `nonisolated` (Swift 6 trap).
- StartTrial belongs to the server relay, never to RevenueCat's Meta
  integration. The relay lives in the Mahj repo
  (`supabase/functions/meta-trial-relay`) and can serve this app
  (`?app=bridge`), but Meta is OFF for every app except Mahj (Jack 2026-10-21):
  no Meta app, no RevenueCat webhook to the relay, no relay secrets. Do not
  turn any of it on without Jack's go-ahead; the steps are in Mahj's
  `project-docs/marketing/meta-ads.md`.
- `RemoteConfig` reads the current RevenueCat offering's metadata: `trial_cta`
  (`seven_day` control, `my`, `your`) and the switches `att_prompt`,
  `rating_prompt`, `challenge` (on unless exactly `off`; set the same on every
  offering). The `challenge` switch is declared but nothing reads it yet: phase 2
  gates the challenge card and deep link on it. DEBUG builds pin any key with
  `-bridge.rc.<key> <value>`; `-bridge.previewMetaATT` shows the real ATT alert in
  captures.
