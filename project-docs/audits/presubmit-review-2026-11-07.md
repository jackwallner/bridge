# Pre-submit review: Bridge 1.2.8 (2026-11-07)

Scope: every app source change from the live version (1.2.7, build 37, parent of `d98155d` "chore: bump version to 1.2.8", `aaefef4`) to `origin/main` `f0ff663` (1.2.8, build 40). App sources only: `Bridge/`, `Shared/`, `Info.plist`, `project.yml`. That covers the Language row in Settings and the state machine audit fixes (reminder reconcile, Game Night membership enforcement with `membershipConfirmed`, flashcard Undo retraction, weekly gain scope, the day-change redraw).

Checked, in order: crashes and data loss, purchase and paywall paths, state bugs, App Review risks.

| Severity | Where | What happens | Status |
|---|---|---|---|
| P1 | `Bridge/Views/Drills/FlashcardDrillView.swift:386` | Answer a choice card (graded at the pick), then tap Undo, which rewinds the card before it. Undo cleared the pick but kept its grade, so the choice card came back unanswered and its next pick was a second graded attempt: two attempts in Your Progress and the review queue, and a wrong first pick could leave the card in the missed set. The 1.2.8 Undo fix covered only the undone card itself. | Fixed (`fix: retract a choice card's pick when Undo drops it`). The pick now snapshots the card's grade state and Undo retracts it with the pick. Test: `FlashcardUndoTests.testUndoAfterAChoicePickCountsOnlyTheRepick` replays the store calls of the route; the view state itself is checked by code read, as the existing Undo tests do. |
| P2 | `Shared/Services/AppSettings.swift:183` | `reconcileReminders()` (new, runs at every launch and foreground with a reminder on) reads `getNotificationSettings` in a completion closure formed on the main actor. Under Swift 6, if the SDK did not mark that handler `@Sendable`, the closure would be inferred main-actor isolated and trap when iOS calls it on its own queue, crashing every launch for a player with a reminder on. | No fix needed if the new test passes: `ReminderReconcileTests.testReconcileReadsTheSettingsWithoutAnIsolationTrap` runs the real call on the simulator. The same pattern (`requestAuthorization`) has shipped since 1.0. |

No finding in the rest of the diff:

- Purchase and paywall: no change to offerings, packages, restore, trial copy or `PaywallView` since 1.2.7. `membershipConfirmed` only gates the Game Night reminder switch-off, never `isPro`, so it cannot lock out or unlock anyone. Terms and Privacy links are unchanged.
- `MasteryLedger` scopes decode with a fallback to empty, so old saved ledgers load. `PracticeRecordStore.snapshot/restore` key the same row as `record`.
- `ProgressStore`'s significant time change observer runs on the main queue, so `MainActor.assumeIsolated` holds.
- Reminder rescheduling reuses fixed identifiers, so repeated reconciles never stack notifications. The Game Night switch-off and the reconcile both run on the main actor and re-read the toggle, so a confirmed non-member's reminder is not put back.
- Language row: opens the app's own iOS Settings page (`openSettingsURLString`), and its two strings are in all 16 languages. No debug UI, hard-coded prices, links to other platforms or health claims were added.

Tests: see the commit that adds this report for the gh-sim run.
