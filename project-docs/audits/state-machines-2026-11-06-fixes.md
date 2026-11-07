# State machine audit fixes, 2026-11-06

Fixes for `state-machines-2026-11-06.md` as corrected by `state-machines-2026-11-06-review.md`, from 4b81122. First pass on branch `fleet/20261106-174331-0577-claude`; second pass on `fleet/20261106-215810-704f-claude` after `state-machines-2026-11-06-verify.md` rejected SM-3.

**Summary: 5 in scope (SM-3, SM-1, SM-2, SM-4 from the review, plus P5, an unverified item settled as reachable). 5 fixed, 0 held, 0 skipped. SM-3 reworked after the verify rejected it. 3 product calls held for Jack (P1, P2, P4), 1 unverified product call skipped (P6), 3 left alone as the review directs (P3, P7, P8).**

## In-scope claims, in the review's ranked order

| id | outcome | commit | regression test | what changed |
|---|---|---|---|---|
| SM-3 | fixed (reworked after the verify) | 2d3e310 (6cac423 on the first branch), 62173a2 | `GameNightMembershipTests` (5 tests) | `SubscriptionService.membershipConfirmed` gates a level-triggered rule: when it turns true, `BridgeApp` calls `AppSettings.enforceGameNightMembership(isMember:)`, which turns the weekly reminder off for a non-member, so a lapsed member whose cached record already reads lapsed (no `isPro` change) loses the reminder at the next launch. Home's edge hook uses the same function. The first pass confirmed after the launch's `.cachedOrFetched` read, which in RevenueCat 5.80.3 returns a stale cache even online, so a renewed member whose old record read lapsed lost the reminder (the verify's route). 62173a2 confirms only after a separate `.notStaleCachedOrFetched` read at the end of launch: RevenueCat refetches a stale record, and a failed fetch (offline on a stale cache) leaves it unconfirmed. It also stays unconfirmed when StoreKit holds a current purchase whose reinstall sync failed, which the first pass confirmed through. The launch's existing reads and their order are unchanged. The test fake now honours the fetch policy as the SDK does, and a new test covers the failed reinstall sync. |
| SM-1 | fixed | 7ce668f (8d0e2da on the first branch) | `ReminderReconcileTests` (3 tests) | `AppSettings.reconcileReminders()` runs at launch and on every return to the foreground. Allowed: puts a missing request back. Not determined (killed during the permission alert): asks again and schedules on a grant, or turns the toggles off on a denial. Denied: keeps the toggle, and the request comes back once iOS allows notifications again. This also covers the review's unproven routes (backup restore, permission cycled) if iOS does drop requests there. |
| SM-2 | fixed | 9a5569a (65bf6ca on the first branch) | `FlashcardUndoTests` (2 tests) | Undo on a plain card restores the item's `PracticeRecord` and seen/missed state from a snapshot taken before the swipe graded it. Only the final swipe counts, and the retraction persists across a relaunch. A choice card was graded at its pick, before the answer showed. Undo now brings it back answered (pick and answer shown, Next to continue) instead of open to a second, informed pick. Its record then matches the no-Undo path, which the review called defensible spaced repetition. The audit's SM-2 repro test was not kept: the review called it the auditor's preferred design. |
| SM-4 | fixed | 2d038a6 (819b075 on the first branch) | `MasteryLedgerTests` (5 new tests, including the audit's repro, which the review called sound) | Each ledger day also stores whether it counted Bridge+ items (`mastery.ledger.scopes`, a separate key). The weekly baseline is the oldest day in the window measured the same way, so re-subscribing within a week no longer fakes "+N locked in this week". Data upgrade: ledgers saved before this have no scope and compare with any day, which `testALedgerSavedBeforeScopesStillMeasures` covers. Nothing is reset or dropped. |
| P5 | fixed (settled: reachable) | b14cb14 (d69684f on the first branch) | `DayChangeRefreshTests` | Settled by code read. Home reads `quickSessionCompletedToday()` and `currentStreak()` against the clock, and no published value, timer or scene-phase hook changes at midnight. A player who finished today's session and reopens the app from memory the next morning saw "Today's session is done. A fresh mix lands tomorrow." `ProgressStore` now sends `objectWillChange` on `UIApplication.significantTimeChangeNotification`, which iOS queues for a suspended app and delivers on return. |

Rules notes: e5296c0 (573e9cb on the first branch) records the reminder reconcile, the level-triggered Game Night rule and the ledger scope in `.claude/rules/game-night.md` and `.claude/rules/feedback-and-retention.md`. fb0d98d corrects the SM-3 note: confirmation needs a fresh record.

Proof that each test fails without its fix. Every new test calls API that does not exist at 4b81122 (`membershipConfirmed`, `enforceGameNightMembership`, `reminderRepair`, `snapshot`/`restore`/`restoreItem`, `record(_:isMember:now:)`, and the `ProgressStore` observer), so the test target does not compile there. On behaviour:
- SM-4: the audit's repro used the same setup and failed with gain 5 (audit run 42287448922, review run 42299097245).
- SM-3: the review's run showed that `isPro` never turns true for this setup, so the old edge hook could not fire. For the rework, the tests from 62173a2 were run against the first pass's `SubscriptionService` (GitHub run 42345133490): 2 passed, 3 failed, the renewed member (reminder off), the offline stale cache ("a cache-only answer counted as confirmed") and the failed reinstall sync ("a failed reinstall sync counted as confirmed"). The lapsed-member and successful-sync tests pass on both, as they should.
- P5: without the observer, nothing calls `objectWillChange`, so the expectation times out.

## Verify findings (`state-machines-2026-11-06-verify.md`)

1. Confirm on a network answer, never on the `.cachedOrFetched` read: done in 62173a2 (`SubscriptionService.confirmMembership()`, `.notStaleCachedOrFetched`). Offline on a stale cache it stays false.
2. The test fake honours `fetchPolicy`: done. `.cachedOrFetched` returns any cache, `.notStaleCachedOrFetched` refetches one older than five minutes, network answers and syncs replace the cache. With that fake the first pass fails the offline test, as the verify predicted.
3. Doc and rules claims corrected: the SM-3 row above and `.claude/rules/game-night.md` (fb0d98d).

Also fixed under the same rule: the first pass confirmed when StoreKit held a current purchase but the reinstall sync failed, so a failed network call could tear the reminder down. Now it stays unconfirmed (`testReinstalledMemberKeepsTheReminderWhenTheSyncFails`).

Not changed: the verify's notes that `ReminderReconcileTests` checks only the mapping, not the launch wiring, and that launch can send two `requestAuthorization` calls. The verify passed SM-1; a notification-center seam would be a refactor outside a bug fix.

Disputed: none.

## Held for Jack

- P1, a member cannot buy Lifetime from the app. The paywall returns `.purchased` for any member and closes itself. Decision: should a monthly or yearly member be offered Lifetime in the app (a paywall offer change), or does Apple's Manage Subscription stay the only plan-change route?
- P2, notifications turned off in iOS Settings while a reminder toggle is on. After SM-1 the toggle stays on and the reminder returns by itself once notifications are allowed again. No banner says it is currently silent. Decision: keep that, or switch the toggle off (or show a note in Settings) while iOS denies notifications?
- P4, tapping a foreground Game Night banner during a drill replaces the open drill, and the unfinished session earns no streak credit. Decision: keep the replace, or suppress the foreground banner (or the jump) while a drill is open?

## Skipped

- P6, one `reminderPermissionDenied` flag bound to two alerts (Settings and Game Night Prep, both mounted when Game Night is opened from Settings). Not a customer-visible bug. The two alerts are identical: same title, message, buttons and binding (`SettingsView.swift:72-81`, `GameNightPrepView.swift:37-46`), so whichever one SwiftUI presents, the player sees the same alert, and dismissing it clears the shared flag for both.

Left alone, as the review directs: P3 and P8 (documented rules), P7 (the review found no kill window).

## Test results

- Focused run, GitHub run 42326249944 (Xcode 27.1, iPhone 17, iOS 27.2): 52 passed, 0 failed, 0 skipped. It covered every new test plus `MasteryLedgerTests`, `PracticeRecordStoreTests` and `ProgressStoreTests`.
- Full suite, first pass, GitHub run 42331288987 (Xcode 27.1, iPhone 17, iOS 27.2): 183 passed, 0 failed, 0 skipped.
- SM-3 revert proof, GitHub run 42345133490: 3 of 5 `GameNightMembershipTests` fail without 62173a2 (above).
- Full suite after the rework, `gh-sim test --scheme Bridge`, GitHub run 42349294755 (Xcode 27.1, iPhone 17, iOS 27.2): 184 passed, 0 failed, 0 skipped (183 plus the new sync-failure test). No test failed, so none needed a rerun on 4b81122, and none already failed there.

The audit's repro suite was never added to the test target (it stays in `state-machines-2026-11-06-repro.swift`, outside the target).
