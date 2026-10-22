# Bridge rules audit, 2026-10-22

Baseline: `4776a046`. Scope: the committed iOS and Android trainer, all registered lessons, generated opening/lead/play advice and grading. Work is isolated from the original working tree. This app supplies drills, not a complete multiplayer bidding or card-play service.

Final integration base: `a2e0fde` (current origin/main). Some corrections listed below were already present there and were retained. The table records findings in the original local checkout as well as the remaining fixes. Final verification covers the newer generated engines too.

## Authorities and rules

[ACBL SAYC System Booklet, January 2006](https://web2.acbl.org/documentlibrary/play/SP3%20%28bk%29%20single%20pages.pdf) defines the bidding agreements. [WBF Laws of Duplicate Bridge](https://www.worldbridge.org/wp-content/uploads/2016/12/2017LawsofDuplicateBridge-paginated.pdf), Laws 18, 19, 22, 44, 77 and 78 define auctions, legal play and scoring.

| Area | Authoritative rule | Test on both platforms |
| --- | --- | --- |
| Hand evaluation | A/K/Q/J count 4/3/2/1. Ordinary openings require hand evaluation, not an automatic pass through 12 HCP. | `saycOpeningsAndTeachingCounts` |
| SAYC opening shape | Normally five-card majors. Equal long suits: higher ranking; 3-3 minors: clubs; 4-4 minors: diamonds. | `saycOpeningsAndTeachingCounts`, existing generator tests |
| Notrump | 1NT is 15-17 balanced. 4333, 4432 and 5332 are balanced; 5422 is not. Five-card majors are permitted. The generator deliberately omits contested examples rather than penalizing a reasonable choice. | `saycOpeningsAndTeachingCounts` |
| Responses | Unpassed responder, uncontested nonjump new suit: 6+ at one level, 10+ at two, forcing one round. Major raise: 6-10 dummy points; limit raise: 10-11 dummy points. 1NT over a major: 6-9, nonforcing. | `gradedAdviceMatchesTheDisplayedPosition` checks the actual lesson; there is no response AI |
| Auction | Increasing levels/strains C,D,H,S,NT. Opponents may double an undoubled bid; declaring side may redouble. New bids cancel doubles. Four opening passes give no contract; otherwise three passes end the auction. Declarer first named the final strain on the winning side. | `legalAuctionsAndPassedOutHands` |
| Play | Follow suit, including trump. When void, any card is legal. Highest trump wins; without trump, highest led suit wins. | `followingAndTrickWinners` |
| Duplicate score | Minor tricks 20; majors 30; first NT trick 40, later 30. Contract trick points of 100 earn game (300/500 NV/V); otherwise 50 partscore. Doubled/redoubled insult 50/100. Overtricks do not qualify a contract for game. Slams add 500/750 or 1000/1500. | `duplicateScoringTable` |
| Penalties | Undoubled: 50/100 per undertrick NV/V. Doubled NV: 100,200,200,then 300 each; V: 200,then 300. Redoubled doubles these. Doubled overtricks: 100/200 NV/V, redoubled twice that. Passed out: zero. | `duplicateScoringTable`, `legalAuctionsAndPassedOutHands` |

Matchpoints compare the board result with other pairs in the same direction. There is no matchpoint ranking service in the app.

## Corrections

| Rule/advice wrong before | After | Regression |
| --- | --- | --- |
| Pass with 0-12, open at 13, despite grading 12-count major openings as open. Generic responder ranges 0-7/8-9/10+. | Hand evaluation and the booklet's exact major-response ranges, including passed-hand and nonjump qualifications. Rule of 20 is identified as a training guideline. | Opening and advice tables |
| `hand-one-spade`, `hand-one-heart` originally claimed 14 HCP but held 12. `plus-open-spade-six` claims 14; it has 13. | The upstream corrected 14-point holdings are preserved; explanations count their displayed cards. | Six authored opening/count rows |
| Copy says a balanced five-card major must open 1NT; two pass explanations still require 13. | SAYC permits that NT opening; ordinary opening strength requires judgment. | Four actual teaching-copy rows on both platforms |
| 14 HCP 5332 club hand described as insufficiently balanced for NT. | It is balanced but below the NT point range. | Authored count and balanced-shape tables |
| The older checkout preferred a five-card major over a six-card minor. Duplicate cards were accepted as a hand. | The newer upstream longest-suit policy is preserved; physical duplicates are rejected. | Opening boundary table |
| `pro-game-major` offers both 4H and 5S, both game contracts, but accepts only 4H. | Asks for the lowest undoubled heart game. | Actual question plus scoring table |
| A third-hand defender supposedly sees declarer's fourth-hand play before choosing. | Position explicitly places the learner fourth. | Lowest winning-card calculation |
| Q-first from AK98 opposite Q765 claimed to guard against 4-1 for four tricks; both hands have four clubs. | Replaced with a fully specified cheapest-winner question. | Lowest winning-card calculation |
| Unsupported ace lead described as necessarily giving away a trick. Two rounds of clubs treated as proof of exactly two clubs. | Conditional lead advice; count exercise explicitly knows exactly two clubs. | Reviewed exact teaching copy |
| Primer could assign declarer to an opponent who named the strain first. | Declarer is first bidder of the strain on the winning side. | Auction table includes opposing strain bids |

`RulesAuditTests.swift` and `RulesAuditTest.kt` consume identical, independently authored `rules-reference.json` tables. They also inspect real catalog questions. Swift-to-Kotlin parity fixtures are additional checks, not the source of expected rules.

## Verification

Run `xcodegen generate`, the `Bridge` scheme unit tests, and `fm-gradle testDebugUnitTest` from `android/`. All authoritative tables are in the native test targets. No Gradle task runs on the Air. See `verification.md` for final receipts.
