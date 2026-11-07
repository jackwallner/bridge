---
paths:
  - "Shared/Content/BridgeMinuteContent.swift"
  - "Shared/Services/BridgeMinuteStore.swift"
  - "Bridge/Views/BridgeMinuteView.swift"
  - "Bridge/Views/GameNightPrepView.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Shared/Services/AppSettings.swift"
  - "BridgeTests/BridgeMinuteTests.swift"
  - "BridgeTests/HandGeneratorTests.swift"
  - "Shared/Models/Drill.swift"
  - "Bridge/Views/Drills/QuickSessionView.swift"
  - "Bridge/Views/SettingsView.swift"
  - "Shared/Content/PlayContent.swift"
  - "Bridge/Views/Drills/PlayDrillView.swift"
---

# Bridge Trainer: game-night rhythm

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

## Game-night rhythm (1.2)

Bridge+ owns two recurring rituals. `BridgeMinuteContent` deterministically
builds the same five questions for every member on a local calendar day: two
generated opening calls, one declarer decision, and two defensive judgments.
Results and a 30-day archive stay on device in `BridgeMinuteStore`; sharing uses
the system share sheet and needs no account or leaderboard.

The declarer question is built straight from the authored `PlayScenario`s, NOT
through `SessionBuilder.choiceItems`. The quick-session pool deliberately
excludes Play drills, so drawing the daily from it silently produced a
four-question challenge with no declarer play in it at all.

`GameNightPrepView` stores a weekly bridge night in `AppSettings`, schedules a
local notification, and opens directly into `SessionBuilder.gameNightPrep`,
which prioritizes due mistakes, misses, the weakest room, and unseen member
content in that order. Both features are entirely Bridge+ gated.

## Reminder state (2026-11-06, state machine audit fixes)

The reminder toggles are saved intent, not proof of a pending request.
`AppSettings.reconcileReminders()` runs at launch and on every return to
the foreground: allowed puts any missing request back, an unanswered ask is
asked again, denied keeps the choice so the request returns once iOS allows
it. The Game Night reminder is turned off for a non-member level-triggered,
when `SubscriptionService.membershipConfirmed` turns true, because a stale
cached record of a lapsed member reads as lapsed from the first frame and
`isPro` never changes. Confirmation needs a `.notStaleCachedOrFetched` read
and no failed reinstall sync. `.cachedOrFetched` returns a stale cache even
online and never counts: a renewed member's old cache reads as lapsed too.
Offline on a stale cache nothing is confirmed. Test fakes must honour the
fetch policy as the SDK does, or a cache-only answer passes as fresh.
