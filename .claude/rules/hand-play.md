---
paths:
  - "Shared/Content/HandPlayEngine.swift"
  - "Shared/Content/HandPlayContent.swift"
  - "Shared/Services/HandPlayStore.swift"
  - "Bridge/Views/Drills/HandPlayView.swift"
  - "BridgeTests/HandPlayEngineTests.swift"
---

# Bridge Trainer: Play a Hand (2026-11-23, ships in 1.3.1)

Design: `project-docs/design/2026-11-23-play-a-hand.md`.

## Shape

- The player is South, always declarer, and plays South and dummy. Deals are
  authored (`HandPlayContent.deals`), each with a full 13-trick line; defenders
  play the line, there are no bots.
- South's coached calls are graded by the engines, never by authored answers:
  openings by `HandGenerator.opening`/`missNote`/`explain`, rebids by
  `BiddingEngine.call`/`missNote`/`explain`. `testCoachedCallsAgreeWithTheEngines`
  holds this.
- Card decisions are authored per (trick, seat) as `PlayDecision`. Every other
  card auto-plays. A wrong card is never played: the miss shows the coach's card
  with a "Why not X?" note and the coach's card goes down, so the line stays true.
- A card counts as right when it is the coach's card, an `alsoFine` card (graded
  right, coach's card still played) or line-equivalent: same hand and suit, the
  swapped line wins every trick for the same seats, and no defender then passes
  up a trick they could win (`defenderPassesUpWinner`). Without that last check
  the A♥ passed for the Q♥ finesse.

## Adding a deal

1. Hands and tricks are suit-first strings ("♠AKT64", "♠K"; T is ten, "-" a
   void). Prose in reasons and notes is rank-first ("A♣"), matching the cards.
2. Run `HandPlayEngineTests`: every card used once, the line legal and making,
   each decision reached with at least one wrong card, also-fine cards legal.
3. Every title, reason and note goes into `Localizable.xcstrings` in all 15
   languages (`LocalizationTests` collects them from `HandPlayContent.deals`).

## Access and state

- Free players get one whole hand per calendar day, spent at the first save
  (the first call). Members are unlimited. `AppDestination.playHand.isFree`.
- `HandPlayState` is Codable and saved after every step, so a back-swipe or a
  killed app resumes the hand. Finishing rotates `nextDeal`.
- DEBUG `-handplay.reset YES` clears all `handplay.*` keys; the gate journey
  `testPlayAHandFreeHand` uses it.
