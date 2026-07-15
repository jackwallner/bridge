# Bridge Trainer Project Guide

Bridge Trainer is a contract bridge drill app for newer players. It teaches card basics, Standard American opening bids, declarer play, and defense through short practice sessions. The XcodeGen project and scheme are `Bridge`; the dedicated headless simulator is `agent-bridge`.

## Build and test

```bash
xcodegen generate
xcodebuild test -project Bridge.xcodeproj -scheme Bridge -destination 'platform=iOS Simulator,name=agent-bridge'
```

Never open Simulator.app. After app-code pushes, run `./scripts/testflight.sh`.

## Product configuration

- Bundle ID: `com.jackwallner.bridge`
- RevenueCat entitlement: `Bridge+`
- Monthly: `com.jackwallner.bridge.monthly`, $1.99
- Yearly: `com.jackwallner.bridge.yearly`, $9.99
- Lifetime: `com.jackwallner.bridge.lifetime`, $29.99
- Membership name: Bridge+

RevenueCat is deliberately disabled in simulator builds. The public SDK key lives in `Shared/Services/SubscriptionService.swift`. App Store Connect credentials come from `~/.baseball_credentials` and must never be printed or committed.

## Architecture

- `Bridge/` contains the SwiftUI app, views, theme, assets, sounds, and StoreKit configuration.
- `Shared/Models/` contains cards, calls, drills, progress, and room models.
- `Shared/Content/` contains all authored lessons and practice questions.
- `Shared/Services/` contains persistence, reminders, review prompting, and subscriptions.
- `BridgeTests/` validates content and persisted state.

Teaching content uses a beginner Standard American framework. Partnership agreements vary, so avoid presenting conventions as universal rules. Do not imply affiliation with ACBL or any other bridge organization.

## Release workflow

Fastlane metadata is under `fastlane/metadata/en-US`. ASC setup and readiness scripts are under `scripts/`. The app uses a warm cream and jade visual system with high-contrast red and black playing cards.
