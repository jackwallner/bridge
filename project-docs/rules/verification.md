# Verification, 2026-10-22

- Swift engine/content XCTest: **35 passed, 0 failures**, using `python3 scripts/test-rules.py` (Swift 6, macOS XCTest, the same Foundation engine/content sources and test tables used by the iOS target).
- Android: **61 passed, 0 failures, 0 skipped**, using `fm-gradle --local testDebugUnitTest` from `android/`. In this wrapper, `--local` selects the remote Mac (`clawd-mac`/jmbp). Gradle did not run on the Air.
- XcodeGen: `xcodegen generate` passed.
- Git: `git diff --check` passed. Work is isolated in `fix/rules-audit-20261022`; original working-tree edits are preserved.
- Table SHA-256: `b55b00298d860174309e54d1e5a63bee3b28c7e0189261c7102f6dfd18d1bbc9`. XCTest and JUnit reference files are byte-identical.
- TestFlight: build 28 prepared, upload follows the code push. Final receipt will be recorded here.

The Swift runner selects engine, generator and content tests. It excludes UI/persistence/mastery cases from mixed files; it is not an iOS simulator UI run. The queued simulator attempt was canceled because the account had more than 30 queued jobs. The release archive separately verifies iOS application compilation.
