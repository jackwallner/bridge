# Mahj — Project Guide

Mahj Trainer: American Mah Jongg drill app for new players (flashcards, quizzes,
hand-matching, Charleston practice — no gameplay). XcodeGen project/scheme:
`MahjTrainer`, simulator device `agent-mahj`. Bundle ID `com.jackwallner.mahj`.

**Product direction:** the swipe deck is a signature mechanic but this is NOT
"a flashcard app" — each room is free to use whatever training interaction fits
its skill (self-test choices, scenario picks, future sims). Propose
room-appropriate mechanics when adding content.

**Content is legally constrained:** the NMJL yearly card is copyrighted. Every
example hand is an ORIGINAL teaching hand for the category system — never copy
hands from the actual card. Keep the "not affiliated with NMJL" disclaimer
(Home footer, Settings, App Store description). `ContentValidityTests` enforces
content rules across ALL drills in `DrillLibrary` (13-tile deals/racks, 3-tile
passes, no passing jokers, max 4 copies of a tile, no em dashes, unique ids,
free/Pro split).

**App Store reviews:** enjoyment gate fires once after the 3rd completed drill
(`DrillCompleteView` → `ProgressStore.shouldShowEnjoymentGate()`). Settings has
Rate + Send Feedback (`jackwallner@gmail.com`).

## Products & free/Pro model

`com.jackwallner.mahj.monthly` $1.99 · `.yearly` $9.99 · `.lifetime` $29.99
(StatScout-style cheapo tier, chosen 2026-07-12). Both subscriptions carry a
1-week free trial — keep monthly trials (fleet rule). RevenueCat entitlement
`pro`; public SDK key in `SubscriptionService.swift`, RC secret API key in
`~/.mahj_credentials` (never commit).

**Free-beginner model (2026-07-12):** all four beginner rooms are FREE; only
the `pro-tables` room (advanced Charleston / Defense School / expert rack
reading, `Shared/Content/ProContent.swift`) is Pro. The onboarding trial page
follows the OT710 zero-shift pattern (`~/OT710.md`, StatScout reference): no
plan cards, soft "Get Started" exit ABOVE the primary, primary CTA in the exact
Continue slot, one tap → yearly trial purchase → Apple confirm; full
`PaywallView` (plan picker) is only the products-failed fallback and the
in-app/Settings paywall.

## Architecture

- `Shared/Models` — `Tile` (suits/winds/dragons/flower/joker, `.c(n)/.b(n)/.d(n)`
  authoring shorthand), `HandCategory` (the 9 stable NMJL card sections), drill
  types (`Flashcard` + optional `CardChoice` self-test, `QuizQuestion`,
  `HandMatchQuestion`, `CharlestonScenario`, `Drill`, `Room`).
- `Shared/Content` — all drill content as Swift constants; `DrillLibrary.rooms`
  defines the 5 rooms (ids: `tile-room`, `card-room`, `charleston-room`,
  `table-room`, `pro-tables`). `SessionBuilder.dailyMix` builds the Get Started
  mixed session (missed items first, then unseen; excludes Pro for free users).
  `HowToPlayContent` holds the original six-page beginner primer.
- `Shared/Services` — `ProgressStore` (UserDefaults streaks/completions/review
  gate + item-level `seenItems`/`missedItems`, `resetAll()` keeps onboarding),
  `AppSettings` (theme Light-default/Dark/System, haptics, sound, daily
  reminder via UNUserNotificationCenter), `SubscriptionService` (RC; simulator
  early-return preserved — never configure the prod `appl_` key on sim).
- `MahjTrainer/Views` — `RootView` branches onboarding vs `HomeView` on the
  `progress.hasOnboarded` defaults key (branch, NOT a fullScreenCover — the
  cover flashed Home behind onboarding on first launch). Navigation is FLAT:
  `HomeView` shows Get Started (mixed session) + every drill grouped by room
  section; there is no intermediate room screen. Onboarding stores skill level
  at defaults key `mahj.skillLevel`. After the trial decision, every player
  sees `FeatureTourView`; players who selected `new` then see `HowToPlayView`
  before Home. The primer remains available from Home for new players and from
  Settings for everyone.
- `MahjTrainer/Utilities/Theme.swift` — the warm-modern design system: cream
  surfaces, jade primary, coral energy, per-room accents (`Room.accent`), serif
  display type (`Theme.display`), `themedCard()`/`primaryCTA()` styles,
  `Haptics` (gated on `settings.haptics`). `SoundPlayer` plays the synthesized
  wavs in `MahjTrainer/Resources/Sounds` (gated on `settings.sound`;
  regenerate via a make_sounds.py-style script if changed). All colors are
  light/dark adaptive; launch screen color is the `LaunchBackground` asset
  (keep in sync with `Theme.background`).

## Flashcard deck (signature interaction)

`FlashcardDrillView` is a Sideline-style swipe deck: tap flips the card, and
only a flipped card can be swiped — right = "got it" (leaves the deck), left =
"again" (returns at the back). Pre-flip drags rubber-band. Undo lives in the
toolbar. Cards with a `CardChoice` show two answer buttons on the front
(choose, graded flip, held result, explicit Next). Their answer determines the
grade and whether the card returns; swipe direction never overrides it. Gesture
gotcha: the deck uses ONE
`DragGesture(minimumDistance: 0)` that treats a <10pt release as the flip
tap — a separate `.onTapGesture` loses arbitration against the drag and
silently never fires. Don't "simplify" it back to `onTapGesture`.

**Flip gotcha (fixed 2026-07-12):** the whole card must rotate as ONE unit —
`FlipRotation` is `Animatable` and swaps faces exactly at 90° while the card is
edge-on. Never rotate the text faces inside a static card background; that's
what made text detach from the card. `MahjCardFace` carries the mahjong-card
chrome (ivory surface, double frame, eyebrow, watermark) — both faces use it.

## Design research

`docs/research/mahjong-market.md` (competitor apps, pricing, aesthetic
white-space) and `docs/research/trainer-ux.md` (flashcard/session UX patterns,
swipe-deck checklist) — consult before design or monetization changes.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, pricing scripts, gotchas): always-loaded global CLAUDE.md + the
`ios-dev` skill.
