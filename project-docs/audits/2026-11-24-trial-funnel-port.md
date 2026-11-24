# Trial funnel port from Mahj Trainer (2026-11-24)

Jack approved this after the 2026-11-24 fleet parity scan. Bridge goes first so the
effect can be measured before the same port goes to Cribbage, Sheepshead, Skat and
Electrician.

## What was ported

Before this, a free player who skipped the onboarding trial page only met Bridge+ again
when they tapped something locked. Mahj Trainer added three asks after onboarding, and
Bridge now has the same three:

1. **One-tap trial sheet** (`TrialOfferSheet`). One plan (monthly, the onboarding
   page's plan), a button that goes straight to Apple's confirm sheet, and "Not now".
   It carries every 3.1.2 element the onboarding page does: the billed amount as the
   largest price, the auto-renew line, Terms, Privacy and Restore. An account that
   already had its free week sees "Join Bridge+" and the billed-today line. Backing out
   of Apple's sheet keeps the sheet up. Ask to Buy shows the localized waiting line.
   The full plan picker opens only if products failed to load.
2. **Pacer** (`TrialOfferPacer`, copied from Mahj line for line). After a good result
   (a drill at 50% or better, or any finished deck), the sheet opens by itself when all
   of these hold: the player is onboarded, is not a member, the customer record has been
   read, they have done 2 practices since onboarding, the RevenueCat `trial_offer`
   switch is not `off`, and StoreKit says the free week is still available. Pacing: on
   install day and the day after, once per app visit (30 minutes away starts a new
   visit) and at most 3 a day. After that it waits 3 days since the last ask, then 7,
   then every 14. Apple's rating prompt stands down for a result where the sheet opened.
3. **Bridge+ card on results** (`BridgePlusPitchCard`). It sits under every finished
   drill for non-members ("Try Bridge+ free for 7 days", or "Get Bridge+" for an account
   with no free week left). Tapping it opens the sheet, with no pacing.

### Mahj trigger to Bridge trigger

| Mahj | Bridge |
|---|---|
| Drill result: card, plus the automatic ask (`drillResult`) | `DrillCompleteView`: room drills, the daily Get Started session, and the Endless, Fix and Timed runs (those three are members-only, so the card stays hidden there) |
| Mahj Minute result: card, plus the automatic ask (`minuteResult`) | Not ported. Bridge Minute is Bridge+ only (`AppDestination.isFree` is Play a Hand only), so no non-member ever reaches its result |
| Play a Hand, free hand spent: automatic ask (`handSpent`), and the upsell opens the sheet | `HandPlayView`: the same. A finished free hand shows the card ("That was today's free hand"), and the locked-state button opens the sheet instead of the full paywall |

### Deliberate differences from Mahj

- **Eligibility adds `membershipResolved`.** Bridge's rule is that nothing sells a
  trial before the customer record is read. Otherwise the conditions are the same as
  Mahj's.
- **No timeline arm.** Mahj splits its sheet between a benefits list and a dated free-week
  timeline (`offer_pitch`). Bridge ships the benefits arm only, so this read measures the
  port and nothing else.
- **No analytics events.** Bridge has no product analytics, so the RevenueCat impressions
  below carry the read.
- **Unknown eligibility promises no trial** (Bridge's existing rule). Mahj's sheet assumes
  the free week until StoreKit says otherwise.

## File map

| File | Change |
|---|---|
| `Shared/Services/TrialOfferPacer.swift` | New. Pacing, session counting, rating-prompt stand-down |
| `Bridge/Views/Components/TrialOfferSheet.swift` | New. The sheet, the `.trialOffer(...)` modifier, `TrialOfferEligibility` |
| `Bridge/Views/Components/BridgePlusPitchCard.swift` | New. The results card |
| `Shared/Services/RemoteConfig.swift` | `RemoteSwitch.trialOffer` (`trial_offer`, on unless `off`) |
| `Bridge/BridgeApp.swift` | Foreground and background notes for the pacer's sessions |
| `Bridge/Views/Drills/DrillCompleteView.swift` | Card under the summary (now in a `CenteringScrollView`), automatic ask, rating prompt waits for it |
| `Bridge/Views/Drills/HandPlayView.swift` | Automatic ask when the free hand is spent, card on the finished free hand, locked button opens the sheet |
| `Bridge/Views/HomeView.swift` | DEBUG `-bridge.previewTrialOffer` for captures |
| `Shared/Services/SubscriptionService.swift` | DEBUG `-bridge.previewTrialEligible` for captures (Test Store products have no free week) |
| `Bridge/Localizable.xcstrings` | 10 new keys, all 15 languages |
| `BridgeTests/TrialOfferPacerTests.swift` | New. Mahj's pacer tests, the clock-ahead and Beirut DST cases, eligibility, card visibility, terms, impression IDs |
| `BridgeTests/TrialCopyTests.swift` | Adds `trial_offer` to the switch list |

## Verification

- Leased simulator (agent-sim), RevenueCat Test Store key through `-rcfunnelprobe`,
  never the production `appl_` key. The Test Store bills $9.99, so that is the price in
  the screenshots. The live app reads $8.99 from StoreKit.
- Screenshots in `2026-11-24-trial-funnel-port/`:
  - `sheet-eligible.png`: the sheet for an eligible account.
  - `result-card.png`: the card under a 10/10 Get Started session.
  - `auto-sheet.png`: the same result a few seconds later, with the sheet opened by the
    pacer (practices since onboarding seeded to 3).
  - `member-result.png`: a member finishing a deck. No card, and no sheet after 7 seconds.
- The ineligible wording ("Join Bridge+", billed today) was checked live on the Test
  Store product, which has no free week.
- Not walked on the simulator: the Play a Hand card and its automatic ask (a full hand
  takes about 40 taps). Both use the same modifier and card as the drill result, and the
  build compiles them.

## What to measure

RevenueCat impression IDs (`paywall_encounter_v3`):

| ID | Surface |
|---|---|
| `bridge_offer_drill` | Card tapped on a drill result |
| `bridge_offer_drill_auto` | Sheet opened by the pacer after a drill |
| `bridge_offer_hand` | Card or locked button tapped in Play a Hand (this replaces `bridge_hand_play`) |
| `bridge_offer_hand_auto` | Sheet opened by the pacer after the free hand |

Read it 2 weeks after the build is live on the App Store, against the 2 weeks before:

1. **Trial starts per install, all surfaces.** This is the decision number. The sheet can
   pull trials away from the onboarding page or the full paywall, so only the total shows
   whether it adds trials.
2. **Trial start rate per paywall view, by entry point.** Trials started divided by
   impressions for each ID above, next to `bridge_onboarding_trial` and the
   `bridge_*_sheet` paywalls. Before the release the four new IDs do not exist, so their
   baseline is the trials that came from anywhere except the onboarding page.
3. **Trial to paid** for trials that started on a `bridge_offer_*` surface, once those
   trials have finished.
4. **Guardrails.** Rating prompt volume, and 1-star reviews that mention pop-ups or
   being asked to pay.

Decision rule for the other four trainers: port it if trial starts per install go up
and trial-to-paid on the new surfaces is not clearly below the onboarding page's.
`trial_offer: off` on every offering stops the automatic asks without a release, and the
cards stay.
