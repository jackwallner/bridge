# Mahj parity matrix: Bridge, Skat, Cribbage (2026-11-22)

Source of truth for Mahj: `~/mahj/AGENTS.md`, every file in `~/mahj/.claude/rules/`, and
the experience audit at `~/mahj/project-docs/audits/experience-2026-11-20/` (fix commit
`dc083f5`). Card apps checked at Bridge 1.2.10 (48), Skat 1.3.4 (49), Cribbage 1.3.3 (47),
by reading each app's `AGENTS.md`, rules, and source.

Key: **Has** = shipped and equivalent. **Part** = some of it. **Lacks** = fits the game,
not built. **No fit** = does not suit that game, reason given.
"Shipped" in the last column means this pass put it on TestFlight (build numbers in the
final report at the end).

## Matrix

| Mahj feature | Bridge | Skat | Cribbage | Notes |
|---|---|---|---|---|
| Endless Practice (generated questions) | Has (`HandGenerator`: opening calls) | Has (`HandGenerator`, `PracticeGenerators`) | Has (`HandCountGenerator`, `PeggingQuestionGenerator`) | Each engine rejects judgment calls, like Mahj. |
| Timed Challenge (90 s, best kept) | Has | Has | Has | |
| Fix My Mistakes (`reviewQueue`, two right to leave) | Has | Has | Has | |
| Bidding beyond the opening (Bridge only) | Lacks: Auction Room taught only the opening bid | n/a | n/a | Jack approved; built first (see below). |
| Mastery rings on Home rooms | Has (`MasteryRing`, 2026-10-20) | Part: mastery shown on Your Progress, Home still counts drills opened | Part: ledger only; Home counts drills opened | |
| Weekly gain ledger ("+N" chip, "Up N this week") | Has | Has | Has | All three have the scope-aware baseline. |
| "Work on" card opens the room (audit item) | Has (link into the room) | Part: text line, no tap | Part: accuracy card, no tap | |
| Coached miss notes ("Why not X?") | Has: opening, responding and rebid questions | Has: dealt hands in the Minute and the quick session | Has: Name the Pattern, legal play, Count the Hand | Bridge can derive notes from the opening rules for free, like Mahj derives them from `HandCategory.requires`. |
| Daily round (Minute) | Part: Bridge Minute, Bridge+ only | Part: Skat Minute, Skat+ only | Part: Cribbage Minute, Cribbage+ only | In Mahj the Minute went free as the challenge's daily round. Here the Minute is a paid trial-page benefit row, so making it free changes the frozen trial page (decision for Jack). |
| Free monthly challenge + App Store in-app events | Lacks | Lacks | Lacks | Only the `challenge` remote switch exists. Needs: the Minute to go free (frozen trial page), authored defensible closers per month, a standing RPC, monthly event art and nomination. Decision for Jack. |
| Coached play-a-hand mode | Lacks | Lacks | Lacks | Fits all three, large: Bridge needs a full declarer hand with a play engine, Skat a 10-trick game against two defenders, Cribbage a discard-peg-count hand. Mahj avoids bots; card games cannot (tricks need opponents' cards). Not started; proposal below. |
| Reference glossary (searchable, toolbar book icon) | Has (39 terms, 16 languages) | Has (Glossar, 28 terms) | Has (29 terms) | Fits all three. Content is per game and must be checked against its rules; Bridge also needs 15 translations. |
| Saved and resumable runs (`OrdinaryRunStore`, one per drill) | Lacks | Lacks | Lacks | Fits all three, medium code; Mahj spent four review rounds on edge cases. |
| What's New sheet | Has | Has | Has | |
| Rating ask with no gate (5.6.1) | Has | Has | Has | Shared code. |
| Churn question | Has | Has | Has | Shared code. |
| Send Feedback (nav-bar Send, 2026-11-22) | Has | Has | Has | Left as is. |
| PostHog analytics | Lacks | Lacks | Lacks | Needs a PostHog project per app (or one shared), App Privacy labels and a policy update in the same release. Decision for Jack. |
| Remote variants via RevenueCat metadata | Part: `trial_cta`, `rating_prompt`, `challenge` | Part: same three | Part: same three | Mahj adds `trial_title`, `trial_benefits`, `onboarding_plan`, `offer_pitch`, `trial_offer`. Each changes the frozen trial page or adds a new sales surface. |
| One-tap trial offer sheet + `TrialOfferPacer` | Lacks | Lacks | Lacks | A new sales surface after results, with the full purchase preflight. Not the frozen flow itself, but it changes how trials start. Decision for Jack. |
| iPad layout | Has | Has | Has | |
| iPhone Duo two-pane Home | Lacks | Lacks | Lacks | Fits, medium. |
| Reduce Motion | Has (confetti, shine, shake) | Part | Part | Audit adds: flashcard fades upright under Reduce Motion. |
| Accessibility-size layouts | Has | Has | Has | |
| Localization | Has: 16 languages | Has: German first (its market) | Lacks: English only | Cribbage would need a catalog and 15 translations (decision for Jack: worth it on Mahj's trial-rate data). |
| **Experience audit (Mahj 2026-11-20)** | | | | Each item ported where the same code exists. |
| Confetti falls under real gravity, waits for the graded row, Next cancels it | Lacks (same sign bug) | Lacks (same bug) | Lacks (same bug) | Confirmed identical formula `(vy + g / k) * decay - g * time / k` in all three. |
| Dark-mode grade marks readable (`gradeCorrect`/`gradeWrong`) | Lacks | Lacks | Lacks | |
| Swipe stamp rides the outgoing card | check per app | check per app | check per app | |
| Timed run: Time's up screen, late answers refused | Lacks | Lacks | Lacks | |
| Missed question repeats the cards above the explanation | n/a until miss notes | n/a | n/a | Mahj-specific to rack questions that scroll off. |
| Paywall Lifetime position, iPad plan sheet | Held | Held | Held | Frozen trial flow; held for Jack in Mahj too. |

## Build order (value per effort)

1. Bridge: responding and opener's rebid drills (approved, member request).
2. All three: the experience-audit code fixes (same code, one pattern each).
3. Bridge: coached miss notes on opening questions (derived from the engine, no new content).
4. Skat and Cribbage: mastery rings on Home and the tappable Work on card (port of Bridge's).
5. Reference glossary, saved runs, Duo: next batches.

## Status

Shipped to TestFlight on 2026-11-22 and 2026-11-23:

| App | Build | What it carries |
|---|---|---|
| Bridge | 1.3.0 (49) | Respond to Partner (9 questions) and Your Second Bid (10), both free; `BiddingEngine` grading Endless Practice skills for responses and rebids (Bridge+), mixed into the Timed Challenge; 58 new strings in all 16 languages; What's New 1.3.0; the audit fixes. 1.2.10 is still in review, so this is a new version. |
| Skat | 1.3.4 (50) | Audit fixes, including the wall-clock timer; mastery rings on Home; a tappable "Übe als Nächstes" card. |
| Cribbage | 1.3.3 (48) | Audit fixes; mastery rings on Home; a tappable work-on card. |
| Bridge | 1.3.0 (50) | Build 49 plus another session's icon change (Icon A). This build passes the release gate. |
| Bridge | 1.3.0 (51) | Adds "Why not X?" notes on every missed opening question, derived from the opening rules (9 strings in 16 languages). |
| Skat | 1.3.4 (51) | Adds the Glossar (28 terms, ISkO 2022) from Home and Settings, plus Reduce Motion fixes in the primer, the tour, the shine sweep and Home. |
| Bridge | 1.3.0 (52) | Adds "Why not X?" notes on every wrong call in responding and rebid questions (Endless, Timed, both authored quizzes, the quick session), each checked against a predicate over dealt hands; 21 strings in 16 languages. Submitted for review 2026-11-22 (manual release). |
| Bridge | 1.3.0 (53) | Another session's narrow-screen fix: hands shrink to fit 320pt screens; the correct answer's pop stays inside the side headroom on the Duo. On 2026-11-23 the build 52 submission was canceled and 1.3.0 resubmitted with build 53 (manual release). |
| Skat | 1.3.4 (52) | Warum-nicht notes in the Skat-Minute's dealt hands and the quick session; Reduce Motion in the quick session and onboarding; the card back's text scrolls at the largest text sizes so Weiter stays on the card. |
| Cribbage | 1.3.3 (49) | The glossary (29 terms, every quoted point value checked against `HandScoring`); "Why not X?" notes in Name the Pattern, legal play and Count the Hand; another session's narrow-screen card fix and long-answer wrapping. 248 tests pass. Submitted 2026-11-23 with a What's New in all 50 store locales, then swapped for build 50 (manual release). |
| Cribbage | 1.3.3 (50) | The tour's room tiles shrink to fit 320pt (Display Zoom) so Show me keeps one width, and the Get Started subtitle wraps instead of truncating; the gate fix agent cleaned the answer rows' accessibility labels. Passed the gate on all 8 personas, including zoomed. In review for 1.3.3 (manual release). |
| Bridge | 1.3.1 (54) | The glossary: 39 terms in four groups, searchable, from the Home toolbar and Settings, in all 16 languages; every quoted number checked against `BridgeRules.score`, `HandGenerator` and the HCP table. Ships together with the play-a-hand session's Play a Hand, which runs the gate and the upload. |

The audit fixes are: confetti under real gravity that waits for the graded row and stops on Next; `gradeCorrect`/`gradeWrong` marks readable in dark mode; the swipe stamp rides the outgoing card, and the flashcard stays upright under Reduce Motion; a Time's up screen when a timed run ends with nothing answered, and late answers are refused.

Not done in this pass:
- Miss notes on Cribbage's Pegging Points questions (numeric answers where several scoring paths reach the same total; no note says something true and useful for every wrong total).
- Saved runs and the iPhone Duo Home are the next batches.
- Jack's decisions on 2026-11-23: the daily round stays as it is, nothing is added to the trial page, Cribbage is not localized, and PostHog and the trial offer sheet are not approved. Play a Hand is under way in its own session.
