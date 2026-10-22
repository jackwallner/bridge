# Verification, 2026-10-22

- Swift engine/content XCTest: **35 passed, 0 failures**, using `python3 scripts/test-rules.py` (Swift 6, macOS XCTest, the same Foundation engine/content sources and test tables used by the iOS target).
- Android: **61 passed, 0 failures, 0 skipped**, using `fm-gradle --local testDebugUnitTest` from `android/`. In this wrapper, `--local` selects the remote Mac (`clawd-mac`/jmbp). Gradle did not run on the Air.
- XcodeGen: `xcodegen generate` passed.
- Git: `git diff --check` passed. Work is isolated in `fix/rules-audit-20261022`; original working-tree edits are preserved.
- Table SHA-256: `e2967dce61b85ce2a61e7aed85e84d076a89cb166318081eaea7fbdbca774be4`. XCTest and JUnit reference files are byte-identical.
- TestFlight: 1.2.5 (28) uploaded and reached VALID. Build 29 includes the final strict SAYC copy corrections; its upload follows this code push.

The Swift runner selects engine, generator and content tests. It excludes UI/persistence/mastery cases from mixed files; it is not an iOS simulator UI run. The queued simulator attempt was canceled because the account had more than 30 queued jobs. The release archive separately verifies iOS application compilation.

The final SAYC teaching-copy table reproduced 14 failed assertions before correction. The corrected copy passes, including the booklet's 6-9 major-response 1NT and 10-11 dummy-point limit raise. Both engine suites were rerun afterward.

Scoring rows also verify the actual displayed quiz answers for passed-out boards, making a doubled partscore into game, and the fourth doubled nonvulnerable undertrick.
