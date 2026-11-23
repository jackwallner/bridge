# Play a Hand: first slice (2026-11-23)

Coached play of a whole deal, from the first call to the last trick. Mahj's
Play a Hand (`~/mahj/.claude/rules/rituals-and-hand-play.md`) is the reference:
grading the player can check, ties never marked wrong, one free hand a day.

## Scope

- **Seat.** The player is South and always declares. Declarer plays both South
  and dummy (North), which is how real bridge works, so every coached card
  decision is the player's. Defense comes in a later slice.
- **Deals are authored, not generated.** Grading a card needs a defensible
  right answer, and Bridge has no double-dummy solver. Each deal is a full
  52-card layout with an auction and a complete 13-trick line that a strong
  player would take. Defenders play the authored line too: no bots, so no
  "the computer cheats" complaint (Mahj's reason for having none).
- **Four deals**, one lesson each: hold up in 3NT, draw trumps in 4♠, ruff a
  loser in dummy before drawing trumps in 4♥, and the finesse in a 2♠ partscore.
- **The auction is played call by call.** South's calls at points the engines
  already grade (the opening, and the rebid after partner's raise) are coached
  by `HandGenerator` and `BiddingEngine` with their existing miss notes.
  Tests keep each authored auction in agreement with those engines, the same
  rule the opening and rebid drills follow. Other calls (partner, the
  opponents, South's last pass) are made by the table.
- **Card decisions.** Each deal names its decision points (three or four per
  deal): opening-lead responses, hold-ups, which suit to lead, when to draw
  trumps, the finesse. At a decision the player taps the card. Every other
  card plays itself at table pace, all thirteen tricks, so the hand is always
  seen through to the last trick.
- **Grading.** Right means the coach's card, or any card in the same hand and
  suit that leaves every trick of the rest of the line won by the same side
  (`HandPlayEngine.isLineEquivalent`, a swap simulation over the authored
  line). A deal can also list `alsoFine` cards: plays that work as well. They
  grade right, with the coach's card then played so the authored line stays
  valid. Anything else shows the coach's card, a "Why not X?" note for that
  card or suit when one is authored, and the reason for the coach's play.
  A wrong card is never played: the coach's card is, so later decisions stay
  true.

## Access

- Free players get one whole hand a calendar day, spent when the first call is
  made, resumable if the app closes mid-hand (Mahj's `HandPlayStore` rule and
  its in-progress lesson). Members play any number.
- The Home tile shows the Bridge+ lock only once a free player has used the
  day's hand; tapping it then opens the existing paywall unchanged.
- No change to onboarding, the trial page, the paywall or the tour. The trial
  page's benefit rows do not mention the mode.

## Build order

1. `HandPlayEngine` and the four deals, with tests for: legal and complete
   lines, auction parse and contract made, engine agreement on South's calls,
   decision points that have a wrong alternative, and line equivalence.
2. `HandPlayStore`: the free-day key, the rotation, and the saved hand.
3. `HandPlayView`: auction, table, coach card, result. A Home training tile.
4. Catalog entries in all sixteen languages, gate, TestFlight.

## Later slices

More deals (target 20), defense from West, generated deals once a small
double-dummy check exists, Fix My Mistakes for missed decisions, and a What's
New item for the version that ships it.
