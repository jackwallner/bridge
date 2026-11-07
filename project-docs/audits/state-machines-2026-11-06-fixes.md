# State machine audit fixes, 2026-11-06

Fixes for `state-machines-2026-11-06.md` as corrected by `state-machines-2026-11-06-review.md`, from 4b81122. First pass on branch `fleet/20261106-174331-0577-claude`; second pass on `fleet/20261106-215810-704f-claude` after `state-machines-2026-11-06-verify.md` rejected SM-3. Third pass on `fleet/20261107-021908-e339-claude` after the second verify rejected only the P6 ruling (skipped instead of held).

**Summary: 5 in scope (SM-3, SM-1, SM-2, SM-4 from the review, plus P5, an unverified item settled as reachable). 5 fixed, 0 held, 0 skipped. SM-3 reworked after the first verify rejected it. 4 items held for Jack (product calls P1, P2, P4, and P6, an unverified item whose headless test passes on 4b81122), 3 left alone as the review directs (P3, P7, P8).**

## In-scope claims, in the review's ranked order

| id | outcome | commit subject | regression test | what changed |
|---|---|---|---|---|
| SM-3 | fixed (reworked after the verify) | fix: turn off the Game Night reminder once a launch confirms no membership; fix: confirm membership only on a fresh RevenueCat record | `GameNightMembershipTests` (5 tests) | `SubscriptionService.membershipConfirmed` gates a level-triggered rule: when it turns true, `BridgeApp` calls `AppSettings.enforceGameNightMembership(isMember:)`, which turns the weekly reminder off for a non-member, so a lapsed member whose cached record already reads lapsed (no `isPro` change) loses the reminder at the next launch. Home's edge hook uses the same function. The first pass confirmed after the launch's `.cachedOrFetched` read, which in RevenueCat 5.80.3 returns a stale cache even online, so a renewed member whose old record read lapsed lost the reminder (the verify's route). "fix: confirm membership only on a fresh RevenueCat record" confirms only after a separate `.notStaleCachedOrFetched` read at the end of launch: RevenueCat refetches a stale record, and a failed fetch (offline on a stale cache) leaves it unconfirmed. It also stays unconfirmed when StoreKit holds a current purchase whose reinstall sync failed, which the first pass confirmed through. The launch's existing reads and their order are unchanged. The test fake now honours the fetch policy as the SDK does, and a new test covers the failed reinstall sync. |
| SM-1 | fixed | fix: reconcile switched-on reminders at launch and on return | `ReminderReconcileTests` (3 tests) | `AppSettings.reconcileReminders()` runs at launch and on every return to the foreground. Allowed: puts a missing request back. Not determined (killed during the permission alert): asks again and schedules on a grant, or turns the toggles off on a denial. Denied: keeps the toggle, and the request comes back once iOS allows notifications again. This also covers the review's unproven routes (backup restore, permission cycled) if iOS does drop requests there. |
| SM-2 | fixed | fix: let flashcard Undo retract the grade it undoes | `FlashcardUndoTests` (2 tests) | Undo on a plain card restores the item's `PracticeRecord` and seen/missed state from a snapshot taken before the swipe graded it. Only the final swipe counts, and the retraction persists across a relaunch. A choice card was graded at its pick, before the answer showed. Undo now brings it back answered (pick and answer shown, Next to continue) instead of open to a second, informed pick. Its record then matches the no-Undo path, which the review called defensible spaced repetition. The audit's SM-2 repro test was not kept: the review called it the auditor's preferred design. |
| SM-4 | fixed | fix: compare weekly gain only across days with the same membership | `MasteryLedgerTests` (5 new tests, including the audit's repro, which the review called sound) | Each ledger day also stores whether it counted Bridge+ items (`mastery.ledger.scopes`, a separate key). The weekly baseline is the oldest day in the window measured the same way, so re-subscribing within a week no longer fakes "+N locked in this week". Data upgrade: ledgers saved before this have no scope and compare with any day, which `testALedgerSavedBeforeScopesStillMeasures` covers. Nothing is reset or dropped. |
| P5 | fixed (settled: reachable) | fix: redraw Home when the day changes | `DayChangeRefreshTests` | Settled by code read. Home reads `quickSessionCompletedToday()` and `currentStreak()` against the clock, and no published value, timer or scene-phase hook changes at midnight. A player who finished today's session and reopens the app from memory the next morning saw "Today's session is done. A fresh mix lands tomorrow." `ProgressStore` now sends `objectWillChange` on `UIApplication.significantTimeChangeNotification`, which iOS queues for a suspended app and delivers on return. |

Rules notes: "docs(rules): record the reminder reconcile and ledger scope rules" records the reminder reconcile, the level-triggered Game Night rule and the ledger scope in `.claude/rules/game-night.md` and `.claude/rules/feedback-and-retention.md`. "docs(rules): membership confirmation needs a fresh record" corrects the SM-3 note: confirmation needs a fresh record.

Proof that each test fails without its fix. Every new test calls API that does not exist at 4b81122 (`membershipConfirmed`, `enforceGameNightMembership`, `reminderRepair`, `snapshot`/`restore`/`restoreItem`, `record(_:isMember:now:)`, and the `ProgressStore` observer), so the test target does not compile there. On behaviour:
- SM-4: the audit's repro used the same setup and failed with gain 5 (audit run 42287448922, review run 42299097245).
- SM-3: the review's run showed that `isPro` never turns true for this setup, so the old edge hook could not fire. For the rework, the tests from "fix: confirm membership only on a fresh RevenueCat record" were run against the first pass's `SubscriptionService` (GitHub run 42345133490): 2 passed, 3 failed, the renewed member (reminder off), the offline stale cache ("a cache-only answer counted as confirmed") and the failed reinstall sync ("a failed reinstall sync counted as confirmed"). The lapsed-member and successful-sync tests pass on both, as they should.
- P5: without the observer, nothing calls `objectWillChange`, so the expectation times out.

## Verify findings (`state-machines-2026-11-06-verify.md`)

1. Confirm on a network answer, never on the `.cachedOrFetched` read: done in "fix: confirm membership only on a fresh RevenueCat record" (`SubscriptionService.confirmMembership()`, `.notStaleCachedOrFetched`). Offline on a stale cache it stays false.
2. The test fake honours `fetchPolicy`: done. `.cachedOrFetched` returns any cache, `.notStaleCachedOrFetched` refetches one older than five minutes, network answers and syncs replace the cache. With that fake the first pass fails the offline test, as the verify predicted.
3. Doc and rules claims corrected: the SM-3 row above and `.claude/rules/game-night.md` ("docs(rules): membership confirmation needs a fresh record").

Also fixed under the same rule: the first pass confirmed when StoreKit held a current purchase but the reinstall sync failed, so a failed network call could tear the reminder down. Now it stays unconfirmed (`testReinstalledMemberKeepsTheReminderWhenTheSyncFails`).

Not changed: the verify's notes that `ReminderReconcileTests` checks only the mapping, not the launch wiring, and that launch can send two `requestAuthorization` calls. The verify passed SM-1; a notification-center seam would be a refactor outside a bug fix.

Disputed: none.

## Second verify findings

1. Move P6 from Skipped to Held for Jack: done, after settling it with a headless UI test that passes on 4b81122 (see Held for Jack). No code changed in this pass.

## Held for Jack

- P1, a member cannot buy Lifetime from the app. The paywall returns `.purchased` for any member and closes itself. Decision: should a monthly or yearly member be offered Lifetime in the app (a paywall offer change), or does Apple's Manage Subscription stay the only plan-change route?
- P2, notifications turned off in iOS Settings while a reminder toggle is on. After SM-1 the toggle stays on and the reminder returns by itself once notifications are allowed again. No banner says it is currently silent. Decision: keep that, or switch the toggle off (or show a note in Settings) while iOS denies notifications?
- P4, tapping a foreground Game Night banner during a drill replaces the open drill, and the unfinished session earns no streak credit. Decision: keep the replace, or suppress the foreground banner (or the jump) while a drill is open?

- P6, one `reminderPermissionDenied` flag bound to two alerts (Settings' root `Form`, `SettingsView.swift:72`, and the pushed Game Night Prep, `GameNightPrepView.swift:37`), both mounted when Game Night Prep is opened from Settings. Settled headless as not failing: the UI test `state-machines-2026-11-06-p6-probe.swift` (launch with `-DuoSeed`, Settings, Game Night Prep, switch on the weekly reminder, Don't Allow in the iOS prompt) passes on 4b81122 (GitHub run 42363608416, Xcode 27.1, iPhone 17, iOS 27.2). Exactly one "Notifications are off" alert appears, one Not now dismisses it, none comes back within 3 s, and Game Night Prep stays open. So no fix was made, and the probe is kept beside the audit rather than in a test target, since it guards no fix. What would still settle it: the same steps on a device or simulator at the deployment floor (iOS 17), where SwiftUI's handling of two alerts on one binding may differ. Decision: keep both alerts, or drop the pushed view's copy anyway (Home's own Game Night Prep push would then need its own alert)?

## Skipped

None.

Left alone, as the review directs: P3 and P8 (documented rules), P7 (the review found no kill window).

## Test results

- Focused run, GitHub run 42326249944 (Xcode 27.1, iPhone 17, iOS 27.2): 52 passed, 0 failed, 0 skipped. It covered every new test plus `MasteryLedgerTests`, `PracticeRecordStoreTests` and `ProgressStoreTests`.
- Full suite, first pass, GitHub run 42331288987 (Xcode 27.1, iPhone 17, iOS 27.2): 183 passed, 0 failed, 0 skipped.
- SM-3 revert proof, GitHub run 42345133490: 3 of 5 `GameNightMembershipTests` fail without that commit (above).
- Full suite after the rework, `gh-sim test --scheme Bridge`, GitHub run 42349294755 (Xcode 27.1, iPhone 17, iOS 27.2): 184 passed, 0 failed, 0 skipped (183 plus the new sync-failure test). No test failed, so none needed a rerun on 4b81122, and none already failed there.

- Second verify (`state-machines-2026-11-06-verify.md`), full suite on the reworked HEAD, GitHub run 42352503931: 184 passed, 0 failed, 0 skipped.
- P6 probe on 4b81122, `gh-sim test --scheme BridgeUITests --only BridgeUITests/GameNightDeniedAlertUITests`, GitHub run 42363608416: 1 passed, 0 failed.
- Third pass, full suite on this branch (no code change since the rework), `gh-sim test --scheme Bridge`, GitHub run 42367180889 (Xcode 27.1, iPhone 17, iOS 27.2): 184 passed, 0 failed, 0 skipped. No test failed, so none needed a rerun on 4b81122, and none already failed there.

The audit's repro suite was never added to the test target (it stays in `state-machines-2026-11-06-repro.swift`, outside the target).
