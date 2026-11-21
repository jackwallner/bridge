# Low bug fixes, 2026-11-20

Fixes for the low bugs (B2 to B9) in `2026-11-20-bug-ux.html`. Base commit `813665a`.

Run ids below (all `gh-sim test`, GitHub Mac, Xcode 27.1, iPhone 17):

- Before run (base code plus the new tests, the three tests whose symbols do not exist on base removed): `bridge-before-imac60e5-1120-211955-24992`
- B7 UI test on base: `bridge-before-imac60e5-1120-220003-29837`
- B7 UI test on base with a fling counter: `bridge-before-imac60e5-1120-224708-20382`
- Final full suite: `bridge@20261120-211129-28b7-claude-imac60e5-1121-000141-8907`

| Id | Title | Outcome | Commit | Proof | What changed |
|---|---|---|---|---|---|
| B2 | English "1 more drills in this room", "Up 1 questions this week" | fixed | dc0ed2b | `LocalizationTests/testEnglishCountsAgreeWithTheirNumber`: failed on base ("1 more drills in this room"), passes in the final run | Added English one/other plural entries to `Localizable.xcstrings` for the 11 counted keys that had plurals in other languages only. |
| B3 | Bridge Minute day built from the phone's calendar | fixed | 8cd6b63 | `BridgeMinuteContentTests/testResultsSavedUnderANonGregorianKeyAreAdopted`: failed on base, passes in the final run. `testDayKeyDefaultsToTheGregorianCalendar` passes both (the test sim is Gregorian, so it cannot fail on base) | `challenge`, `key`, `shortDate` and `result(for:)` default to `Calendar.gregorianLocal`; `BridgeMinuteStore.init` moves results saved under a non-Gregorian key to the Gregorian key. |
| B4 | Timed Challenge clock only counts while the app runs | fixed | c4bfc12 | `PracticeRunScoringTests/testTimedChallengeClockFollowsTheWallClock` (new API, so it could not compile on base; passes in the final run). Behaviour itself is code read only | The run stores a deadline `Date` and each tick shows `secondsLeft(until:)`, so time away from the app counts and a long absence ends the run on return. |
| B5 | Day after a midnight clock change counts as the same day | fixed | b126dc6 | `ProgressStoreTests/testStreakGrowsAcrossAMidnightThatDoesNotExist`, `testGetStartedResetsAfterAMidnightThatDoesNotExist`, `testStreakGrowsAcrossAMidnightThatDoesNotExistInTheLastHourOfTheDay` (America/Santiago): all failed on base, pass in the final run | Stored days and "now" are both compared at noon, which every zone has, instead of start of day. |
| B6 | Ask to Buy shown as a raw English error | fixed | 085ed64 | `PurchaseEntitlementTests/testAskToBuySaysItIsWaitingForApproval`: failed on base (RevenueCat "error 20" text), passes in the final run; `testOtherPurchaseErrorsKeepTheirOwnMessage` passes | `SubscriptionService.purchase` turns RevenueCat's `paymentPendingError` into `PurchaseError.awaitingApproval` with a new localized line (15 languages). Paywall and onboarding both show `error.localizedDescription`, so both are covered by the one change. |
| B7 | Double tap on Next commits twice | disproven | none | UI test `FlashcardDoubleTapUITests` (not committed) on base code: passed in `...220003-29837` (deck at "1 of N down" after `doubleTap()` on Next). Instrumented base build in `...224708-20382`: `fling` was called exactly once (`flings=1`) | No code change. A real double tap never reached the Next action a second time on the unguarded code. |
| B8 | Paywall purchase button dead when prices loaded but membership did not | fixed | 20e82d9 | `PurchaseEntitlementTests/testPaywallReloadsWhenPricesLoadedButMembershipDidNot` (new helper, so it could not compile on base; passes in the final run). The paywall view itself is not reproducible on a simulator (RevenueCat is off there) | The paywall's `.task` reloads when the price or the membership is missing, and the existing "Retry loading prices" button shows (without the prices sentence) when only the membership is missing. |
| B9 | Onboarding trial button stays disabled after an offline first load | fixed | 9780f8a | `testTrialPageKeepsAskingUntilAFirstCustomerRecordLands` and `testTrialPageStopsAskingWhenLeft` (new API, so they could not compile on base; pass in the final run) | The trial page's task calls `resolveMembershipWhenReachable`, which re-reads the customer record every 5 seconds while the check is failing and stops when the page goes away. No new UI. |

Docs commit `70fa617` adds the retry, Ask to Buy and Bridge Minute calendar notes to the two rules files.

## Final run

- Run id: `bridge@20261120-211129-28b7-claude-imac60e5-1121-000141-8907`, 200 tests, 200 passed, 0 failed, 0 skipped.
- Started before the docs-only commits (this file and `70fa617`); no code changed after it.
- Tests that fail on the base commit and are not mine: none. The before run had 6 failures, all new tests for B2, B3, B5 and B6.
- Not run: the `BridgeUITests` and `BridgeScreenshots` schemes (only B7's throwaway UI test was run).

## For the reviewer

- B3 migration rule: a stored key counts as non-Gregorian when its year differs by more than one from the Gregorian year of `completedAt`. A result finished on a different day than its key year (manual clock change by years) would be moved, which is harmless.
- B3 left `completedThisWeek` and `archiveDates` on `Calendar.current` on purpose: both work on instants and day offsets, and a Gregorian calendar would change the locale's first weekday, so Monday-first regions would see their week count change.
- B2 did not touch `Locked. %lld drills, included with %@` (VoiceOver hint) or the "more drills across every room" line: the only locked room (Master Tables) has 4 drills and the total is always more than one, so "1 drills" is not reachable. `%lld day streak` and `%lld-day streak` already read correctly for 1.
- B6 detects the pending error with `error as? ErrorCode` and, failing that, the NSError domain and code. The unit test throws both forms; real Ask to Buy was not run (no StoreKit sandbox here).
- B7: the evidence shows one `fling` call, so the second tap did not reach the button on a simulator. I did not test a real device. The cataloger's missing `isFlinging` guard is real but unreachable as far as the test can tell, so I left the code alone as the brief says.

## For Jack

Nothing needs a decision. The Ask to Buy line is new English copy with 15 translations I wrote; a native check of the Korean and Thai lines would be worth a glance.
