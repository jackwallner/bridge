---
paths:
  - "Shared/Content/HandGenerator.swift"
  - "Shared/Content/EndlessPractice.swift"
  - "Shared/Services/PracticeRecordStore.swift"
  - "Shared/Services/WhatsNew.swift"
  - "Bridge/Views/Drills/PracticeRunView.swift"
  - "Bridge/Views/StatsView.swift"
  - "Bridge/Views/WhatsNewSheet.swift"
  - "BridgeTests/HandGeneratorTests.swift"
  - "BridgeTests/PracticeRecordStoreTests.swift"
  - "Shared/Models/BridgeTopic.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Bridge/Views/Drills/QuickSessionView.swift"
  - "Bridge/Views/HomeView.swift"
  - "Bridge/Views/SettingsView.swift"
---

# Bridge Trainer: generated practice and What's New

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Generated practice (1.1)

The authored sets are finite, so a motivated player exhausted Bridge+ in two
sittings and then paid for nothing new. 1.1 answers that with three Bridge+
modes on Home under TRAINING, all run by `PracticeRunView` (Endless / Timed /
Review) on the existing `QuickItem` shape:

- **Endless Practice** (`HandGenerator` + `EndlessPractice`) deals hands
  procedurally, forever. The opening bid is a deterministic function of points
  and shape, so `HandGenerator.opening` grades it. It returns nil for anything
  a beginner Standard American table would argue about (22+ and 20-21 hands,
  borderline 11-counts, 15-17 balanced holding a five-card major); generation
  is rejection sampling on top, so a hand only reaches a player when exactly
  one of the six `HandCategory` answers is right. `batch` targets the answer
  first, because a purely random deal is a Pass more than half the time.
- **Fix My Mistakes** replays `PracticeRecordStore.reviewQueue()`, an SM-2-ish
  schedule over per-item history. An item leaves the queue after two correct in
  a row, not one.
- **Timed Challenge**: 90 seconds of mixed generated items, best score kept.

`HandGeneratorTests.testAuthoredHandsMatchTheClassifier` cross-checks the
hand-written opening drills against the same engine that grades Endless
Practice. Keep it: it caught `hand-one-diamond` shipping at 14 HCP with an
explanation claiming 16 and an answer of 1NT. If two drills can disagree about
the same shape, the app has lost the player's trust.

`PracticeRecordStore` records EVERY graded answer app-wide (each drill view
calls it alongside `progress.recordItem`). Generated ids are unique per
question, so they collapse onto one per-skill row and never enter the review
queue or the seen/missed sets, which would otherwise grow without bound.
`StatsView` (free for everyone) reads the per-room rollups.

**What's New sheet:** `WhatsNew` + `WhatsNewSheet`, shown once on the first
launch after an update. A FRESH install never sees it: onboarding calls
`WhatsNew.markCurrentAsBaseline()`. An onboarded player with no stored marker
is an upgrader from a pre-1.1 build and does get it. The sheet raises
`onUpgrade` rather than presenting `PaywallView` itself, because a sheet cannot
present another sheet while dismissing.
