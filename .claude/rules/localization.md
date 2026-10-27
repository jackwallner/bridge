---
paths:
  - "Bridge/Localizable.xcstrings"
  - "Bridge/InfoPlist.xcstrings"
  - "Shared/Models/Drill.swift"
  - "Shared/Content/**"
  - "BridgeTests/LocalizationTests.swift"
  - "project.yml"
---

# Bridge Trainer: UI localization (2026-10-27)

The app ships in en plus da, de, el, fr, it, ja, nl, th, tr and zh-Hant. Why:
RevenueCat showed non-English rich markets trialing at about 6% against 15 to
19% for US/UK/CA/AU at the same price, while the App Store pages were already
translated, so the drop happened inside the app.

## Setup

- `Bridge/Localizable.xcstrings` holds every UI string, the onboarding, the
  paywall, notifications, and all authored teaching content (about 790 keys).
  `Bridge/InfoPlist.xcstrings` holds the ATT purpose string. XcodeGen derives
  `knownRegions` from the catalogs; `project.yml` sets
  `SWIFT_EMIT_LOC_STRINGS` and `LOCALIZATION_PREFERS_STRING_CATALOGS`.
- Every entry is `extractionState: manual`. Format-only keys (`%lld`,
  `%@%lld`, `%lld/%lld`), the app name and the DEBUG-only Developer rows are
  `shouldTranslate: false`.
- Authored content stays plain English in `Shared/Content`. Each model
  (`Room`, `Drill`, `Flashcard`, `CardChoice`, `QuizQuestion`,
  `HandMatchQuestion`, `PlayScenario`, `HowToPlayPage`, `WhatsNewItem`,
  `WhatsNewRelease`) localizes its copy once at init through
  `String.localizedContent` (`Shared/Models/Drill.swift`), a catalog lookup by
  the English text. The compiler never extracts these keys, so
  `LocalizationTests` fails when one has no entry in some language.
- Churn chips in `ReviewPromptSheet` are sent to the feedback table in English;
  only the label is translated (`chip.localizedContent`).

## Rules

- `Text("literal")` localizes itself. Copy held in a `String` (view params,
  enums, copy helpers, notifications, alerts, a `Text(cond ? "a" : "b")`
  ternary) must be `String(localized:)`. Logs, analytics, RevenueCat metadata
  and identifiers stay plain.
- Whole sentences as keys, never fragments. Generated explanations
  (`HandGenerator.explain`, `EndlessPractice.pointExplanation`) branch into one
  key per variant. Singular/plural: catalog plural variations for single-number
  keys; an explicit `n == 1` branch when the key has more than one argument.
- Room names carry articles in several languages ("Der Kartenraum"), so a
  sentence that embeds one uses a colon form ("Extraübung: %@").
- Card ranks stay A, K, Q, J in every language because the card faces show
  them; words (Ass, roi, クイーン) are used only in prose. Bids keep the NT
  symbol, prose uses each language's notrump word. "Bridge+", "Bridge
  Trainer" and "Bridge Minute" stay untranslated.
- Dates use `setLocalizedDateFormatFromTemplate` or `Date.FormatStyle`
  (`BridgeMinuteContent.shortDate`), percentages use `.percent` formatting,
  prices only come from StoreKit.
- No em dashes in any language.

## Adding or changing copy

1. Write the English in code (`Text`, `String(localized:)`, or a content
   model init).
2. Add the key to the catalog with all ten translations. For compiler keys you
   can build once and run `xcrun xcstringstool sync Bridge/Localizable.xcstrings
   --stringsdata <DerivedData>/**/Bridge.build/**/*.stringsdata`; content keys
   must be added by hand.
3. Format specifiers must match the key; reorder with positional `%1$@`.
4. Run the tests: `LocalizationTests` covers the content keys.

## Simulator checks

DEBUG launch args for screenshots: `-AppleLanguages (de) -AppleLocale de_DE`,
plus `-bridge.onboardingPage 4 -bridge.skillLevel new` for the trial page or
`-progress.hasOnboarded YES -bridge.suppressWhatsNew -bridge.showPaywall YES`
for the paywall. RevenueCat is off on simulators, so the paywall shows the
"prices aren't available" state there.
