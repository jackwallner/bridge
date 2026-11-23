---
paths:
  - "Shared/Content/HandGenerator.swift"
  - "Shared/Content/BiddingEngine.swift"
  - "Shared/Content/BiddingContent.swift"
  - "BridgeTests/BiddingEngineTests.swift"
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

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

## Generated practice (1.1)

The authored sets are finite, so a motivated player exhausted Bridge+ in two
sittings and then paid for nothing new. 1.1 answers that with three Bridge+
modes on Home under TRAINING, all run by `PracticeRunView` (Endless / Timed /
Review) on the existing `QuickItem` shape:

- **Endless Practice** (`HandGenerator` + `EndlessPractice`) deals hands
  procedurally, forever. The opening bid is a deterministic function of points
  and shape, so `HandGenerator.opening` grades it, following the ACBL SAYC:
  one of a suit takes 13+ points, or 12 by the Rule of 20 (points plus the two
  longest suits reach 20); 1NT is a balanced 15 to 17; the longest suit opens
  first (a five-card major gives way only to a six-card minor), equal length
  opens the higher suit, 4-4 minors open 1D, 3-3 open 1C. It returns nil for
  anything a beginner Standard American table would argue about (20+ HCP,
  11-counts, a 12 outside the Rule of 20, 4-4-4-1 shapes, 15-17 balanced
  holding a five-card major); generation
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
is an upgrader from a pre-1.1 build and does get it. `currentRelease` is the newest entry at or below the running version (see `membership-and-trial.md`). The sheet raises
`onUpgrade` rather than presenting `PaywallView` itself, because a sheet cannot
present another sheet while dismissing.

## Responses and opener's rebid (1.3.0, 2026-11-22)

A paying member asked how to get past the first three Auction Room lessons:
the room only taught the opening bid. `BiddingEngine` grades the next two
calls after a 1♥/1♠ opening, uncontested, unpassed responder, beginner SAYC:
responder's first call (pass, simple raise, limit raise, 1♠ over 1♥, 1NT,
two-level new suit) and opener's rebid after a raise, after 1♥-1♠ and after
1♠-1NT (minimum hands only outside the raise). Like `HandGenerator`, it
returns nil for anything a SAYC teacher would argue about: 13+ responding
hands, a 10-count without support, 3 hearts beside 4 spades, limit raises
on three trumps, four hearts beside a four-card minor over 1♠, opener's
raise of 1♠ with shortness (support points reach a jump raise), seven-card
or six-plus-singleton minimums after a raise, and any rebid where plain
high-card points, length points and shortness points land in different
ranges. A rebid question also requires the hand to open that major by
`HandGenerator.opening`, so a rebid never rests on an opening the app would
not grade. Two free quiz drills (`respond-to-partner`, `opener-rebid`) come
from `BiddingContent`, and `BiddingEngineTests.testAuthoredQuestionsMatchTheEngine`
holds every authored answer to the engine. Endless Practice gained two
Bridge+ skills (`responses`, `rebids`); the Timed Challenge mixes them in.
A Sonnet teacher review (2026-11-22) drove the guards above; its one claim
that 1♠-1NT-2♥ is a reverse was wrong (hearts rank below spades) and was
not applied.

## Miss notes on opening questions (2026-11-22)

Ported from Mahj's `MissNoteCard`: a wrong opening pick shows "Why not X?"
under the gold explanation. `HandGenerator.missNote(picked:answer:)` derives the
line from the same rules `opening` grades by (pass versus open, 1NT versus a
suit, then the picked suit's length rule), so no hand needs authoring. It covers
Name Your Opening, Endless and Timed openings, the Quick Session and the Bridge
Minute. `QuickItem.choiceNotes` carries the notes and `SessionBuilder.prepared`
shuffles them with the labels. `MissNoteTests` checks every suit note against
the cards directly: a note that states a rule the hand actually meets would teach
the wrong thing.

Responding and rebid questions carry notes too: `BiddingEngine.missNote(picked:answer:in:)`
states what the picked call needs, with the engine's earlier priorities folded in
("Without four spades, rebidding 2♥ promises six or more hearts"), so any hand
the engine grades fails the note for every other candidate. Endless and Timed
responses and rebids, the two authored bidding quizzes (`QuizQuestion.choiceNotes`,
mapped through the quiz shuffle in `QuizDrillView`) and the Quick Session pool
use them. `BiddingEngineTests.testEveryWrongCallHasANoteTheHandFails` checks each
note against a predicate written from its words, over dealt hands for every
situation and answer. Change a note's wording and its predicate together.
