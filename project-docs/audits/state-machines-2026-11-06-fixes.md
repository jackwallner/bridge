# State machine audit fixes, 2026-11-06

Fixes for `state-machines-2026-11-06.md` as corrected by `state-machines-2026-11-06-review.md`, on branch `fleet/20261106-174331-0577-claude` from 4b81122.

**Summary: 5 in scope (SM-3, SM-1, SM-2, SM-4 from the review, plus P5, an unverified item settled as reachable). 5 fixed, 0 held, 0 skipped. 3 product calls held for Jack (P1, P2, P4), 1 unverified product call skipped (P6), 3 left alone as the review directs (P3, P7, P8).**

## In-scope claims, in the review's ranked order

| id | outcome | commit | regression test | what changed |
|---|---|---|---|---|
| SM-3 | fixed | 6cac423 | `GameNightMembershipTests` (4 tests) | `SubscriptionService.membershipConfirmed` turns true once a launch has heard RevenueCat itself (not only the cache) and any reinstall sync is done. `BridgeApp` then calls `AppSettings.enforceGameNightMembership(isMember:)`, which turns the weekly reminder off for a non-member. This rule is level-triggered, so a lapsed member whose cached record already reads lapsed (no `isPro` change) loses the reminder at the next launch. Home's edge hook uses the same function. The rule never acts on the cache alone, because a renewed member's stale cache can read as lapsed too. It also never acts offline or before a reinstall sync answers. Tests cover all three of those cases. |
| SM-1 | fixed | 8d0e2da | `ReminderReconcileTests` (3 tests) | `AppSettings.reconcileReminders()` runs at launch and on every return to the foreground. Allowed: puts a missing request back. Not determined (killed during the permission alert): asks again and schedules on a grant, or turns the toggles off on a denial. Denied: keeps the toggle, and the request comes back once iOS allows notifications again. This also covers the review's unproven routes (backup restore, permission cycled) if iOS does drop requests there. |
| SM-2 | fixed | 65bf6ca | `FlashcardUndoTests` (2 tests) | Undo on a plain card restores the item's `PracticeRecord` and seen/missed state from a snapshot taken before the swipe graded it. Only the final swipe counts, and the retraction persists across a relaunch. A choice card was graded at its pick, before the answer showed. Undo now brings it back answered (pick and answer shown, Next to continue) instead of open to a second, informed pick. Its record then matches the no-Undo path, which the review called defensible spaced repetition. The audit's SM-2 repro test was not kept: the review called it the auditor's preferred design. |
| SM-4 | fixed | 819b075 | `MasteryLedgerTests` (5 new tests, including the audit's repro, which the review called sound) | Each ledger day also stores whether it counted Bridge+ items (`mastery.ledger.scopes`, a separate key). The weekly baseline is the oldest day in the window measured the same way, so re-subscribing within a week no longer fakes "+N locked in this week". Data upgrade: ledgers saved before this have no scope and compare with any day, which `testALedgerSavedBeforeScopesStillMeasures` covers. Nothing is reset or dropped. |
| P5 | fixed (settled: reachable) | d69684f | `DayChangeRefreshTests` | Settled by code read. Home reads `quickSessionCompletedToday()` and `currentStreak()` against the clock, and no published value, timer or scene-phase hook changes at midnight. A player who finished today's session and reopens the app from memory the next morning saw "Today's session is done. A fresh mix lands tomorrow." `ProgressStore` now sends `objectWillChange` on `UIApplication.significantTimeChangeNotification`, which iOS queues for a suspended app and delivers on return. |

Rules notes: 573e9cb records the reminder reconcile, the level-triggered Game Night rule and the ledger scope in `.claude/rules/game-night.md` and `.claude/rules/feedback-and-retention.md`.

Proof that each test fails without its fix. Every new test calls API that does not exist at 4b81122 (`membershipConfirmed`, `enforceGameNightMembership`, `reminderRepair`, `snapshot`/`restore`/`restoreItem`, `record(_:isMember:now:)`, and the `ProgressStore` observer), so the test target does not compile there. On behaviour:
- SM-4: the audit's repro used the same setup and failed with gain 5 (audit run 42287448922, review run 42299097245).
- SM-3: the review's run showed that `isPro` never turns true for this setup, so the old edge hook could not fire.
- P5: without the observer, nothing calls `objectWillChange`, so the expectation times out.

## Held for Jack

- P1, a member cannot buy Lifetime from the app. The paywall returns `.purchased` for any member and closes itself. Decision: should a monthly or yearly member be offered Lifetime in the app (a paywall offer change), or does Apple's Manage Subscription stay the only plan-change route?
- P2, notifications turned off in iOS Settings while a reminder toggle is on. After SM-1 the toggle stays on and the reminder returns by itself once notifications are allowed again. No banner says it is currently silent. Decision: keep that, or switch the toggle off (or show a note in Settings) while iOS denies notifications?
- P4, tapping a foreground Game Night banner during a drill replaces the open drill, and the unfinished session earns no streak credit. Decision: keep the replace, or suppress the foreground banner (or the jump) while a drill is open?

## Skipped

- P6, one `reminderPermissionDenied` flag bound to two alerts (Settings and Game Night Prep, both mounted when Game Night is opened from Settings). Not a customer-visible bug. The two alerts are identical: same title, message, buttons and binding (`SettingsView.swift:72-81`, `GameNightPrepView.swift:37-46`), so whichever one SwiftUI presents, the player sees the same alert, and dismissing it clears the shared flag for both.

Left alone, as the review directs: P3 and P8 (documented rules), P7 (the review found no kill window).

## Test results

- Focused run, GitHub run 42326249944 (Xcode 27.1, iPhone 17, iOS 27.2): 52 passed, 0 failed, 0 skipped. It covered every new test plus `MasteryLedgerTests`, `PracticeRecordStoreTests` and `ProgressStoreTests`.
- Full suite, `gh-sim test --scheme Bridge`, GitHub run 42331288987 (Xcode 27.1, iPhone 17, iOS 27.2): 183 passed, 0 failed, 0 skipped. No test failed, so none needed a rerun on 4b81122, and none already failed there.

The audit's repro suite was never added to the test target (it stays in `state-machines-2026-11-06-repro.swift`, outside the target).
