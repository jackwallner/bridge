# Bridge Trainer vs Mahj reference audit (2026-10-20)

Reference: jackwallner/mahj at ff8242b (cloned read-only to `~/fleet-ref/mahj`). Mahj's frozen conversion flow was not touched. Status: present, missing, unsuitable, incorrect.

## Feature comparison

| Area | Status | Source | Notes |
|---|---|---|---|
| Endless original practice | Present | `Shared/Content/HandGenerator.swift`, `EndlessPractice.swift`, `Bridge/Views/EndlessPickerView.swift` | Six `HandCategory` answers, rejection-sampled so exactly one answer is defensible. `HandGeneratorTests.testAuthoredHandsMatchTheClassifier` ties authored drills to the same engine. |
| Fix My Mistakes / spaced review | Present | `PracticeRecordStore.reviewQueue()`, `PracticeRunView` | SM-2-like; leaves queue after two right in a row. |
| Timed challenge | Present | `PracticeRunView(mode: .timed)`, `bestChallengeScore` | 90 seconds, best kept. Bridge+ only, correct for the paid boundary. |
| Daily short practice | Present | `BridgeMinuteContent`, `BridgeMinuteStore`, Home Get Started | Deterministic per local day; declarer question from authored `PlayScenario`s. |
| Game night prep, reminders | Present | `GameNightPrepView`, `AppSettings` | Daily and weekly local notifications, no backend. |
| Room-level stats | Present | `StatsView` | Accuracy per room, free for all. |
| Mastery layer (known = two right in a row, not stale) | Present in data, **missing in UI** | `Shared/Services/Mastery.swift`, `MasteryLedger.swift` | Fully built and tested but only the weekly "+N" chip consumed it. Home rings still counted drills opened, which rewards tapping over learning. |
| Mastery ring on Home rooms | **Missing, now added** | `HomeView.MasteryRing` | Replaces the drills-opened `ProgressRing`. Free players' denominator excludes locked sets. |
| "What is holding" per room | **Missing, now added** | `StatsView.masteryBreakdown` | Accuracy kept below as its own list; the two answer different questions. |
| "Work on" coaching card | **Missing, now added** | `StatsView.workOnCard` | Driven by `roomToWorkOn` (least mastered started room, never a locked or untouched room), links straight into the room. Old accuracy-based weak spot is the fallback before any room is started. |
| Monthly challenge | Unsuitable for this pass | Mahj `MonthlyChallengeContent` | Mahj's rounds are authored per-card-year themes. Bridge would need authored deals with defensible double-dummy-free answers; not inventing content overnight. Left as phase 2 content work. |
| Feedback, churn question, ratings, What's New | Present | `FeedbackService`, `ReviewPromptSheet`, `WhatsNew` | Matches the 5.6.1 policy in AGENTS.md. |
| Reduce Motion | **Missing, now added** | `ConfettiBurst`, `ShineSweep`, `ChoiceList` shake | There were zero `accessibilityReduceMotion` reads in the app. Confetti, shine sweep and the wrong-answer shake now skip under Reduce Motion; text, colour and haptics still carry the result. |
| Large text | Present | `HomeView.roomCard`, `RoomView` use `isAccessibilitySize` layouts | Not re-measured on device in this pass (see limitations). |

## Persona review (source level plus captures)

- Beginner: Get Started session and Card Room are free and uncluttered. The new ring says "New" until something is actually locked in, with no scary zero.
- Experienced player: previously nothing pointed at the weakest room except raw accuracy over 5+ answers. Work-on card now names it and opens it.
- Returning player: mastery lapses a full interval past due, so a weekly player keeps progress; the ledger still reports a gain only when positive.
- Larger text / Reduce Motion: ring caption scales but is capped at 12pt; motion gap fixed above.

## Limitations

No Xcode or simulator on this machine. Build, tests and captures run through `gh-sim`; evidence is in `~/fleet-evidence/shift-cards-bridge-1-1792479733`.
