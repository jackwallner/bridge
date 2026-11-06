# State machine audit, 2026-11-06

Scope: iOS app `Bridge` (SwiftUI, `Bridge/` and `Shared/`), audited at commit 38f9417 (`git stash -u` found nothing to stash, tree was clean). There are no widget, watch or backend targets in this repo. The only server the app talks to is the shared Supabase feedback table (FeedbackService) and RevenueCat. Android is out of scope.

**Summary: 4 bugs. 2 proved by a failing test (SM-2 at store level, SM-4), 2 code path only (SM-1, SM-3). Plus 8 product calls (not counted).**

Evidence run: `gh-sim test --scheme Bridge --only BridgeTests/StateMachineAuditRepro`, GitHub run 42287448922 (iPhone 17, iOS 27.2): 1 passed, 3 failed, 1 skipped. An earlier run, 42283274844, recorded the same SM-2 and SM-4 values and showed the SM-3 test's first draft modelled the SwiftUI onChange hook wrongly (fixed before the second run). The suite is `state-machines-2026-11-06-repro.swift` next to this file.

Existing test seams, listed before choosing evidence types: injected `UserDefaults` suites on every store (`ProgressStore`, `PracticeRecordStore`, `MasteryLedger`, `BridgeMinuteStore`, `AppSettings`, `SubscriptionService`), the `RevenueCatClient` protocol with constructed `CustomerInfo` fixtures (PaywallFunnelTests), `ownsCurrentPurchase` injection, `now:` parameters on stores, `NSTimeZone.default` (ProgressStoreTests). There is no seam for `UNUserNotificationCenter` (AppSettings calls `.current()` directly) and none for view `@State`, so notification claims and view-only claims stay code path.

## Bugs, ranked by impact

| id | bug | what the user sees | promise | user route | impact | evidence | file:line |
|---|---|---|---|---|---|---|---|
| SM-1 | Reminder toggles are never reconciled with the requests the system actually holds. Nothing re-schedules at launch. | Settings shows Daily Reminder (and Game Night) switched on with a time, and no reminder ever arrives. No hint anywhere. | "an optional daily reminder" and "an optional weekly reminder" (fastlane/metadata/en-US/description.txt:12, :24); toggle row "Daily Reminder" (SettingsView.swift:101); "Prep is scheduled" shown whenever the flag is on (GameNightPrepView.swift:78). | Settings > Daily Reminder on, allow. Then any of: (a) restore the phone from a backup or migrate it (UserDefaults come across, pending local requests do not), (b) iOS Settings > Notifications > Bridge Trainer off, then on again (iOS drops pending requests when permission is revoked; to confirm on a device), (c) force-quit while the first permission sheet is up (the flag is saved before the answer, AppSettings.swift:77-82). Reopen Settings: toggle on, nothing pending. Only toggling off and on (or changing the time) schedules again. | Everyone with a reminder who changes phone or cycles notification permission. Cost is the loss of the app's only retention nudge, silently, with the UI saying the opposite. No usage numbers are available in the repo; the population is reminder users who migrate or restore a phone, or cycle notification permission. | Code path. Complete scheduler call-site list in M5 below: the only callers are the two toggle `didSet`s, the two time `didSet`s and the game-night day `didSet`; none runs from `init`, `BridgeApp`, `AppDelegate` or a scene-phase hook; `getNotificationSettings` and `getPendingNotificationRequests` appear nowhere. The test `testEnabledReminderTogglesAreBackedByPendingRequestsAfterLaunch` SKIPPED: on the runner the simulator's center kept no unauthorised add (control pending=[]), so launch-time scheduling cannot be observed there. Settles it: on a device, enable the reminder, revoke and re-grant notifications (or restore from a backup), then read `getPendingNotificationRequests`. | AppSettings.swift:75-100 (didSets), :124-127, :164-189, :199-229; BridgeApp.swift:20-61 |
| SM-2 | Flashcard "Undo" rewinds the deck but not the answer it recorded. | After undoing a wrong pick and answering right, Your Progress counts two attempts (50% on that card), and the card is a "mistake": it counts in the "N due" badge and Game Night Prep's "N due mistakes first", and appears in Fix My Mistakes tomorrow, though the player's final answer was right. | Toolbar control labelled "Undo last answer" (FlashcardDrillView.swift:89); "Undo lives in the toolbar" (Bridge/Views/Drills/AGENTS.md:5-6). | Home > The Defense Room > Lead or Hold? (free deck, every card has a two-button self-test). Pick the wrong button, tap the card's arrow or Next to move on, tap the undo arrow (top right, appears after the first card), pick the right button. Undo is one level deep, so it is reachable on every card after the first. | Every player who uses Undo in a self-test deck (free for all; the Plus review queue consumes the result). Cost is small per use (a spurious review item, skewed accuracy), but the controls invite use after any misclick. | Test (store consequence) plus code read (the view's call sequence). `testUndoThenRightAnswerLeavesOneAttemptAndNoDueMistake` FAILED with recorded values: `attempts=2 correct=1 streak=1`, `needsReview=true`, `dueCount=1`, item present in `reviewQueue`. Preconditions asserted (a free, reviewable choice card; empty store); control (one right answer) passed: attempts 1, needsReview false, not queued. The test replays the two `record` calls the view makes (`choose` at :237, `commit` at :349) because `undo()` (:363-376) touches only `queue`, `lastSwipe`, `choicePick`, `isFlipped`, and no store API can retract an answer. The view half is code path: no way to drive the swipe deck here. | FlashcardDrillView.swift:232-252, :338-361, :363-376; PracticeRecordStore.swift:31, :69-95 |
| SM-3 | The weekly Game Night reminder is switched off only by an observed `isPro` change, so a non-member whose first record already says "not a member" keeps it, and cannot reach the switch. | A lapsed or restored-from-backup player keeps getting "Your game night prep is ready" every week. Tapping it shows the paywall. Game Night Prep (and its toggle) is hidden for them. | Banner title "Your game night prep is ready" (AppSettings.swift:216); both Game Night features "entirely Bridge+ gated" (.claude/rules/game-night.md:38); Home's own intent: turn it off when membership ends (HomeView.swift:146-148). | Needs: Game Night reminder on, then a process whose first customer record is not a member (reinstall or backup restore on a new RevenueCat user, or a cached record RevenueCat reports as expired). Then wait for the chosen weekday; or open Settings (no Game Night row, SettingsView.swift:105) and Home (Game Night tile opens the paywall). A running-app lapse IS handled (control test passes). | Small: lapsed or restored members who had the weekly reminder on. Cost is a recurring notification they cannot turn off in-app and that opens a paywall. Whether the common lapse path hits it depends on whether RevenueCat reports an expired cached record as inactive at launch (unconfirmed). | Code path with a model test. `testGameNightReminderIsOffWhenTheFirstRecordSaysNotAMember` FAILED: "weekly Game Night reminder still enabled for a non-member", with its precondition and `hookFires == 0` assertions passing. The test replicates HomeView's `onChange` as `$isPro.removeDuplicates().dropFirst()`, so it proves the hook is edge-triggered, not that the premise occurs in production. Control `..._control` (member then lapse) passed. Settles it: launch with a cached expired record and the reminder on, on a device, and read pending requests; or check RevenueCat 5.72 `EntitlementInfo.isActive` for cached records. | HomeView.swift:141-149; AppSettings.swift:105-111; SettingsView.swift:105 |
| SM-4 | Weekly gain compares ledger days that measure different item sets after a membership change. | Home chip "+5 questions locked in this week" and Your Progress "Up 5 questions this week" appear for a player who answered nothing in the last 7 days. | "\(gain) questions locked in this week" (HomeView.swift:397); "Up \(gain) questions this week" (StatsView.swift:78); the code itself names the hazard: "a member reads as free and the day's entry would drop every Bridge+ item, faking a gain the next day" (HomeView.swift:223-224), guarded only for the unresolved case. | Member with Bridge+ sets learned more than a week ago. Membership lapses. Open Home as a free player (ledger row excludes Bridge+ items). Within 7 days re-subscribe (Home upgrade card or Settings > Get Bridge+). Home shows the chip, Your Progress the card. | Win-back subscribers who opened Home while lapsed and returned within a week. Rare, cost is a misleading positive chip. | Test. `testResubscribingDoesNotReportOldLockedInQuestionsAsThisWeeksGain` FAILED: `XCTAssertNil failed: "5" - chip would read +Optional(5) questions locked in this week with no practice`. Preconditions asserted (Bridge+ items known for a member and hidden for a free player; every record last answered more than 7 days ago). Control (same membership on both days) passed: nil. | MasteryLedger.swift:33-57, :87-93; Mastery.swift:138-146; HomeView.swift:222-227 |

### Product calls (no promise to cite, not counted)

- P1 A member has no way to buy Lifetime (or change plan) from the app: `purchase` returns `.purchased` when `isPro` (SubscriptionService.swift:406), the paywall closes itself on `isPro` (PaywallView.swift:357), Settings shows no upgrade row for members (SettingsView.swift:133-141).
- P2 Revoking notification permission in iOS Settings leaves the toggles on with no banner. The denial alert only appears when a toggle is switched on (AppSettings.swift:164-170). Closely related to SM-1.
- P3 Both reminders are static repeating requests, so they fire after the player already practised today (AppSettings.swift:176-189). Copy is deliberately generic.
- P4 `willPresent` shows banners in the foreground (AppRouter.swift:75). Tapping a Game Night banner during a drill replaces the navigation path (HomeView.swift:271-290) and the unfinished session earns no streak credit.
- P5 Home reads `quickSessionCompletedToday()` and `currentStreak()` in `body` and nothing invalidates it at midnight, so a Home left open across midnight can show yesterday's card and streak until another published value changes (HomeView.swift (`todaySession`), ProgressStore.swift:75).
- P6 `reminderPermissionDenied` is one flag bound to two alerts (SettingsView.swift:63, GameNightPrepView.swift:37) that are both mounted when Game Night is opened from Settings. Which alert presents on denial was not verified.
- P7 What's New is marked seen before it is shown (HomeView.swift:305), so a kill inside the 0.5 s window loses it.
- P8 `markShown()` is written before `requestReview()` (ReviewRequest.swift:47), so a prompt Apple swallows still burns the 30-day cooldown.

### Related fixes, in order

1. Reminder reconcile (SM-1, P2, and SM-3 if it also checks membership): one `reconcileReminders()` on launch and on `scenePhase == .active`, comparing the two toggles with `getNotificationSettings` and `getPendingNotificationRequests`; re-add a missing request when authorised, turn the toggle off and say so when not. After the first record resolves, also cancel the Game Night request for a non-member. This also makes the Game Night rule level-triggered instead of edge-triggered.
2. Undo (SM-2): snapshot the item's `PracticeRecord` and the seen/missed membership before grading, and restore them in `undo()`; or defer recording to commit.
3. Ledger (SM-4): store the membership scope with each ledger day, or compute the baseline over the same item set.

## State machines

Notation: "Inv" lists invariants; a transition row ends with the invariant it breaks (`BREAKS Mx-n`) or `ok`. Rows marked BREAKS are the ones behind a bug id above. All persistence is `UserDefaults.standard` unless noted. There are no widget, watch or backend targets in this repo (`project.yml` has Bridge, BridgeTests, BridgeScreenshots, BridgeUITests only; no server code beyond the FeedbackService POST to the shared Supabase table).

### M1 Membership (SubscriptionService)

State is spread over `isConfigured`, `membershipResolved`, `entitlementCheckFailed`, `membershipRecovery` (a Task), `isPro`, `isTrialing`, `expirationDate`, `lastCustomerInfoDate`, and the defaults keys `membership.lastSnapshot`, `membership.churnAskSpent`, `membership.pendingChurnMoment`, `membership.reinstallSyncDone` (SubscriptionService.swift:112-123).

Derived states: `Unconfigured` (simulator/no key) / `Unresolved` (configured, no record yet) / `CheckFailed` / `Recovering` (reinstall sync running) / `Free` / `Trial` / `Paid` / `Lifetime`.

Invariants
- M1-1 `isPro` is true only if the newest record seen (by `requestDate`) has the `Bridge+` entitlement active (or the DEBUG override).
- M1-2 No purchase is sold while `!membershipResolved`, while `Recovering`, or while `isPro` (SubscriptionService.swift:403-407).
- M1-3 "Not a member" is never read as a lapse before `membershipResolved` (:483-492, fresh-baseline rule).
- M1-4 One churn ask per departure; a return clears a queued ask (:496-508).

| From | Event | To | Inv |
|---|---|---|---|
| Unresolved | cached record applied (`start`) | Free/Trial/Paid/Lifetime, resolved | ok |
| Unresolved | fetch fails | CheckFailed (buttons stay disabled until a later `loadOfferings`/`ensureOfferings` re-reads, :332-336) | ok (BR-01 fix is covered by existing tests) |
| Any | record with `requestDate` older than last seen | ignored (:451) | ok (tested) |
| Free | StoreKit owns entitlement, RC does not (reinstall) | Recovering then Paid; flag stored only after a successful sync (:231) | ok |
| Free | purchase result | Trial or Paid; `startedTrial` read from `periodType` (:418) | ok |
| Paid/Trial | `isPro` true to false while Home is mounted | Home turns Game Night reminder off (HomeView.swift:141-148) | ok |
| Paid/Trial | process starts with a record that is already not a member (restored defaults, new RC user, or RC reporting an expired cached record) | Free with no `isPro` change | BREAKS M5-4 (SM-3) |
| Paid | Restore/purchase of a plan | no upgrade path for a member: `purchase` returns `.purchased` when `isPro` (:406) and Paywall self-dismisses on `isPro` (PaywallView.swift:357) | product call P1 |

### M2 Purchase flow (OnboardingView trial page, PaywallView)

State: `purchasing`, `restoring`, `trialEligible` (@State, default false), `showPaywallFallback`, `purchaseError`; service side as M1.

Invariants: M2-1 the CTA wording and disclosure always match the plan bought (onboarding: monthly; paywall: selected). M2-2 a cancel is an outcome, never an error or a second paywall. M2-3 a changed eligibility answer redraws and returns without charging (OnboardingView.swift:622-626, PaywallView.swift:480-482).

| From | Event | To | Inv |
|---|---|---|---|
| idle | tap CTA, member | `startTour` | ok |
| idle | tap CTA, `ensureOfferings` finds member (reinstall) | `startTour` | ok |
| idle | tap CTA, recovery still running after 3s | alert "Still checking", no sale | ok |
| idle | no package | paywall fallback sheet; dismiss with `isPro` calls `startTour` (:664) | ok |
| idle | eligibility differs from drawn state | redraw, return | ok |
| purchasing | user cancels sheet | idle | ok |
| purchasing | purchased, entitlement not yet visible | `confirmEntitlement` x3 (1.2 s apart), then alert "Give it a moment, then tap Restore" | ok |
| purchasing | Ask to Buy / pending | RC throws; alert shows RC text; later delegate update flips `isPro` and the paywall self-dismisses, but the onboarding trial page has no `isPro` observer to advance (title and CTA switch to "Continue") | ok (user taps Continue) |
| any | `loadOfferings` runs | `introEligibility` reset to `[:]` then refilled (:335-340): trial copy flickers to "Join Bridge+" for the duration | cosmetic |

### M3 Churn ask (inside M1)

State: snapshot (`membership.lastSnapshot`), `churnAskSpent`, `pendingChurnMoment`, Home's `churnPrompt`.

Invariants: M3-1 at most one pending moment; M3-2 spent flag set when queued, cleared only by `resetsAsk` (active and renewing after not being so); M3-3 shown only on a bare Home.

| From | Event | To | Inv |
|---|---|---|---|
| none | active to inactive, or renewal on to off, not spent | pending + spent | ok |
| pending | member returns before Home asks | pending cleared, spent cleared | ok (tested) |
| pending | Home bare 0.9 s | shown, pending cleared | ok |
| spent | trial renewal off, then trial lapses | no second ask (one per departure) | documented |
| spent | cancelled-but-active subscription restored with `willRenew` false | spent flag stays | ok (does not reset; low) |

### M4 Onboarding and first-run (OnboardingView, FeatureTourView, HowToPlayView, RootView)

State: `page` 0-4, `stage` pages/howToPlay/tour, `skillLevel`, `progress.hasOnboarded`, `sessionsAtOnboarding`, `whatsnew.lastSeenVersion`, `bridge.hasReadPrimer`, `bridge.recommendedRoomHint`. Only `hasOnboarded` (written by `finish`, :676) survives a kill; `page` and `stage` are @State, so a kill during the primer or tour restarts at page 0.

Invariants: M4-1 a swipe cannot pass the skill page without a choice (OnboardingView.swift:111). M4-2 the tour's practice does not count toward Home extras (`sessionsAtOnboarding`). M4-3 a fresh install never sees What's New (`markCurrentAsBaseline`).

| From | Event | To | Inv |
|---|---|---|---|
| pages 0-3 | Continue / swipe | next page | ok |
| page 4 | Get Started or purchase | howToPlay (skill "new") or tour | ok |
| howToPlay | Skip | `finish()` (skips the tour) | ok (documented) |
| tour | done | `finish()` | ok |
| any stage | app killed | page 0 again, even for a member (CTA reads "Continue") | ok |
| any | notification routed while not onboarded | `pendingDestination` waits; consumed when Home first appears, so a first-launch Game Night tap opens a session straight after the tour | low |

### M5 Reminders (AppSettings, AppDelegate, HomeView router)

State has four parts that nothing keeps equal: the two persisted toggles (`settings.reminderEnabled`, `settings.gameNightReminderEnabled`), the pending request ids (`bridge.dailyReminder`, `bridge.gameNightReminder`) in the system, iOS authorization, and `reminderPermissionDenied` (one flag shared by both reminders and bound to two alerts).

Invariants
- M5-1 toggle on implies a pending request exists.
- M5-2 toggle off implies no pending request.
- M5-3 toggle on implies authorization was granted at the time of the last schedule.
- M5-4 Game Night toggle on implies Bridge+ (it is the only way to reach the toggle).

Scheduler call sites (complete list, `grep scheduleReminder|scheduleGameNightReminder|requestAuthorization|removePending`): AppSettings.swift:84 (cancel daily), :99 (daily reschedule on time change, only when toggle on), :109 (cancel game night), :117 (game night reschedule on day change), :126 (on time change), :164-170 (daily request, schedules on grant, turns toggle off on denial), :176-189 (schedule daily), :191 (cancel daily), :199-205 (game night request), :211-229 (schedule game night), :231 (cancel game night). There is no call from `init`, `BridgeApp`, `AppDelegate.didFinishLaunching`, or a scene-phase handler, and no `getNotificationSettings` or `getPendingNotificationRequests` anywhere.

| From | Event | To | Inv |
|---|---|---|---|
| off | toggle on, grant | on + pending | ok |
| off | toggle on, deny | toggle forced off, alert | ok |
| on | time/day change | reschedule | ok |
| on | toggle off | cancel | ok |
| on | relaunch | no reconcile; toggle on, pending whatever the system holds | BREAKS M5-1 (SM-1) when pending is empty (backup restore, iOS dropping pending requests, kill during the permission sheet) |
| on | iOS Settings turns notifications off | toggle stays on, no banner | BREAKS M5-3 (product call P2) |
| on (game night) | `isPro` flips true to false in a running Home | toggle off, cancel | ok |
| on (game night) | first record of the process says not a member | toggle stays on, request stays pending, toggle unreachable | BREAKS M5-4 (SM-3) |
| on | notification fires after the player already practiced today | static text fires anyway | product call P3 |
| tap | game night banner | `AppRouter.pendingDestination = .gameNightPrepSession` -> Home `path = [destination]` (HomeView.swift:271-290); non-member gets the paywall | ok |
| tap | banner while a drill is open (foreground banner is enabled, AppRouter.swift:75) | the open drill is replaced; unfinished session is not recorded | product call P4 |

### M6 Router and upgrade intent (AppRouter, HomeView)

State: `AppRouter.pendingDestination`, Home `path`, `showPaywall`, `pendingAfterUpgrade`, `membershipWaitOver`.

Invariants: M6-1 a locked destination survives the paywall only if the player became a member (`UpgradeIntent.consume`). M6-2 a member opening a notification cold waits up to 4 s for the first record before being sold a paywall.

| From | Event | To | Inv |
|---|---|---|---|
| pending | Home appears / pending changes / membership resolves | `consumePendingDestination` | ok |
| pending | not resolved | wait 4 s, then fall back to member check | ok |
| non-member | locked destination | `pendingAfterUpgrade` set, paywall | ok |
| paywall | dismissed without upgrade | intent consumed and cleared | ok (tested) |
| any sheet open (Settings, What's New) | route arrives | `showPaywall = true` while another sheet is up; SwiftUI cannot present it, `pendingAfterUpgrade` stays armed | unverified (cannot be run here; settle on a device by tapping a game night banner for a lapsed player while Settings is open) |

### M7 Streak and the daily Get Started (ProgressStore)

State: `progress.streakCount`, `progress.lastActiveDay` (day key string, or legacy Date), `progress.lastQuickSessionDay`, `totalSessions`, `completions`.

Invariants: M7-1 `streakCount` counts consecutive local calendar days with a finished session. M7-2 `currentStreak` reads 0 once a day is missed. M7-3 Get Started rests for the rest of the local day.

| From | Event | To | Inv |
|---|---|---|---|
| any | `recordSession` same day | unchanged | ok |
| any | next day | +1 | ok |
| any | gap > 1 | 1 | ok |
| any | clock/zone goes backwards (gap < 0) | session counted, streak not touched (ProgressStore.swift:88-91) | ok (documented) |
| Home on screen | midnight passes while backgrounded | `quickSessionCompletedToday()` and `currentStreak()` are read in `body`; nothing invalidates Home at midnight, so the card/chip can show yesterday's state until another published value changes | low (unverified, P5) |
| session | started before midnight, finished after | credits the day of the finish | ok |

### M8 Practice record, mastery, weekly ledger (PracticeRecordStore, Mastery, MasteryLedger)

State per item: `attempts, correct, streak, dueDate, intervalDays, ease, reviewSuppressed`. Mastery `known` = `streak >= 2` and not a full interval past due. Ledger: one `[room: known]` row per local day, 60 days kept.

Invariants: M8-1 one `record` call per graded answer the player stands behind. M8-2 `needsReview` = ever missed and fewer than two right in a row. M8-3 `weeklyGain` = questions locked in during the last 7 days. M8-4 a day's ledger row measures the same set of items as the baseline row.

| From | Event | To | Inv |
|---|---|---|---|
| item | answer in a quiz/hand-match/play/choice card | `record` (+1 attempt) | ok |
| item | flashcard Undo | queue rewound, record untouched; next answer records again | BREAKS M8-1 (SM-2) |
| ledger | Home appears / record count changes / membership resolves | today's row rewritten | ok |
| ledger | membership changes between two ledger days | totals measure different item sets | BREAKS M8-4 (SM-4) |
| ledger | unresolved membership | no write (HomeView.swift:222-227) | ok |
| all | Reset Progress | records, ledger, minute results, progress cleared; reminders and prompts untouched | ok |

### M9 Flashcard deck (FlashcardDrillView)

State: `queue`, `isFlipped`, `drag`, `isFlinging`, `choicePick`, `lastSwipe` (one level), `finished`, `flingOpacity`.

Invariants: M9-1 only a flipped card can be swiped. M9-2 a choice card is graded once, at pick. M9-3 Undo returns the deck and the grading to the state before the last card.

| From | Event | To | Inv |
|---|---|---|---|
| front | tap | flipped | ok |
| front (choice card) | pick | graded (progress + record), flipped | ok |
| flipped | swipe | `commit`: grade (plain cards), `lastSwipe` set, card removed or requeued | ok |
| any after a swipe | Undo | queue.insert at 0, `choicePick = nil`, flipped false; `ProgressStore` and `PracticeRecordStore` unchanged | BREAKS M9-3 / M8-1 (SM-2) |
| last card | swipe | finished (Undo button gone, `lastSwipe` unreachable) | ok |
| mid-fling | Undo | ignored (`!isFlinging`) | ok |

### M10 Practice runs (PracticeRunView) and Quick Session

State: `items, index, selection, attempted, score, finished, secondsRemaining`.

Invariants: M10-1 a run with no answers closes without a result or a streak credit. M10-2 the Timed Challenge ends at 0 s.

| From | Event | To | Inv |
|---|---|---|---|
| run | Finish with 0 answers | dismiss | ok |
| run | Finish with answers | `DrillCompleteView`, `recordSession` once (`recorded` guard) | ok |
| timed | app suspended | clock is a `Task.sleep` loop (:236-244); behaviour across suspension not verified | unverified |
| timed | 0 s with a question open | `finish()`; unanswered question not counted | ok |
| quick session | abandoned mid-way | answers already recorded individually; no session credit, Get Started not spent | ok |

### M11 Bridge Minute (BridgeMinuteStore, BridgeMinuteView)

State: `results[dayKey]`, first write wins (`record` returns the existing result, BridgeMinuteStore.swift:59). Week count uses `completedAt`, the day key uses the challenge's day.

| From | Event | To | Inv |
|---|---|---|---|
| day not played | finish | result stored under the challenge day, `completedAt` = now | ok |
| started 23:58, finished 00:03 | | stored under yesterday; today still shows "Start" | low |
| archive day | finish | counts toward this week ("catch up from the archive") | documented |
| any | Reset Progress | results removed | ok |

### M12 Presentation arbiter (HomeView.homeIsBare)

What's New, the churn question and the rating prompt each wait for a bare Home (`homeIsBare`, HomeView.swift:243). What's New marks itself seen before it is shown (:298-310), so a kill in the 0.5 s window loses it (low). The churn moment is stored, so a kill loses nothing.

### M13 Rating prompt (ReviewPromptTracker, ReviewRequest)

State: `launchCount`, `lastShown`, `outcome`. `markShown` is written before `requestReview()` (ReviewRequest.swift), so a swallowed Apple prompt still burns the 30-day cooldown (documented: "a call it swallows costs nothing" is about the player, not the cooldown).

### M14 Feedback queue (FeedbackService)

State: `feedback.pending` array (cap 20), `isFlushing`. Rows leave only after the server answers; a flush suspended by app suspension that already got a 2xx but did not persist the removal re-sends that row next launch (duplicate feedback row, low, unverifiable offline).
