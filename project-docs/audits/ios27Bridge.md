# iOS 27 compatibility audit: Bridge

- Audit date: 2026-08-05
- Runtime: iOS 27.0 (24A5390f)
- Xcode: 26.6 (17F113)
- Scheme: `Bridge`
- Unit target: `BridgeTests`
- Overall: Pass with concurrency warnings

## Checks

- Debug build: Pass.
- Unit tests: Pass.
- Normal rebuild after tests: Pass.
- Install and launch smoke test: Pass.
- Runtime UI snapshot: Pass. Onboarding rendered.

## Findings

- `Bridge/Utilities/Theme.swift:179,186,193` has main-actor-isolated haptic calls or initializers from synchronous nonisolated context.
- `Shared/Content/HandGenerator.swift:174` declares an unused `suit` value.
- `BridgeTests/ReviewPromptTrackerTests.swift`, `ProgressStoreTests.swift`, and `PracticeRecordStoreTests.swift` contain main-actor isolation warnings.
- No iOS 27-specific compiler error or runtime blocker was observed.

## Recommended follow-up

- Annotate the haptic construction/use path consistently with `@MainActor` or isolate the calls at the UI boundary.
- Clean the unused value and test concurrency warnings before enabling warnings-as-errors.
