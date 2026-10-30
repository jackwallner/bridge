---
paths:
  - "Shared/Services/SubscriptionService.swift"
  - "Shared/Services/ProgressStore.swift"
  - "Bridge/Views/OnboardingView.swift"
  - "Bridge/Views/PaywallView.swift"
  - "Bridge/Views/HowToPlayView.swift"
  - "Bridge/Views/FeatureTourView.swift"
  - "BridgeTests/TrialCopyTests.swift"
  - "BridgeTests/TrialEligibilityTests.swift"
  - "BridgeTests/PaywallFunnelTests.swift"
---

# Bridge: membership, the trial flow and fit

Bridge+ (entitlement `Bridge+`). Prices are read live from StoreKit through
RevenueCat (`PaywallPricing`); never hardcode one anywhere.

**Trial flow, structurally Mahj 1.3.2.** Onboarding trial page: soft "Get
Started" exit above the primary, primary CTA in the exact Continue slot, one tap
buys the MONTHLY trial, Apple confirms. The billed amount is the most prominent
price (22pt, 3.1.2(c)) with the small disclosure under it; the paywall footer
keeps the same 22pt line. `trialDisclosure` must always name the plan the CTA
buys. Backing out of Apple's sheet is `PurchaseOutcome.cancelled`, never an
error and never another paywall. The trial end date is not shown anywhere (the
trial-end reminder screen was cut in Mahj); Settings shows Manage Subscription
only when there is an expiration date (not for lifetime). Only the button wording
varies, via `TrialCTA` offering metadata; any other change to this flow needs
Jack's go-ahead.

The five benefit rows follow Mahj 1.3.2 (Jack, 2026-10-21): free beginner
rooms first, then the paid Minute and a personalized Game Night Prep, then
Endless Practice, Fix My Mistakes and the extra sets. Mahj 1.4.1 rewrote
rows 2 and 4 because its Minute went free; here the Minute is still paid,
so the 1.3.2 wording holds. Drop the Minute from row 2 if it ever goes free.

**Intro-offer eligibility (2026-10-20, Mahj fc6b7ed).** Apple gives one free
week per subscription group, so a lapsed member is charged on day one.
`SubscriptionService.isTrialEligible(for:)` asks StoreKit (no product reads as
eligible, as before). The onboarding trial page and `PaywallView` load it in
`.task` and, when it is false, drop every free-week line: onboarding title "Get
Bridge+ today", the CTA "Join Bridge+", the plan cards "Billed yearly.
Auto-renews." / "Billed monthly. Auto-renews.", and `PaywallPricing.terms(...,
trial: false)` ("$X/month, billed today. Auto-renews until canceled."). The
billed amount stays the largest price. A purchase tap re-checks eligibility
after offerings load and, if it changed, redraws and returns without buying.
`TrialEligibilityTests` runs against `Bridge.storekit`; its lapsed-account half
is left out because `Product.purchase` hangs on the gh-sim runner. The eligible
copy is unchanged.

**Membership state.** `membershipResolved` is false until a customer record was
read (cache or network); nothing may treat "not a member" as a lapse or sell a
trial before it. A reinstall is a new anonymous RevenueCat user:
`recoverReinstalledMembershipIfNeeded` syncs once per install when StoreKit owns
an entitlement, and `ensureOfferings` (so every purchase) waits for it (3s cap).
Both purchase buttons stay disabled until `membershipResolved`, so
`ensureOfferings` and `loadOfferings` re-read the customer record while it is
false (a failed launch fetch used to leave them dead for the session).
`startedTrial` comes from the purchased entitlement's `periodType`, not the
product. `confirmEntitlement` fetches a fresh record. Simulators keep the
early-return in `configureIfNeeded`: never configure the production `appl_` key
there.

**Fit.** Every fix is conditional on fit or text size, never on device. At
accessibility sizes the onboarding pages, the primer and the tour put the page in
a ScrollView with the buttons pinned below; Home and the room grid drop to one
column, the Bridge+ badge stacks under the title and the room icon tile hides;
the trial page keeps the designed layout below AX sizes. The primer's hand row
takes the largest of 46/40/36/32pt that fits. Home's header stacks the chips
under the title on compact widths (no gear collision), and the toolbar keeps its
system background. Dark mode uses `Theme.onFill` on filled buttons and
`Theme.goldText` for small gold text.

**What's New mechanics.** `WhatsNew.currentRelease` is the newest entry at or
below the running version, so a build with no entry of its own still carries the
last notes once to a player who skipped a version. `shownThisLaunch` delays ATT.
There is no 1.3.0 entry yet: phase 2 writes it with the real feature list.
