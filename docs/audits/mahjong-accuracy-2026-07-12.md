# American Mah Jongg accuracy audit — 2026-07-12

Scope: every instructional/teaching claim in `Shared/Content/*.swift` plus the
tile/category ground truth in `Shared/Models/Tile.swift` and
`Shared/Models/HandCategory.swift`. 109 individual content items (flashcards,
quiz questions, hand-match questions, Charleston scenarios, How to Play pages)
were checked against authoritative American Mah Jongg rules (NMJL rule
clarifications via Sloperama's FAQ, the back-of-card rules text, and other
established teaching references), plus the two model files.

Verdict legend: **OK** = matches ground truth, no change. **FIXED** = edited
in this pass. **FLAGGED** = left as-is, needs a human/orchestrator call
(none met that bar this pass; see "Flagged" section at the end for the one
soft note).

## Shared/Models/Tile.swift and HandCategory.swift

| Item | Claim | Verdict |
|---|---|---|
| `Dragon.matchingSuit` | Red↔crak, Green↔bam, Soap↔dot | OK — matches NMJL dragon/suit convention |
| `Wind` cases | North, East, West, South | OK |
| `HandCategory` doc comment | "original teaching hands, not card hands" | OK, correctly frames the legal constraint |
| `HandCategory.howToSpot` (all 9 cases) | Year/2468/Like Numbers/Quints/Consecutive Run/13579/Winds & Dragons/369/Singles & Pairs descriptions | OK — all definitions match the stable NMJL section families |

## HowToPlayContent.swift (6 pages)

| id | Claim | Verdict / rationale |
|---|---|---|
| htp-goal | 14-tile hand exactly matches a card line; 13 on rack + 1 drawn/called; declare "mahj" | OK |
| htp-tiles | 3 suits 1-9; craks/bams/dots colors; dragon-suit pairing; flowers bonus; jokers stand in for groups | OK |
| htp-card | Card groups hands into sections | OK |
| htp-charleston | Passes: right, across, left, optional 2nd round; jokers never pass | OK — matches mandatory-first/optional-second order in the brief |
| htp-turn | Call discard for pung/kong/quint; pairs/singles callable only for mahj; concealed can't call except mahj | OK |
| htp-ready | Wrap-up, no factual claims | OK |

## TileBasicsContent.swift (12 flashcards + 16 quiz questions)

| id | Claim | Verdict / rationale |
|---|---|---|
| tiles-craks | 36 craks (1-9 ×4), pairs with Red Dragon | OK |
| tiles-bams | 36 bams, pairs with Green Dragon, "1 Bam is usually a bird" | OK — true trivia about real tile art |
| tiles-dots | 36 dots, pairs with Soap/White Dragon | OK |
| tiles-winds | 16 winds (4×4) | OK |
| tiles-dragons | 12 dragons (4 Red/4 Green/4 Soap), suit pairing | OK |
| tiles-soap | Soap = White Dragon, doubles as zero | OK |
| tiles-flowers | 8 flowers, all interchangeable | OK |
| tiles-jokers | 8 jokers; only in groups of 3+; never pair/single/S&P/Charleston | OK |
| tiles-count | 108 + 16 + 12 + 8 + 8 = 152 | OK — matches ground truth exactly |
| tiles-card | Card lists legal hands; colors mean different suits, not fixed ones | OK |
| tiles-groups | Pair=2, Pung=3, Kong=4, Quint=5 (needs a joker, only 4 of each tile exist) | OK |
| tiles-concealed | X = exposures allowed, C = concealed (still may call the winning tile) | OK |
| quiz-dragon-crak/bam/dot | Dragon-suit pairing quiz | OK |
| quiz-joker-pair | Joker can't complete a pair | OK |
| quiz-joker-charleston | Jokers can never be passed | OK |
| quiz-soap-zero | Soap = zero in year hands | OK |
| quiz-joker-count | 8 jokers | OK |
| quiz-pung | Pung = 3 identical tiles; American mahj has no chow/run calling | OK |
| quiz-quint | Quint needs a joker (only 4 naturals exist) | OK |
| quiz-flowers-same | All 8 flowers interchangeable | OK |
| quiz-sp-jokers | No jokers in Singles & Pairs | OK |
| quiz-concealed | C = concealed, no exposures before mahj | OK |
| quiz-colors | Card colors denote different suits, not fixed ones | OK |
| quiz-hand-size | 13 tiles held, 14th via draw/call | OK |
| quiz-joker-exchange | You may exchange a matching natural tile for an exposed joker "on your turn" | **FIXED** — the NMJL rule requires you to draw or call your 14th tile *first*; exchanging before that makes your hand dead. The explanation said only "on your turn," which a beginner could read as "any time during your turn," including before drawing. Added the missing sequencing clause. |
| quiz-dead-joker | A discarded joker is dead, cannot be called | OK — confirmed against NMJL rule text (jokers can only come from the wall or from swapping an exposed one) |

## CategoryContent.swift (9 category flashcards + 9 hand-match questions)

All category flashcards reuse the verified `HandCategory.howToSpot` strings
and add short strategy notes; none contain factual errors. All hand-match
example racks are original 13-tile teaching deals (verified against
`ContentValidityTests`), not reproductions of real card lines.

| id | Verdict |
|---|---|
| cat-year, cat-2468, cat-like, cat-quints, cat-run, cat-13579, cat-winds, cat-369, cat-sp | OK |
| hm-2468, hm-run, hm-odds, hm-winds, hm-369, hm-like, hm-year, hm-quints, hm-sp | OK — category-reading logic is internally consistent and does not misstate any rule |

## CharlestonContent.swift (10 strategy flashcards + 9 scenarios)

| id | Claim | Verdict / rationale |
|---|---|---|
| ch-what | 3 passes (right/across/left), optional 2nd round (left/across/right), optional courtesy pass across, always 3 tiles | OK — matches official pass order exactly |
| ch-first-look | Strategy only | OK |
| ch-jokers | Jokers may never be passed in Charleston or courtesy pass | OK |
| ch-flowers | Flowers CAN be passed (unlike jokers) | OK |
| ch-pairs | Jokers can't make pairs, protect natural pairs | OK |
| ch-blind | Blind pass allowed on the LAST pass of either Charleston (1-3 unseen tiles) | OK — verified against multiple sources: blind pass is legal only on the First Left (3rd sub-pass of Charleston 1) and Last Right (3rd sub-pass of Charleston 2), i.e. exactly "the last pass of either Charleston." The app's phrasing is correct and not overstated. |
| ch-stop | Second Charleston needs unanimous agreement to happen | OK |
| ch-courtesy | Courtesy pass: 0-3 tiles, same number both ways, with the player across | OK |
| ch-watch, ch-telegraph | Strategy only | OK |
| cs-evens, cs-winds, cs-run, cs-pairs, cs-junk, cs-flowers, cs-like, cs-commit, cs-year | Scenario decks: pass direction labels, joker/flower handling | OK — every scenario correctly keeps jokers out of `recommendedPass` and labels the pass direction consistent with Charleston order |

## KeepDiscardContent.swift (14 flashcards)

| id | Claim | Verdict / rationale |
|---|---|---|
| kd-wrong-parity, kd-third-flower | Strategy only | OK |
| kd-joker-rescue | Joker rescues any section except Singles & Pairs | OK |
| kd-joker-swap | "You just drew the real 6 Bam... on your turn, place it on their exposure and take the joker" | OK — already correctly framed as happening after a draw, so no sequencing issue here |
| kd-sp-joker | Jokers useless in Singles & Pairs | OK |
| kd-count-four | Only 4 copies of any tile exist | OK |
| kd-exposed-pung, kd-follow-count, kd-wind-pair, kd-flower-vs-wind | Strategy only | OK |
| kd-dead-joker | A discarded joker is dead, can't be called | OK |
| kd-call-cost | Calling exposes your section and kills a concealed hand | OK |
| kd-mahj-call | Concealed hands may still call the winning tile for mahj jongg | OK |
| kd-hot-late | Strategy only | OK |

## ProContent.swift (6 advanced Charleston scenarios + 10 defense quiz + 8 rack-reading questions)

| id | Claim | Verdict / rationale |
|---|---|---|
| pro-ch-two-sections, pro-ch-keep-pair, pro-ch-pass-pair, pro-ch-369-vs-run, pro-ch-second-stop, pro-ch-defend-late | Charleston direction labels, pair/joker handling, pass-direction defense reasoning | OK |
| pro-def-read-like, pro-def-read-369, pro-def-count-copies, pro-def-quints-dead, pro-def-safe-discard, pro-def-hot-tile, pro-def-break-hand | Reading exposures, counting copies (max 4 per real tile), defense | OK |
| pro-def-joker-swap | "On your turn you may redeem an exposed joker by giving the matching natural tile" | **FIXED** — same missing-sequencing issue as `quiz-joker-exchange` above, and more important to state precisely in the Pro tier aimed at players who already know the sections. Added the "after you draw or call" clause and the dead-hand consequence of skipping it. |
| pro-def-track-jokers | Exposed jokers are redeemable by any player holding the natural tile | OK — framed as tracking/strategy, not a rule statement, so the missing sequencing detail doesn't misstate a rule here |
| pro-def-dead-joker | Discarded joker is dead | OK |
| pro-rack-1..8 | Category-reading logic across decoy sections | OK — internally consistent, no rule errors, no real-card reproduction |

## Fixed (2 items, both the same underlying rule gap)

1. `Shared/Content/TileBasicsContent.swift:quiz-joker-exchange` — explanation
   now states the exchange must happen *after* you draw or call your 14th
   tile, not simply "on your turn," matching the official NMJL rule that an
   early exchange makes your hand dead.
2. `Shared/Content/ProContent.swift:pro-def-joker-swap` — same fix, with the
   dead-hand consequence spelled out since this is the advanced tier.

## Flagged for the orchestrator

None of the content contains a claim that is actually wrong, ambiguous, or
at risk of reproducing the real NMJL card. One soft observation, not
actionable without a product decision:

- `HowToPlayContent.swift:htp-tiles` describes suit colors as "craks (red),
  bams (green), and dots (blue)." Real physical dot tiles are typically
  printed with a mix of colors, not uniformly blue; "blue" here is a common
  teaching mnemonic (and matches the red/green/blue convention used
  elsewhere in the app, e.g. `tiles-card`'s "any suit can be red, green, or
  blue"). This is a widely used simplification, not a factual error, so no
  change was made. Flagging only in case the orchestrator wants the wording
  softened (e.g. "dots are often shown as blue") for extra precision.

## Everything else

All tile counts (152 total, 108/16/12/8/8 breakdown), the dragon-suit
pairing (Red-crak, Green-bam, Soap-dot), joker rules (groups of 3+ only,
never pair/single, never Charleston, discarded jokers are dead, exposed
jokers may be redeemed), Charleston order and blind-pass timing, calling and
exposure rules (pung/kong/quint callable, pair/single only for mahj,
concealed hands can still call mahj), and the "declare Mah Jongg on a legal
14-tile hand matching a card line" rule were all verified correct as
written. No example hand anywhere reproduces or paraphrases-to-copy a real
NMJL card line; all are original teaching decks as required.
