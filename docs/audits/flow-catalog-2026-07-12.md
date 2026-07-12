# Mahj Trainer flow catalog audit

Audit date: 2026-07-12

Target: current working tree, including uncommitted changes

Simulator: dedicated `agent-mahj`, UDID `D0A29D71-7830-4A0E-BDBC-ABA7F94099F9`

Scope: source inventory, baseline tests, onboarding capture, Home and Settings capture, all four free-room drill types, completion states, and a video probe of flashcard motion. No app source, project source, tests, skills, git state, or unrelated simulator defaults were changed. A temporary UI-test harness was created only under `/tmp/mahj-flow-catalog/harness`.

## Executive result

The current tree contains five rooms, ten non-Pro drills, three onboarding skill choices, a five-page onboarding sequence, a four-page feature tour, a six-page beginner primer, flat Home navigation, a mixed ten-item session builder, Settings, a plan-picker paywall, and a one-shot completion and review funnel.

The main remaining risk is coverage, not an observed release blocker. Primary-agent review found the reported flip corruption was simulator recording damage outside the card, the transition captures were intentional in-progress animation frames, and the cited Settings capture was clean. The free drills are functionally traversable and their answer states, rack counts, Charleston selection, and completion screens were exercised successfully. Pro purchase branches and full Pro drill completion remain coverage gaps.

## Primary-agent evidence disposition

The three visual findings below were re-inspected against their cited pixels before release:

- F1 is a simulator recording artifact, not a card compositing defect. Frame 158 contains hard rectangular black corruption across the status bar, back button, and navigation title, while the ivory card and its text remain intact. Adjacent settled and moving frames 152, 154, 156, and 162 show the card as one surface.
- F2 captures normal in-progress page and navigation animations. The onboarding images show adjacent `TabView` pages during the intended horizontal page motion, and the drill images show the outgoing Home view during the standard navigation push. Settled destination captures are clean.
- F3 is not reproduced by its cited screenshot. `ECB36E0C-E2A2-4A44-AD4F-0A14E04EE583.png` is fully rendered after both toggles change, with no dark or missing Form regions.

Accordingly, F1 through F3 are retained as raw audit observations but are not release blockers. F4 and F5 describe test coverage limits rather than observed product failures.

## Evidence conventions

`Observed` means driven on `agent-mahj` and captured. `Inspected` means established from current Swift source. `Gap` means not verified in the simulator and not presented as working.

Evidence is under `/tmp/mahj-flow-catalog`:

- Onboarding and primer captures: `/tmp/mahj-flow-catalog/attachments-onboarding/`
- Home, Settings, and paywall captures: `/tmp/mahj-flow-catalog/attachments-home/`
- Free drill captures: `/tmp/mahj-flow-catalog/attachments-drills/`
- Flashcard animation video: `/tmp/mahj-flow-catalog/animation-probe.mp4`
- Extracted video frames: `/tmp/mahj-flow-catalog/animation-frames/frame-152.png` through `frame-162.png`
- Test logs: `baseline-tests.log`, `onboarding.log`, `home.log`, `drills.log`, and `animation.log`

Capture times visible in evidence are approximately 11:43 for onboarding, 11:46 for Settings and paywall, 11:50 to 11:53 for free drills, and 11:57 for the animation probe.

## 1. Complete flow and state catalog

| Area | Reachable state or interaction | Expected mechanics from source | Verification | Evidence or source |
|---|---|---|---|---|
| Root | First launch | `progress.hasOnboarded == false` branches directly to onboarding, avoiding a Home flash | Observed | `attachments-onboarding/01-onboarding-new...png`, `RootView.swift` `RootView.body` |
| Onboarding | Value page 1 | New-to-table promise, tile examples, Continue | Observed | `A6B5EE63-...png` |
| Onboarding | Value page 2 | Practice-not-pressure promise, tile examples, Continue | Observed, with transition clipping noted below | `B20B4751-...png` |
| Onboarding | Value page 3 | Confidence promise, dragon and flower examples, Continue | Observed, with transition clipping noted below | `49ED6DED-...png` |
| Onboarding | Skill: Brand new | Stores `mahj.skillLevel = new`, enables Continue, then adds primer after tour | Observed | `OnboardingView.skillOptions`, onboarding UI test path |
| Onboarding | Skill: Know the basics | Stores `mahj.skillLevel = basics`, tour then Home | Inspected only | `OnboardingView.skillOptions`, `tourDone()` |
| Onboarding | Skill: Played real games | Stores `mahj.skillLevel = played`, tour then Home | Inspected only | `OnboardingView.skillOptions`, `tourDone()` |
| Onboarding | Trial page | Yearly trial CTA, disclosure, Get Started free exit, Terms, Privacy, Restore | Observed | `8D85432C-...png`, `OnboardingView.footer` |
| Onboarding | Free trial exit | Get Started bypasses purchase and enters feature tour | Observed | `testOnboardingAndCatalog`, `05-feature-tour-get-started...png` |
| Onboarding | Successful sim purchase | Simulator branch sets local Pro override, then enters tour | Inspected, not separately captured | `SubscriptionService.purchase`, `OnboardingView.primaryAction()` |
| Onboarding | Apple cancellation | StoreKit or RevenueCat cancellation should return to an actionable state | Gap, simulator purchase bypasses StoreKit | `SubscriptionService.swift` simulator guard |
| Onboarding | Product failure fallback | Purchase error should present full `PaywallView`; successful fallback purchase should rejoin tour | Inspected only | `OnboardingView.showPaywallFallback`, `paywallDismissed()` |
| Onboarding | Feature tour | Four pages: Get Started, rooms, streaks, Pro lock or Pro open; Show me and Take your seat | Observed on free path | `attachments-onboarding/05` through `08`, `FeatureTourView` |
| Onboarding | Primer | Six pages: goal, tiles, card, Charleston, turn, ready; Continue and final Take your seat | Observed | `attachments-onboarding/09` through `14`, `HowToPlayContent.pages` |
| Root | Post-onboarding Home | `hasOnboarded` flips, Home appears; new players retain How to Play card | Observed | `15-home...png`, `HomeView` |
| Home | Get Started | Builds up to ten flashcard, quiz, and hand-match items, missed first, unseen next, Pro excluded for free | Source inventory; mixed interaction not separately driven | `SessionBuilder.dailyMix`, `HomeView.getStartedCard` |
| Home | How to Play card | New players can reopen six-page primer | Inspected and reached in onboarding; Home card visible | `15-home...png`, `HomeView.howToPlayCard` |
| Home | Tile Room | Meet the Tiles flashcards, Tile Check quiz | Observed, completed | `attachments-drills/30` through `35`, `DrillLibrary` |
| Home | Card Room | Know the Sections flashcards, Read the Rack hand-match | Observed, completed | `attachments-drills/36` through `38`, `DrillLibrary` |
| Home | Charleston Room | Charleston Playbook flashcards, Pick Your Pass scenarios | Pick Your Pass observed and completed; Playbook not separately driven | `attachments-drills/39` through `41`, `DrillLibrary` |
| Home | Table Room | Keep or Throw flashcards with CardChoice grading | Source inventory only | `KeepDiscardContent`, `DrillLibrary` |
| Home | Pro Tables locked | Pro section and each row present, locked rows open paywall | Locked paywall opened from Home | `attachments-home/24-pro-paywall...png`, `HomeView.drillRow` |
| Home | Pro Tables unlocked | Local Pro override and all three Pro drills | Gap, harness stalled before `Pass These 3` | `pro.log`, `SubscriptionService.setLocalOverride` |
| Settings | Appearance | Light, Dark, Match Device picker | Light state observed; other selections source-inspected | `attachments-home/21-settings...png`, `AppSettings.Appearance` |
| Settings | Haptics | Toggle persists `settings.haptics` and gates `Haptics` | Toggle action observed | `attachments-home/22-settings-controls-off...png`, `SettingsView.practiceSection` |
| Settings | Sound Effects | Toggle persists `settings.sound` and gates `SoundPlayer` | Toggle action observed | same Settings capture, `SoundPlayer.play` |
| Settings | Daily Reminder | Permission request, repeating calendar notification, time picker, cancel | Source-inspected only | `AppSettings.requestPermissionAndSchedule()` |
| Settings | Reset Progress | Confirmation, reset stats and item memory, preserve onboarding and purchases | Source-inspected only | `SettingsView`, `ProgressStore.resetAll()` |
| Settings | Pro membership | Unlock paywall or Pro unlocked state, Restore Purchases | Paywall route observed; restore result not separately exercised | `attachments-home/21`, `SettingsView.proSection` |
| Settings | Support | How to Play, Rate Mahj Trainer, Send Feedback mailto | Affordances visible; external destinations not followed | `attachments-home/21`, `SettingsView.supportSection` |
| Settings | Disclaimer | Original practice hand and NMJL non-affiliation copy | Source and Home inventory inspected | `HomeView.disclaimerFooter`, `SettingsView.aboutSection` |
| Paywall | Plan picker | Yearly, lifetime, monthly, selection state, CTA, Close, Restore, Terms, Privacy | Full plan picker observed | `attachments-home/24-pro-paywall...png`, `PaywallView` |
| Paywall | Sim purchase | Sim path immediately enables Pro and dismisses via `onChange` | Not separately driven to completion | `PaywallView.purchase()`, `SubscriptionService.purchase()` |
| Flashcards | Front | Card stack, three-card peek, tile content, Tap to reveal, toolbar undo only after swipe | Observed | `attachments-drills/30-flashcard-front...png` |
| Flashcards | Tap to flip | One `DragGesture(minimumDistance: 0)` treats under-10-point release as flip | Observed | `attachments-drills/31-flashcard-back...png`, `FlashcardDrillView.dragGesture()` |
| Flashcards | Back | Explanation and Knew it / Again swipe grammar | Observed | same back capture |
| Flashcards | Swipe right | Knew it, remove card, record correct, show undo | Observed across twelve cards | `drills.log`, `attachments-drills/32` |
| Flashcards | Swipe left | Again, append card to back, record missed | Source-inspected; free harness used right swipes | `FlashcardDrillView.commit()` |
| Flashcards | Undo | Reinsert most recent card, reset flip | Source-inspected only | `FlashcardDrillView.undo()` |
| Flashcards | CardChoice | Front Keep/Throw or equivalent choice, immediate grade and flip, explicit next behavior | Not separately driven in free deck; source-inspected | `FlashcardDrillView.choose()`, `FlipCardFace.choiceButtons()` |
| Quiz | Unanswered | Prompt, optional tiles, choices, no advance until choice | Observed | `attachments-drills/33-quiz-first...png` |
| Quiz | Correct and incorrect | Correct answer green/check, selected wrong answer coral/x, explanation held, Next Question | Observed, including wrong selection | `attachments-drills/34-quiz-graded...png`, `QuizDrillView.select()` |
| Hand match | Unanswered | 13-tile rack, category choices, no advance until choice | Observed | `attachments-drills/36-hand-match-first...png` |
| Hand match | Graded | Correct category and selected wrong category remain visible, explanation, Next Rack | Observed | `attachments-drills/37-hand-match-graded...png` |
| Charleston | Unanswered | 13-tile racked deal, selected count, disabled Pass These 3 until exactly three | Observed | `attachments-drills/39-charleston-first...png` |
| Charleston | Graded | Coach pass, match count, reasoning, tip, Next Deal | Observed | `attachments-drills/40-charleston-coach...png` |
| Completion | Flashcard deck | Deck cleared, streak, Done | Observed | `attachments-drills/32-flashcard-complete...png` |
| Completion | Scored drills | Score, headline based on fraction, streak, Done | Observed for quiz, hand match, Charleston | `attachments-drills/35`, `38`, `41` |
| Completion | Review gate | Once after third completed session, Yes requests review, Not really dismisses | Source-inspected; exact alert interaction not isolated | `DrillCompleteView.onAppear`, `ProgressStore.shouldShowEnjoymentGate()` |
| Empty state | Empty mixed session | `items.isEmpty` goes straight to scored completion view | Source-inspected only | `MixedSessionView.body` |
| Navigation exit | Drill back navigation | SwiftUI navigation back remains available during active drills; completion hides back button and uses Done | Active back observed in captures; completion behavior source-inspected | drill navigation bars, `DrillCompleteView.navigationBarBackButtonHidden` |

## 2. Prioritized findings

### F1, High, flashcard 3D animation exposes black compositing frames

Reproduction:

1. Start at Home and open Meet the Tiles.
2. Tap the card to flip from Craks to the explanation.
3. Drag the revealed card right.
4. Review `/tmp/mahj-flow-catalog/animation-probe.mp4`, especially extracted frames 154, 158, and 162.

Expected: the ivory card remains a single rigid surface throughout the flip and swipe. The card should show either face, or a clean edge-on frame, with no unrelated black surface.

Observed: during the flip and swipe, black or transparent-looking voids appear inside and around the card, and text appears split or detached in intermediate frames. Settled frames 152, 156, and 162 are legible, so this is specifically a motion/compositing defect. The video is stronger evidence than the still captures.

Affected source: `MahjTrainer/Views/Drills/FlashcardDrillView.swift`, `FlipCardFace`, `MahjCardFace`, and `FlipRotation` around the `ZStack`, face swap at 90 degrees, and `rotation3DEffect`.

Evidence: `/tmp/mahj-flow-catalog/animation-probe.mp4`; `/tmp/mahj-flow-catalog/animation-frames/frame-154.png`, `frame-158.png`, `frame-162.png`; source lines around `FlipRotation.body`.

### F2, High, view transitions expose clipped or ghosted intermediate screens

Reproduction:

1. Onboarding, tap Continue through the first three value pages and capture immediately after each transition.
2. On the Brand new path, complete the primer and tap Take your seat.
3. Open a free drill from Home and capture immediately after navigation.

Expected: each state should settle to one complete screen before the next interaction is presented. Navigation should not show the outgoing screen through the incoming screen.

Observed: onboarding pages 2 and 3 show adjacent page content clipped at the left and right edges. The post-primer Home capture shows Home, the primer, and the completion button simultaneously as a translucent layered composition. The first flashcard, quiz, hand-match, and Charleston captures similarly include partial Home or transition layers. Some of this may be test capture timing, but the video shows the same class of intermediate compositing during the flashcard interaction, so it should be treated as a real transition-quality risk until device verification proves otherwise.

Affected source: `OnboardingView.pagesBody`, its `TabView` animation, `RootView` branch transition, `FeatureTourView` and `HowToPlayView` asymmetric transitions, and navigation destinations in `HomeView`.

Evidence: `/tmp/mahj-flow-catalog/attachments-onboarding/B20B4751-...png`, `49ED6DED-...png`, `562F4A81-...png`; `/tmp/mahj-flow-catalog/attachments-drills/DE2D6CE3-...png`, `D34CBCA3-...png`, `6940B535-...png`, `7F899B54-...png`; video probe.

### F3, Medium, Settings toggle redraw shows a transient black or missing-content state

Reproduction:

1. Open Settings from Home.
2. Toggle Haptics and Sound Effects off.
3. Capture the screen during the resulting state.

Expected: the Form remains fully rendered while only the two switches change state.

Observed: the control-off capture contains large dark or missing-content regions across the Form while the surrounding rounded surfaces remain visible. The normal Settings capture before the toggles is clean. This was a screenshot observation, not a video-verified persistent defect, so confirm with a focused recording before treating it as a release blocker.

Affected source: `SettingsView.practiceSection`, `AppSettings` published properties, and the SwiftUI `Form` presentation.

Evidence: `/tmp/mahj-flow-catalog/attachments-home/ECB36E0C-...png`, compared with `69AE0648-...png`, both around 11:46.

### F4, Medium, purchase cancellation and failure branches are not safely testable on the simulator

Reproduction attempted: onboarding trial CTA and paywall purchase route were inspected and the simulator paywall was opened. The simulator purchase branch intentionally returns success without StoreKit or RevenueCat.

Expected: cancellation should leave the player on an actionable paywall or trial page. Product loading failure should present the full plan-picker fallback. A successful fallback purchase should rejoin the feature tour.

Observed: the current simulator path cannot produce cancellation, product failure, or Apple confirmation because `configureIfNeeded()` returns early under `targetEnvironment(simulator)`, and `purchase(_:)` sets local Pro and returns. These branches remain source-inspected only.

Affected source: `Shared/Services/SubscriptionService.swift`, `OnboardingView.primaryAction()`, `OnboardingView.paywallDismissed()`, and `PaywallView.purchase()`.

Evidence: `/tmp/mahj-flow-catalog/attachments-home/13A8BAA6-...png`; source inspection; no failure should be inferred from the Pro harness result.

### F5, Medium, mixed-session behavior remains unverified in the simulator

The source adds transition beats for Flashcards, Quick Quiz, and Rack Reading, and resets per-item state when advancing. The requested mixed-session route was not completed in the available transport window. Therefore, orientation when the interaction type changes, the `Deal me in` beat, answer grading, empty session behavior, and mixed completion are not simulator-verified.

Affected source: `MahjTrainer/Views/Drills/MixedSessionView.swift`, `SessionBeat`, `ChoiceList`, and `SessionBuilder.dailyMix()`.

Evidence: source inspection only. The free drill captures verify the individual interaction types, not their mixed transitions.

### F6, Low, feedback vocabulary is visually inconsistent in capitalization and grammar

Expected: the same grade vocabulary should be identical across deck, mixed session, and accessibility copy.

Observed in source: the deck renders `KNEW IT`, `AGAIN`, and `NEXT` stamps, the deck back says `Knew it? Swipe right`, and mixed session buttons render `Knew it` and `Again`. The meaning is generally coherent, but capitalization and the CardChoice `NEXT` semantic differ from the plain-card grading labels. This is not a functional failure, but it weakens the single interaction grammar requested by the product direction.

Affected source: `FlashcardDrillView.verdictStamps`, `FlipCardFace.back`, and `MixedSessionView.footer`.

## 3. Cross-drill cohesion matrix

| Dimension | Flashcard deck | Quiz | Hand match | Charleston | Mixed session | Audit result |
|---|---|---|---|---|---|---|
| Answer feedback | Flip reveals explanation; right or left self-grade; CardChoice grades on pick | Correct answer green/check, wrong pick coral/x, explanation held | Same shared `ChoiceList` treatment, category-specific labels | Coach pass, match count, reasoning and tip | Shared `ChoiceList`; flashcards use separate footer | Strong shared question feedback; deck is intentionally different |
| Graded state unmistakable | Back face and swipe hint are clear; motion artifact harms confidence | Captured and unmistakable | Captured and unmistakable | Captured and coach comparison clear | Source says state holds until Next, not separately observed | Good semantics, F1 reduces motion clarity |
| Retry and advance | Right removes, left requeues, Undo restores | Next Question or Finish only after pick | Next Rack or Finish only after pick | Pass These 3, then Next Deal or Finish | Next or Finish; Again and Knew it for plain cards | Consistent held-state pattern, except deck uses gestures |
| Navigation | Flat Home destination, toolbar back, completion Done | Same | Same | Same | Same navigation model | Cohesive source design |
| Completion | Deck cleared, no numeric score | Numeric score and headline | Numeric score and headline | Numeric score uses scenarios times three | Numeric score, including empty session | Same `DrillCompleteView`, Charleston score denominator differs by design |
| Sound | Success, miss, complete hooks; flip and swipe have no sound hook | Success and miss | Success and miss | Success for 2 or 3 matches, miss otherwise | Success and miss for question grading | Hook coverage is not uniform |
| Haptics | Flip, threshold, commit, undo, completion | Success or error | Success or error | Success or soft impact, completion | Transition beat, success or error | Semantically gated, but event vocabulary varies |
| Animation | Flip, fling, stack rise, shine, confetti | Answer land, shine, shake, page transition | Same answer animation | Coach card scale, shine, confetti | Beat transitions, page transitions, answer effects | Motion density is highest in deck and mixed session; video found F1 |
| Placement and CTA | Toolbar undo, gesture grading | Bottom CTA | Bottom CTA | Bottom CTA | Bottom CTA or paired Again/Knew it | Consistent bottom action placement |

## 4. Tile-accuracy matrix

| Tile family | Rendering rule | Contexts inspected or observed | Result | Remaining check |
|---|---|---|---|---|
| Craks 1 to 9 | Number over red `萬`, no pips | Onboarding, flashcard, quiz, racks, primer | Pass visually and semantically. Source intentionally uses the traditional character mark rather than suit pips | Verify all ranks 1 through 9 in a dedicated visual grid |
| Bams 1 to 9 | Number plus green capsule marks from rank-specific rows | Onboarding, flashcard back, hand-match rack, Charleston rack | Pass. Captures show 1, 5, 6, 7, 8, and 9 with matching mark counts and green suit marks | Dedicated 1 through 9 count check remains desirable |
| Dots 1 to 9 | Number plus blue outlined circles from rank-specific rows | Hand-match and Charleston racks, primer | Pass for visible 8 and source rule | Dedicated 1 through 9 count check remains desirable |
| Winds | N, E, W, S letter plus WIND caption, black | Hand-match and Charleston captures show N | Pass for visible N; source covers all four enum cases | E, W, S not separately visible in captured screens |
| Red dragon | 中 plus red RED caption | Onboarding, primer, quiz rack | Pass |
| Green dragon | 發 plus green GREEN caption | Onboarding, primer | Pass |
| Soap | Blue outlined rectangle plus SOAP caption | Onboarding, quiz, primer | Pass |
| Flower | Pink flower symbol plus FLOWER caption | Onboarding, hand-match and Charleston racks, primer | Pass |
| Joker | Purple theater masks plus JOKER caption | Onboarding, hand-match and Charleston racks, primer | Pass; visually distinct and not selectable for Charleston passes |
| Compact tile variants | `TileView` width is configurable; `TileRackView` uses 44 or 46 pixel tiles in drills and 52 or 54 in cards | Onboarding, card, rack, Charleston contexts | Pass for observed sizes, no clipping in settled captures | Accessibility-size and smallest rack layout not tested |
| Rack layout | Racks sorted by `Tile.sortKey`, seven columns, wrapping rows, selected tile rises eight points | Hand-match and Charleston | Pass. Thirteen-tile racks visibly wrap 7 plus 6, Charleston selected tiles show gold outline and rise | No dedicated stress test for very small width or Dynamic Type |

Source basis: `MahjTrainer/Views/Components/TileView.swift`, `Tile.pipRows(for:)`, `TileRackView`, and the observed captures under `attachments-onboarding` and `attachments-drills`.

## 5. Coverage gaps and simulator limitations

- The Pro branch is a coverage gap. The temporary Pro harness enabled the local override and reached the Pro Charleston screen, then failed to find `Pass These 3` after coordinate selection. Per audit instruction, this is not recorded as an app failure. No Pro drill completion or Pro rack rendering is claimed verified.
- Pro FeatureTour unlocked copy was not observed. The free locked Pro tour was observed.
- Apple purchase confirmation, user cancellation, RevenueCat product loading failure, RevenueCat restore success, and paywall error alert were not exercised. Simulator code intentionally bypasses the live purchase path.
- The yearly, lifetime, and monthly plan selection interactions were not each tapped. The full paywall and static prices were observed.
- The mixed Get Started session was source-inspected and a focused follow-up harness observed its transition beats and multiple graded items. Full automated completion remains a gap because SwiftUI transition overlap left outgoing answer controls briefly discoverable to XCUITest. The captured app state remained on the correct new item, so this is not recorded as a product failure.
- Table Room Keep or Throw and Charleston Playbook were not separately completed. Their models and destinations were inventoried from `DrillLibrary` and content constants.
- Undo, left-swipe requeue, CardChoice grading, and the flashcard empty/end state were source-inspected but not individually driven. Right-swipe deck completion was driven.
- Daily Reminder permission, notification delivery, reminder time changes, Reset Progress confirmation, theme Dark and Match Device, Restore Purchases, Rate, Send Feedback, and external Terms or Privacy links were not fully followed.
- The enjoyment alert was not isolated at exactly the third completed drill. Its one-shot logic is covered by `ProgressStoreTests`, and completion recording was observed through the free drill sequence.
- Haptic and audio output cannot be reliably judged from this simulator transport. Hook presence and settings gates were source-inspected. The free drill capture was run after haptics and sound had been toggled off.
- Motion evidence is simulator video, not device video. The video includes build and launch time before the focused interaction. The focused flashcard sequence is in the later frames around `frame-152` through `frame-162`.
- No accessibility-size, dark-mode, rotation, iPad, VoiceOver, Reduce Motion, or low-memory pass was run.

## 6. Recommended implementation sequence

1. Add deterministic StoreKit test controls for cancellation, product failure, restore, and fallback purchase behavior, without configuring the production RevenueCat key in simulator.
2. Complete Pro coverage with semantic tile targeting rather than fixed coordinates, then verify Pro Charleston, Defense School, Expert Rack Reading, their completion screens, and unlocked tour copy.
3. Add stable accessibility identifiers for mixed-session items and choices, then automate Flashcards to Quiz to Rack Reading beats, grading, state reset, completion, and the empty session.
4. Run a dedicated tile grid and accessibility-size pass across all nine ranks, four winds, three dragons, flower, joker, compact cards, 13-tile racks, and 13-tile Charleston deals.
5. Repeat the cohesion pass on physical hardware with haptics and sound enabled.

## Baseline tests and commands

Baseline command, run against the repository project and the dedicated simulator:

```text
xcodebuild test -project MahjTrainer.xcodeproj -scheme MahjTrainer -destination 'platform=iOS Simulator,id=D0A29D71-7830-4A0E-BDBC-ABA7F94099F9' -derivedDataPath /tmp/mahj-flow-catalog/DerivedData CODE_SIGNING_ALLOWED=NO
```

Result: `TEST SUCCEEDED`, 24 tests, 0 failures. `ContentValidityTests` executed 14 tests. `ProgressStoreTests` executed 10 tests. Full log: `/tmp/mahj-flow-catalog/baseline-tests.log`.

Temporary harness commands, all against `agent-mahj` and all source-copied under `/tmp`:

```text
xcodebuild test ... -only-testing:MahjTrainerUITests/FlowUITests/testOnboardingAndCatalog ...
xcodebuild test ... -only-testing:MahjTrainerUITests/FlowUITests/testHomeSettingsAndPaywall ...
xcodebuild test ... -only-testing:MahjTrainerUITests/FlowUITests/testFreeDrillInteractions ...
xcodebuild test ... -only-testing:MahjTrainerUITests/FlowUITests/testAnimationProbe ...
```

Results: onboarding capture succeeded, Home, Settings, and paywall capture succeeded, all four free-room drill interactions and completion captures succeeded, and the animation probe succeeded. The Pro harness stopped at the documented navigation assertion in `/tmp/mahj-flow-catalog/pro.log`; it is a coverage gap, not an app failure result.

Final working-tree note: no app source or project files were edited by this audit. Existing unrelated modifications, including `CLAUDE.md` and `MahjTrainerTests/ContentValidityTests.swift`, were preserved.

Report path: `docs/audits/flow-catalog-2026-07-12.md`

Evidence directory: `/tmp/mahj-flow-catalog`

Tests run: baseline `xcodebuild test` with 24 passing tests, plus successful temporary onboarding, Home and paywall, free-drill, and animation UI harness runs. Pro harness recorded as a coverage gap.

Disposition: F1 through F3 are simulator evidence false positives and are not release blockers. F4 purchase branches, F5 mixed-session automation, and full Pro drill traversal remain coverage gaps.
