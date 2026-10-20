---
paths:
  - "Shared/Services/FeedbackService.swift"
  - "Shared/Services/MembershipTransitions.swift"
  - "Shared/Services/MasteryLedger.swift"
  - "Shared/Services/Mastery.swift"
  - "Shared/Services/ReviewPromptTracker.swift"
  - "Bridge/Views/ReviewPromptSheet.swift"
  - "Bridge/Views/Components/ReviewRequest.swift"
  - "Bridge/Views/StatsView.swift"
  - "BridgeTests/FeedbackServiceTests.swift"
  - "BridgeTests/MasteryLedgerTests.swift"
  - "BridgeTests/MembershipTransitionsTests.swift"
---

# Bridge: feedback, the churn question, and the weekly gain (1.3 platform layer)

Ported from Mahj 1.4 to 1.4.2 (phase 1 of the Bridge refresh, 2026-10-19). Mahj's
`.claude/rules/feedback-and-retention.md` has the reasoning; this file is what
differs here.

## Ratings (App Review 5.6.1)

No question stands in front of Apple's prompt, ever. A finished drill or Bridge
Minute scoring half or better bumps a counter; `requestsReview(after:)` waits
3s, re-checks the screen (view on screen, no alert or share sheet up) and calls
`requestReview()`. Gates live only in `ReviewPromptTracker.shouldRequestReview`:
second cold launch, 30-day cooldown, and opening the write-review page ends the
asks. Also required: onboarded, and RevenueCat `rating_prompt` not `off`.
Settings has two separate rows: Rate (write-review page, ends the asks) and Send
Feedback (never stops them). The old pending-positive-moment tracker and the mail
draft `FeedbackSheet` are gone. No per-question report link (Jack's call in Mahj:
a flag under every answer casts doubt on the right one).

## The feedback sink

`FeedbackService` posts to the shared Supabase `app_feedback` table (project
`ucoveqbyfuxqvpysmixu`) with `appID = "bridge"`. The publishable key can only
INSERT rows where `app` is one of the card trainers (migration
`20261019120000_card_apps_feedback.sql` in the Mahj repo) and `kind` is
`general`, `not_enjoying`, `question` (retired) or `churn`. 2xx is sent;
network error, 408, 429 and 5xx queue the row (cap 20, retried on launch and
every return to the app); any other 4xx is dropped. Nothing personal is sent.
The public privacy page (`docs/privacy-policy*.html`) describes the fields
(updated 2026-10-19); keep it in step.

## One sheet, two jobs

`ReviewPromptSheet` has `.feedback` and `.churn(ChurnMoment)`. Neither touches
`ReviewPromptTracker`. `SubscriptionService.observe` compares each RevenueCat
record with the last one (`MembershipTransitions.churnMoment`) and stores at
most one `ChurnMoment` per departure. A first record only becomes the baseline
if RevenueCat answered within 5 minutes (`freshBaselineAge`): launch applies the
cached record first, which can be months old. Home shows the question once
0.9s after it is bare (`HomeView.homeIsBare`) and spends it only when shown.

## Weekly gain

`MasteryLedger` stores known-question counts per room once a day (`Mastery.swift`
supplies `RoomMastery`; an item is known after two right answers in a row and
until a full interval past due). `weeklyGain()` drives the plum "+N" chip on
Home and the "Up N this week" card on Your Progress. Nothing is baked into the
repeating reminders (`AppSettings.dailyReminderBody` is static and number-free;
Bridge never shipped Mahj's counted 1.4.0 copy, so no migration exists).

## Not ported, on purpose

Trial-end reminder screen (Mahj removed it from the frozen trial flow), the
game night card on Home, per-question report link, and the monthly challenge
(phase 2). Mastery rings on Home rooms, the "what is holding" list and "work on"
card use the same `Mastery.swift` data and are phase 2.
