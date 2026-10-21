---
paths:
  - "Bridge/Views/HomeView.swift"
  - "Bridge/Utilities/UnfoldedSplit.swift"
  - "Bridge/Utilities/DuoScreenshotMode.swift"
  - "Bridge/Views/StatsView.swift"
  - "Bridge/Views/SettingsView.swift"
---

# Bridge Trainer: iPhone Duo (2026-10-21)

- Unfolded (regular width, at least 720 pt), `HomeView` puts its own
  NavigationStack (Home, rooms, drills) on the leading side of the fold and Your
  Progress on the trailing side, so the record a drill is building sits beside
  it and updates as answers land. Fold edges come from
  `GeometryProxy.verticalFold()` (iOS 27.1 `reservedRegions(.division)`), else
  an even split (`UnfoldedSplit`, tested in `UnfoldedSplitTests`). Folded, every
  ordinary iPhone, and the unfolded Duo in portrait keep the single column. iPad
  splits evenly by the same rule.
- Both panes get `horizontalSizeClass = .compact`, so each lays out as on a
  phone. Inside HomeView, `horizontalSizeClass` is a computed property that
  already reflects the pane; the window's class is `windowSizeClass`.
- Folding only moves frames. The progress pane mounts on the first unfold and
  is then hidden, never removed, and the Home stack is never rebuilt, so a
  drill in progress survives the fold. Do not wrap either pane in an `if`.
- While split: the stats chips are inert (the breakdown is already open),
  Settings opens in the trailing pane instead of a sheet (`settingsSheet`
  binding; opening the Duo with the sheet up moves it to the pane), and Your
  Progress's work-on card pushes the room on Home's side (`AppDestination.room`).
- Still system sheets, so centred across the fold: the paywall (trial flow is
  locked to Mahj 1.3.2, needs Jack's go-ahead), What's New, the churn and
  feedback sheets, and sheets raised from inside Settings. Onboarding is a
  full-width readable column.
- Captures: see `screenshots.md`, "iPhone Duo capture". The `stats` route
  pushes Your Progress on the left too, so skip it for inner shots.
