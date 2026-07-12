# Task 01 — American Mah Jongg accuracy audit + safe corrections

Owner: Sonnet subagent, dispatched by the Opus orchestrator.
Status file — update the checkboxes as you go so this task is resumable.

## Objective
Audit EVERY piece of instructional content in the app for American Mah Jongg
correctness, produce a written report, and apply the corrections that are
unambiguously factual. This app teaches brand-new players, so a wrong rule is a
serious defect.

## Legal / content constraints (hard rules — do not violate)
- The NMJL yearly card is copyrighted. NEVER reproduce, paraphrase-to-copy, or
  invent "the real" card hands. All example hands are ORIGINAL teaching hands
  for the stable category system. If a correction would require quoting the real
  card, DO NOT — flag it instead.
- `MahjTrainerTests/ContentValidityTests.swift` enforces structural rules
  (13-tile deals/racks, 3-tile passes, no passing jokers, max 4 copies of a
  tile, no em dashes, unique ids, free/Pro split). Your edits must keep it green.
- No em dashes anywhere in content (tests fail on them).

## Ground truth to check against (authoritative American Mah Jongg facts)
Verify each of these against the content and fix violations:
- Tile set: 3 suits (craks/characters, bams/bamboo, dots/circles) numbered 1-9,
  4 of each = 108; 4 winds x4 = 16; 3 dragons x4 = 12; 8 flowers; 8 jokers;
  total 152.
- Dragon-suit pairing: Red dragon <-> craks; Green dragon <-> bams; White dragon
  (soap/zero) <-> dots.
- Jokers: may be used in pungs, kongs, quints, sextets (groups of 3+ identical
  tiles); NEVER in a pair, single, or as part of two different tiles; never
  passed in the Charleston; a player may swap a matching natural tile for an
  exposed joker.
- Charleston: mandatory first Charleston = right, across (over), left; optional
  second Charleston = left, across, right; the "courtesy"/optional pass across
  (0-3 tiles by agreement) follows. First pass right may be a "blind" pass of
  up to 3 tiles you have not seen only in the 2nd-3rd sub-passes — verify the
  app's phrasing is correct and not overstated. Jokers cannot be passed.
- Calling/exposures: you may call a discard to complete a pung/kong/quint IF it
  exposes the group; you may NOT call for a pair or single except to complete
  mahjong; concealed hands cannot be called on except for the winning tile.
- Winning: a legal 14-tile hand exactly matching a card line; declare "Mah Jongg".
- Verify counts/phrasing in `HowToPlayContent.swift`, `TileBasicsContent.swift`,
  `CategoryContent.swift`, `CharlestonContent.swift`, `KeepDiscardContent.swift`,
  `ProContent.swift`, and any explanation strings.

## Files to review
All of `Shared/Content/*.swift`, plus `Shared/Models/HandCategory.swift` and
`Shared/Models/Tile.swift` for the tile/category definitions the content relies
on.

## Deliverables
1. `docs/audits/mahjong-accuracy-2026-07-12.md` — a table of every claim checked:
   file + item id, the claim, verdict (OK / FIXED / FLAGGED), and for FIXED/
   FLAGGED a one-line rationale with the correct fact. Group by file.
2. Apply corrections that are unambiguously factual (wrong dragon pairing, wrong
   counts, wrong joker/Charleston rule, misleading explanation). Keep edits
   minimal and preserve the original teaching-hand nature.
3. Anything uncertain, stylistic, or that risks copying the real card: leave the
   content as-is and list under FLAGGED for the orchestrator to decide. Do not
   guess.

## Build / verify (headless only — never open Simulator.app)
```
cd /Users/jackwallner/mahj
xcodegen generate
UDID=$(agent-sim boot mahj)
xcodebuild test -project MahjTrainer.xcodeproj -scheme MahjTrainer -destination "id=$UDID" -only-testing:MahjTrainerTests/ContentValidityTests
```
If `agent-sim`/xcodegen are unavailable in your environment, still make the
edits and note in the report that tests could not be run locally; the
orchestrator will run them.

## Commit protocol (for resumability)
- Commit after the report is written and again after corrections, e.g.
  `git commit -m "docs: mah jongg accuracy audit report"` then
  `git commit -m "fix: correct <thing> per accuracy audit"`.
- Do NOT push. Do NOT bump build numbers.

## Resume protocol
If respawned: run `git log --oneline -5`, read this file and the audit report if
it exists, and continue from the first unchecked box.

## Progress
- [ ] Report written
- [ ] Corrections applied
- [ ] ContentValidityTests green (or noted as unrunnable)
- [ ] Committed

## Report back to orchestrator
Return: count of items checked, list of FIXED (file:id -> what changed), list of
FLAGGED (file:id -> the open question), and whether tests passed.
