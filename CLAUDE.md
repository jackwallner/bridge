# Bridge Trainer Project Guide

Bridge Trainer is a contract bridge drill app for newer players. It teaches card basics, Standard American opening bids, declarer play, and defense through short practice sessions. The XcodeGen project and scheme are `Bridge`; runtime checks use a checked-out shared agent-sim group.

## Build and test

```bash
xcodegen generate
UDID=$(agent-sim checkout bridge)
trap 'agent-sim checkin bridge' EXIT
xcodebuild test -project Bridge.xcodeproj -scheme Bridge -destination "id=$UDID"
```

Never open Simulator.app. After app-code pushes, run `./scripts/testflight.sh`.

## Product configuration

- Bundle ID: `com.jackwallner.bridge`
- RevenueCat entitlement: `Bridge+`
- Monthly: `com.jackwallner.bridge.monthly`, $1.99
- Yearly: `com.jackwallner.bridge.yearly`, $9.99
- Lifetime: `com.jackwallner.bridge.lifetime`, $29.99
- Membership name: Bridge+

RevenueCat is deliberately disabled in simulator builds. The public SDK key lives in `Shared/Services/SubscriptionService.swift`. App Store Connect credentials come from `~/.baseball_credentials` and must never be printed or committed.

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

## Architecture

- `Bridge/` contains the SwiftUI app, views, theme, assets, sounds, and StoreKit configuration.
- `Shared/Models/` contains cards, calls, drills, progress, and room models.
- `Shared/Content/` contains all authored lessons and practice questions.
- `Shared/Services/` contains persistence, reminders, review prompting, and subscriptions.
- `BridgeTests/` validates content and persisted state.

Teaching content uses a beginner Standard American framework. Partnership agreements vary, so avoid presenting conventions as universal rules. Do not imply affiliation with ACBL or any other bridge organization.

## Release workflow

Fastlane metadata is under `fastlane/metadata/en-US`. ASC setup and readiness scripts are under `scripts/`. The app uses a warm cream and jade visual system with high-contrast red and black playing cards.

## Subagent delegation
Follow the global CLAUDE.md subagent rules: ask Jack for the model before spawning, spawn at most one at a time unless Jack explicitly approves more, and never allow a subagent to spawn another subagent.

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

## iPad (1.2)

iPad support is free: `TARGETED_DEVICE_FAMILY "1,2"`, portrait and landscape,
adaptive Home columns, drill grids, and readable content widths.

Every drill body is a scroll view, so a question that underfills the viewport
was pinned to the top and left the bottom half of a 13-inch iPad empty.
`CenteringScrollView` centres short content and leaves taller content scrolling
untouched (minHeight, not height). Keep its `maxWidth: .infinity`: a plain
ScrollView centres narrow content for you, an explicitly framed one does not.
The room eyebrow lives INSIDE `QuestionPager` so it centres with the question,
and the flashcard deck is capped at 520pt wide so a card still looks like a
card.

## Screenshots

`scripts/capture-screenshots.sh <udid> <out-dir> [prefix]` drives the real app
through the App Store screens via the `Screenshots` scheme.
`scripts/with-ipad-sim.sh` creates a throwaway 13-inch iPad (App Store iPad
shots must be 2064x2752 and the agent-sim pool has no iPad Pro), boots it
headless, and deletes it on exit:

```bash
./scripts/with-ipad-sim.sh sh -c './scripts/capture-screenshots.sh "$IPAD_UDID" out ipad_'
```

Gotchas baked into the test: the What's New sheet covers Home on the first
launch after a version bump and comes back every time Home reappears, so the
script passes the marketing version in through
`TEST_RUNNER_SCREENSHOT_APP_VERSION` and the test marks it seen; returning to
the root only taps navigation-bar button 0 while a back button is there,
because on Home that button is the Settings gear; and the test never calls
XCTFail, because a failing UI test spends ten minutes collecting simulator
diagnostics first.
