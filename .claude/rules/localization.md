---
paths:
  - "Bridge/Localizable.xcstrings"
  - "Bridge/Info.plist"
  - "Shared/Models/Drill.swift"
  - "Shared/Content/**"
  - "BridgeTests/LocalizationTests.swift"
  - "Tools/Localization/check.py"
  - "project.yml"
---

# Bridge Trainer: UI localization (2026-10-28)

The app ships in English plus da, de, el, es, fr, it, ja, ko, nb, nl, ru, sv,
th, tr and zh-Hant. The current markets with two or more new customers in the
last 90 days drove the additions of Spanish, Korean, Norwegian Bokmål, Russian
and Swedish.

## Setup

- `Bridge/Localizable.xcstrings` holds UI copy and authored teaching content.
  All 15 non-English locales must be present for each translatable key.
- `Bridge/Info.plist` lists `en` and all 15 locales in `CFBundleLocalizations`.
  There are no permission purpose strings, so there is no
  `InfoPlist.xcstrings`. The app name `Bridge Trainer` stays in English.
- The project currently has no widget, Watch, or App Intent targets. If one is
  added, keep it on the same catalog and declare the same locales in its plist.
- Keep the `TrialCTA` wording variants in the catalog. Offering metadata selects
  the variant, and StoreKit supplies prices.
- XcodeGen 2.39 or later reads the catalog and derives `knownRegions`. The
  project keeps `LOCALIZATION_PREFERS_STRING_CATALOGS` and
  `SWIFT_EMIT_LOC_STRINGS` enabled.
- `Tools/Localization/check.py` checks source literals, required languages and
  format specifiers. `BridgeTests/LocalizationTests.swift` checks authored
  content in every locale and Russian one/few/many plural resolution.
- Authored content stays English in `Shared/Content`. Each model (`Room`,
  `Drill`, `Flashcard`, `CardChoice`, `QuizQuestion`, `HandMatchQuestion`,
  `PlayScenario`, `HowToPlayPage`, `WhatsNewItem` and `WhatsNewRelease`)
  localizes copy once at init through `String.localizedContent` in
  `Shared/Models/Drill.swift`.

## Rules

- `Text("literal")` localizes itself. Copy held in a `String` (view params,
  enums, helpers, notifications, alerts, accessibility values and ternaries)
  uses `String(localized:)` or an already localized content value. Do not
  compose translated fragments into a sentence.
- Use whole UI phrases as keys. For generated coaching, use one complete key
  per sentence variant. Use catalog plural variations for count strings.
- Keep `Bridge+`, `Bridge Trainer`, `Bridge Minute`, card ranks A/K/Q/J and bid
  symbols such as `1NT` unchanged. Use the local bridge terms in prose:
  Norwegian uses *melding*, *grand* and *spillefører*; Swedish uses
  *budgivning*, *sang*, *spelförare* and *träkarlen*. Preserve each locale's
  standard suit and card-play vocabulary.
- Dates use `setLocalizedDateFormatFromTemplate` or `Date.FormatStyle`.
  Percentages use `.percent`; prices come from StoreKit.
- No em dashes in app copy.

## Adding or changing copy

1. Put the complete English key in code or authored content.
2. Add every target translation to `Bridge/Localizable.xcstrings`. Mark only
   format-only keys, the app name and debug-only copy with
   `shouldTranslate: false`.
3. Keep format specifiers intact. Use positional specifiers when a language
   needs a different word order.
4. Run `python3 Tools/Localization/check.py` and the `Bridge` test scheme.

## Remote screenshot checks

Use `gh-sim all` on GitHub-hosted Macs. DEBUG launch args include
`-AppleLanguages (de) -AppleLocale de_DE`, `-bridge.onboardingPage 4
-bridge.skillLevel new` for the trial page, and
`-progress.hasOnboarded YES -bridge.showPaywall YES
-bridge.suppressWhatsNew` for the paywall. `-DuoSeed` gives Home sample
progress and persists onboarded member state, so capture onboarding and trial
before seeded Home, and do not use it for paywall captures. Keep the bare
`-bridge.suppressWhatsNew` last so it is not read as another key's value.
RevenueCat remains disabled in simulator builds.
