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

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

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
