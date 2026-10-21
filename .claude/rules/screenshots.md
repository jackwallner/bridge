---
paths:
  - "scripts/capture-screenshots.sh"
  - "scripts/with-ipad-sim.sh"
  - "BridgeScreenshots/*"
---

# Bridge Trainer: screenshots

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

## Screenshots

`scripts/capture-screenshots.sh <udid> <out-dir> [prefix]` drives the real app
through the App Store screens via the `Screenshots` scheme.
`scripts/with-ipad-sim.sh` creates a throwaway 13-inch iPad (App Store iPad
shots must be 2064x2752 and the agent-sim pool has no iPad Pro), boots it
headless, and deletes it on exit:

```bash
./scripts/with-ipad-sim.sh sh -c './scripts/capture-screenshots.sh "$IPAD_UDID" out ipad_'
```

Gotchas baked into the test: the What's New sheet covers Home on the first
launch after a version bump and comes back every time Home reappears, so the
script passes the marketing version in through
`TEST_RUNNER_SCREENSHOT_APP_VERSION` and the test marks it seen; returning to
the root only taps navigation-bar button 0 while a back button is there,
because on Home that button is the Settings gear; and the test never calls
XCTFail, because a failing UI test spends ten minutes collecting simulator
diagnostics first.

## iPhone Duo capture

DEBUG only (`Bridge/Utilities/DuoScreenshotMode.swift`). `-DuoSeed` fills the
real stores with a week of practice (streak, mastery rings, three Bridge
Minutes, Bridge+ override; no RevenueCat, no network), once per install
(`duo.seeded`), so gh-sim's relaunch for the inner display shows the same week. `-DuoTour -DuoRoutes a,b,c` walks Home through
routes on a timer, because the capture job cannot tap and `simctl openurl`
raises a confirmation sheet. Routes: home, quick, room-<id>, drill-<id>,
stats, endless, minute, prep, timed, howto, settings, paywall. Dwell is
`-DuoTourStep` (outer, about 7s per screenshot) and `-DuoTourStepRegular`
(inner, about 12s). The tour restarts when the size class changes, so each
display gets a full walk, and it lives on the NavigationStack, not Home's root
(a pushed route would cancel a task there).

```bash
gh-sim launch --device 'iPhone Duo' --wait 6 \
  --args "-DuoSeed -DuoTour -bridge.suppressWhatsNew -DuoTourFirst 1 -DuoTourStep 8 -DuoTourStepRegular 13 -DuoRoutes quick,room-auction-room,stats" \
  --url noop://1 ... --url noop://8
```

The launch step has a 10 minute cap that includes boot and every screenshot, so
keep to about 5 routes and 8 urls per launch, and split bigger sets across
launches. `--record-seconds` eats the same budget. Never kill a watching
`gh-sim`; reattach with `gh-sim get <id>`. Sizes: outer 1398x2034, inner
2853x2007, both in `APP_IPHONE_DUO`.
