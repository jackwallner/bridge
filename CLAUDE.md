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
free/Mahj+ split).

**App Store reviews:** the fleet funnel. `ReviewPromptTracker` (launches,
positive moments, cooldowns, terminal outcome) gates `ReviewPromptSheet`:
enjoying it? → yes routes to the App Store write-review page, no routes to a
feedback mail draft (`jackwallner+m@gmail.com`). Unhappy players never see a
rating ask. Fires after the 3rd finished drill (`DrillCompleteView`, 1.4s after
the celebration lands); Settings' Rate / Send Feedback open the same sheet at
their step. App Store ID `6790052126`.

## Products & the Mahj+ model

`com.jackwallner.mahj.monthly` $1.99 · `.yearly` $9.99 · `.lifetime` $29.99
(StatScout-style cheapo tier, chosen 2026-07-12). Both subscriptions carry a
1-week free trial — keep monthly trials (fleet rule). RevenueCat entitlement
`pro`; public SDK key in `SubscriptionService.swift`, RC secret API key in
`~/.mahj_credentials` (never commit).

Membership is branded **Mahj+** in-app (`Membership.name`; the RevenueCat
entitlement id stays `pro`). "Pro" as a player-facing word is retired: it reads
as a skill tier, and the free rooms are explicitly the beginner ones.

**Free-beginner + extra-sets model (2026-07-13):** all four beginner rooms are
FREE and everything that was ever free stays free. Mahj+ ADDS: one extra
practice set per beginner room (`Shared/Content/PlusContent.swift`, drills
flagged `isPlus`, ids `plus-*`, same mechanics as the room's free drills, just
more original questions) plus the whole `pro-tables` room, now shown as **The
Master Tables** (`Shared/Content/ProContent.swift`). Locking is per-drill:
`Room.isLocked(_:isMember:)` is the single source of truth, and `SessionBuilder`
filters the Quick Session pool through it. The onboarding trial page
follows the OT710 zero-shift pattern (`~/OT710.md`, StatScout reference): no
plan cards, soft "Get Started" exit ABOVE the primary, primary CTA in the exact
Continue slot, one tap → yearly trial purchase → Apple confirm; full
`PaywallView` (plan picker) is only the products-failed fallback and the
in-app/Settings paywall. A user backing out of Apple's sheet is a
`PurchaseOutcome.cancelled`, NOT an error: never answer it by shoving up
another paywall.

**Paywall compliance (App Review 3.1.2):** `PaywallView` must always show, on
the purchase screen itself: membership name, per-plan price, billing period, an
explicit auto-renew + cancellation sentence (`PaywallPricing.terms`), Restore,
Terms of Use, and Privacy Policy. Don't trim any of them for layout.

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
  cover flashed Home behind onboarding on first launch). Navigation is a LOBBY:
  `HomeView` shows Get Started (mixed session) + one card per room; `RoomView`
  lists that room's drills, with the locked Mahj+ set and an in-room upsell.
  (Home was flat until 2026-07-13; once every room grew an extra set, a dozen
  drill rows on one screen stopped reading as rooms.) Onboarding stores skill level
  at defaults key `mahj.skillLevel`. After the trial decision, players who
  selected `new` see `HowToPlayView` first, then everyone gets
  `FeatureTourView`, whose finale runs a real Quick Session. Both of those
  screens carry an ESCAPE HATCH straight to Home ("Skip for now" / "Skip the
  tour" / "Skip it, take me to the app"): onboarding is long, and a player who
  wants to just use the app must always be one tap from doing so. The primer
  stays available from Home for new players and from Settings for everyone.
  `HowToPlayView` pages by swipe as well as by buttons, and its Back button
  sits NEXT to Continue, not in the top-left corner a thumb can't reach.
- `MahjTrainer/Utilities/Theme.swift` — the warm-modern design system: cream
  surfaces, jade primary, coral energy, per-room accents (`Room.accent`), serif
  display type (`Theme.display`), `themedCard()`/`primaryCTA()` styles,
  `Haptics` (gated on `settings.haptics`). `SoundPlayer` plays the synthesized
  wavs in `MahjTrainer/Resources/Sounds` (gated on `settings.sound`;
  regenerate via a make_sounds.py-style script if changed). All colors are
  light/dark adaptive; launch screen color is the `LaunchBackground` asset
  (keep in sync with `Theme.background`).

## Flashcard deck (signature interaction)

See `MahjTrainer/Views/Drills/CLAUDE.md` for the swipe-deck gesture/flip
mechanics and gotchas.

## Room art

`scripts/generate_room_art.py` generates the five room banners once via
Pollinations and bakes them into `Assets.xcassets/RoomArt`. The app NEVER calls
Pollinations at runtime. The art is DECORATIVE ONLY: it may never carry
information a learner reads (no tile faces, no card sections, no text). A
diffusion model cannot draw a trustworthy 2 Crak, and a wrong tile teaches the
wrong thing. Real tiles are always `TileView`/`TileRackView` drawing real data.
Rerun with `--force`, or `--only <name> --seed-offset N` to reroll one.

## Design research

`docs/research/mahjong-market.md` (competitor apps, pricing, aesthetic
white-space) and `docs/research/trainer-ux.md` (flashcard/session UX patterns,
swipe-deck checklist) — consult before design or monetization changes.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, pricing scripts, gotchas): always-loaded global CLAUDE.md + the
`ios-dev` skill.
