# Bridge Trainer Project Guide

Bridge Trainer is a contract bridge drill app for newer players. It teaches card basics, Standard American opening bids, declarer play, and defense through short practice sessions. The XcodeGen project and scheme are `Bridge`; runtime checks use a checked-out shared agent-sim group.

## Product configuration

- Bundle ID: `com.jackwallner.bridge`
- RevenueCat entitlement: `Bridge+`
- Monthly: `com.jackwallner.bridge.monthly`, $8.99
- Yearly: `com.jackwallner.bridge.yearly`, $34.99
- Lifetime: `com.jackwallner.bridge.lifetime`, $79.99
- Membership name: Bridge+

RevenueCat is deliberately disabled in simulator builds. The public SDK key lives in `Shared/Services/SubscriptionService.swift`. App Store Connect credentials come from `~/.baseball_credentials` and must never be printed or committed.

## Rules that hold everywhere
Condensed from the deep notes below; the reasoning behind each one lives there.
- A generated hand only reaches a player when exactly one of the six `HandCategory` answers is right. Keep `HandGeneratorTests.testAuthoredHandsMatchTheClassifier`: authored opening drills must agree with the engine that grades Endless Practice.
- The daily declarer question is built from the authored `PlayScenario`s, never through `SessionBuilder.choiceItems`.

## Architecture

- `Bridge/` contains the SwiftUI app, views, theme, assets, sounds, and StoreKit configuration.
- `Shared/Models/` contains cards, calls, drills, progress, and room models.
- `Shared/Content/` contains all authored lessons and practice questions.
- `Shared/Services/` contains persistence, reminders, review prompting, and subscriptions.
- `BridgeTests/` validates content and persisted state.

Teaching content uses a beginner Standard American framework. Partnership agreements vary, so avoid presenting conventions as universal rules. Do not imply affiliation with ACBL or any other bridge organization.

## Release workflow

Fastlane metadata is under `fastlane/metadata/en-US`. ASC setup and readiness scripts are under `scripts/`. The app uses a warm cream and jade visual system with high-contrast red and black playing cards.

## Deep notes (load on demand)
These files load automatically when you read a file matching their `paths:`. Agents that do not auto-load rules (AGENTS.md readers) should open the file for the area they are touching. Record new area-specific learnings in the matching file, not here.

| File | Covers | Read when |
|---|---|---|
| `.claude/rules/generated-practice.md` | Generated practice (1.1): `HandGenerator`, Fix My Mistakes, Timed Challenge, `PracticeRecordStore`, the What's New sheet | Generators, practice runs, stats, `WhatsNew` |
| `.claude/rules/game-night.md` | Game-night rhythm (1.2): Bridge Minute, the daily declarer question, game night prep | `BridgeMinute*`, `GameNightPrepView`, `SessionBuilder` |
| `.claude/rules/ipad-layout.md` | iPad (1.2): device family, `CenteringScrollView`, the pager eyebrow, the deck width cap | Drill layouts, Home columns |
| `.claude/rules/screenshots.md` | Screenshots: the capture script, the throwaway iPad, test gotchas | Capture scripts, the `Screenshots` scheme |
