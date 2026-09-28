# Bridge Trainer audit

Audit date: 2026-08-23

Repository: /Users/jackwallner/bridge

Scope: read-only inspection of the app source, XcodeGen configuration, StoreKit configuration, ASC and fastlane assets, landing site, legal and support pages, tests, RevenueCat integration, paywall and onboarding paths, review funnel, analytics hooks, release scripts, and agent documentation. This file is for a separate implementation agent. No app code, configuration, metadata, assets, scripts, commits, uploads, or external services were changed.

## How to read this audit

* Evidence means a directly observed repository fact, with a path and line reference.
* Inference means the likely product, conversion, operational, or release consequence of that evidence. It is not a reported metric.
* Recommendation means a proposed change or experiment for the implementation agent.
* Confidence is confidence in the finding, not confidence in an unobserved business outcome.
* No live App Store Connect, RevenueCat, crash, download, trial, rating, or revenue metrics were accessed. Any metric in the implementation plan is a proposed measurement.
* Per instruction, this audit does not report inconsistencies about RevenueCat tracking or data-collection disclosures. RevenueCat was reviewed only for functional purchase, entitlement, restore, paywall, and instrumentation behavior.

## Executive priority list

| Priority | Finding | Why it matters first | Evidence |
| --- | --- | --- | --- |
| P0 | RevenueCat entitlement lookup key is not canonical across the app and setup script | A successful purchase can remain locked if the production entitlement is created or selected as pro while the app checks Bridge+ | Shared/Services/SubscriptionService.swift:4-8,170-174; scripts/rc-setup.py:78-93; CLAUDE.md:16-25 |
| P0 | Current prices and screenshot prices diverge, and release tooling still contains the old price ladder | A buyer can see stale prices in acquisition assets, while a future operator can overwrite ASC with old prices | Bridge/Bridge.storekit:6-84; fastlane/screenshots/en-US/04_screenshot.png; scripts/asc-setup-release.py:18-34; scripts/asc-set-prices.py:19-23; scripts/asc-create-lifetime.py:1-29; scripts/generate_metadata.py:5-12 |
| P0 | Screenshot capture can succeed while required captures failed | Incomplete or stale screenshots can reach ASC and lower download conversion or trigger a resubmission | BridgeScreenshots/ScreenshotTests.swift:13-17,43-79; scripts/capture-screenshots.sh:22-35; scripts/asc-upload-screenshots.py:1-22,81-84 |
| P1 | Marketing, release notes, What’s New, and local ASC state do not agree on the current version | New users and agents can receive stale release messaging, and an update can show no What’s New sheet | project.yml:29-35; Shared/Services/WhatsNew.swift:37-44,110-121; docs/index.html:56-60; scripts/.asc-state.json |
| P1 | Paywall and onboarding can present a purchase CTA before a usable package exists | A user can tap a loading or unavailable offer, hit a generic error, or receive weak price disclosure instead of a recoverable state | Bridge/Views/PaywallView.swift:144-212,215-285; Bridge/Views/OnboardingView.swift:231-239,318-350; Shared/Services/SubscriptionService.swift:92-131 |
| P1 | The trial claim is unconditional even when the Apple account is not eligible for an introductory offer | An ineligible user can see “7 days free” and a trial CTA that does not describe the actual transaction | Bridge/Views/PaywallView.swift:4-9,67-79; Bridge/Views/OnboardingView.swift:231-239,274-286; docs/terms.html:103-108 |
| P1 | Onboarding purchase does not confirm entitlement before continuing | A paid user can enter the tour while isPro is still false and see locked content immediately after payment | Bridge/Views/OnboardingView.swift:331-345; Shared/Services/SubscriptionService.swift:148-162 |
| P1 | There is no production crash, hang, degraded-UX, or purchase-funnel telemetry in the repository | A release regression cannot be detected from app events alone, and urgent multi-user failures need an external release watch | Bridge/BridgeApp.swift:3-23; Shared/Services/SubscriptionService.swift:78-102; repository-wide search found no MetricKit, crash reporter, os_log, Logger, or crash SDK |
| P1 | Review and support outcomes are mostly local and the support email differs | The owner cannot reliably connect a review ask to an outcome, and support links point to two different inboxes | Shared/Services/ReviewPromptTracker.swift:27-125; Bridge/Views/ReviewPromptSheet.swift:98-223; Shared/Services/ReviewPromptTracker.swift:4-18; docs/support.html:39-52 |
| P2 | The first Quick Session excludes Play scenarios and plain flashcards | The first value moment does not represent the full declarer and card-play promise in the store listing | Shared/Content/SessionBuilder.swift:51-55,169-227; fastlane/metadata/en-US/description.txt |
| P2 | Empty review state renders completion instead of a useful empty state | A stale review ID or empty queue can look like a completed run with no recovery path | Bridge/Views/Drills/PracticeRunView.swift:72-84 |
| P2 | Agent documentation is useful but versioned and duplicated operational truth is drifting | Cursor, Claude, and Codex agents can follow stale price, release, or runtime guidance | AGENTS.md:1-134; CLAUDE.md:1-134; ios27Bridge.md:1-28; scripts/generate_metadata.py:1-12 |

The recommended implementation order is: entitlement and price guards, screenshot pipeline hardening, purchase-state machine, version/source-of-truth reconciliation, release watchdog scaffolding, then funnel experiments and polish.

## Repository and product baseline

### Evidence inventory

The repository has 707 tracked files at audit time, including 54 Swift app/shared source files and 6 Swift test files. It contains 50 storefront localization directories under fastlane/metadata, plus a separate review_information directory. The root has no README.md. The only pre-existing worktree change at inspection start was the untracked audit823.md draft, which this file replaces.

The project is an XcodeGen iOS and iPadOS app:

* project.yml:2-5 uses the RevenueCat SPM package, from version 5.72.0.
* project.yml:6-14 targets iOS 17.0 and Swift 6.0.
* project.yml:15-35 defines bundle ID com.jackwallner.bridge, product name Bridge Trainer, marketing version 1.2.2, build 15, and device family 1,2.
* project.yml:39-50 defines BridgeTests.
* project.yml:51-93 defines the BridgeScreenshots UI test target and a separate Screenshots scheme.
* Bridge/Info.plist uses MARKETING_VERSION and CURRENT_PROJECT_VERSION and does not contain a tracking authorization prompt.
* Bridge/BridgeApp.swift:3-23 injects SubscriptionService, ProgressStore, AppSettings, and AppRouter into the root view.
* Bridge/RootView.swift:3-21 gates HomeView on the local hasOnboarded flag.

### Product and entitlement model

The local StoreKit configuration is:

| Product | Identifier | Local price | Intro offer | Evidence |
| --- | --- | ---: | --- | --- |
| Monthly | com.jackwallner.bridge.monthly | $8.99 | 1 week | Bridge/Bridge.storekit:29-59 |
| Yearly | com.jackwallner.bridge.yearly | $34.99 | 1 week | Bridge/Bridge.storekit:60-84 |
| Lifetime | com.jackwallner.bridge.lifetime | $79.99 | None | Bridge/Bridge.storekit:4-19 |

CLAUDE.md:16-25 repeats these identifiers and prices, and names the entitlement Bridge+. Shared/Services/SubscriptionService.swift:4-8 defines the same entitlement string. SubscriptionService is @MainActor, configures RevenueCat once, refreshes customer information and offerings asynchronously, maps the three plans to the current offering, purchases a package, polls for the entitlement, and restores purchases.

Free content is intentionally substantial:

* Shared/Content/DrillLibrary.swift:3-75 defines four free rooms, Card, Auction, Declarer, and Defense, plus the paid Master Tables room.
* Shared/Models/Drill.swift:107-127 locks paid drills and the paid room for nonmembers.
* Shared/Content/EndlessPractice.swift:10-147 creates generated opening and point-count practice, both mapped to the Auction Room.
* CLAUDE.md:27-57 documents Endless, Timed, Review, the practice record store, and free Stats.
* CLAUDE.md:83-99 documents the Bridge Minute and Game Night Prep Bridge+ features.
* Bridge/Views/HomeView.swift:355-440 presents Endless Practice, Bridge Minute, Game Night Prep, Timed Challenge, and Fix My Mistakes.

The value proposition is credible, but the first value experience is a long sequence and the monetization configuration has several hard failure modes. The audit below separates those functional risks from experiments.

## Download growth and App Store optimization

### Current storefront metadata counts

Counts below are exact counts from the local text files after removing only the final CR/LF. They use Python Unicode string length, not UTF-8 byte length. The six ASC-limited fields are compared with limits 30, 30, 100, 4000, 170, and 4000 respectively. No storefront field exceeded its local limit.

#### en-US exact counts

| Field | Count | ASC limit | Evidence |
| --- | ---: | ---: | --- |
| name | 27 | 30 | fastlane/metadata/en-US/name.txt |
| subtitle | 30 | 30 | fastlane/metadata/en-US/subtitle.txt |
| keywords | 95 | 100 | fastlane/metadata/en-US/keywords.txt |
| description | 2383 | 4000 | fastlane/metadata/en-US/description.txt |
| promotional_text | 167 | 170 | fastlane/metadata/en-US/promotional_text.txt |
| release_notes | 645 | 4000 | fastlane/metadata/en-US/release_notes.txt |
| marketing_url | 36 | URL | fastlane/metadata/en-US/marketing_url.txt |
| privacy_url | 51 | URL | fastlane/metadata/en-US/privacy_url.txt |
| support_url | 44 | URL | fastlane/metadata/en-US/support_url.txt |
| copyright | 17 | metadata | fastlane/metadata/en-US/copyright.txt |

The current en-US positioning is:

* Name: Bridge Trainer: Learn & Bid.
* Subtitle: Bridge Bidding & Card Practice.
* Keywords: bridge,bidding,cards,contract,learn,tutor,beginner,lesson,drill,defense,declarer,practice,quiz.
* The description leads with five-minute sessions, describes four free rooms, describes Bridge+ as optional, explains the Standard American framework, and contains a price-free subscription paragraph.
* Promotional text leads with five-minute bridge drills for bidding, declarer play, and defense.
* Release notes describe Bridge Minute, Game Night Prep, iPad support, and their Bridge+ gating.

The subtitle is exactly at the limit. The promotional text is three characters below the limit. The keywords field has five characters of capacity but repeats terms already covered by the name or subtitle, including bridge, bidding, and practice. This is an opportunity, not proof that a replacement will rank better. Proposed keyword variants should be tested against ASC product page conversion and organic acquisition after a sufficient observation window.

#### Locale coverage and ranges

There are 50 storefront locales. review_information is not a storefront locale and should not be counted as one. All 50 storefront directories have the required name, subtitle, keywords, description, promotional_text, release_notes, marketing_url, privacy_url, support_url, and copyright files.

| Locale | Name | Subtitle | Keywords | Description | Promo | Release notes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| en-US | 27 | 30 | 95 | 2383 | 167 | 645 |
| en-GB | 27 | 30 | 95 | 2384 | 167 | 645 |
| en-CA | 27 | 30 | 95 | 2384 | 167 | 645 |
| en-AU | 27 | 30 | 95 | 2384 | 167 | 645 |
| es-ES | 30 | 29 | 96 | 2688 | 169 | 584 |
| fr-FR | 24 | 25 | 98 | 2886 | 168 | 631 |
| ja | 28 | 26 | 95 | 1518 | 81 | 277 |
| zh-Hans | 24 | 24 | 94 | 1080 | 64 | 205 |
| ar-SA | 27 | 25 | 99 | 2267 | 139 | 427 |
| ta-IN | 29 | 29 | 99 | 2619 | 169 | 642 |
| tr | 26 | 28 | 100 | 2696 | 166 | 559 |

Across all 50 storefront locales, observed ranges are:

* Name: 24 to 30.
* Subtitle: 24 to 30.
* Keywords: 94 to 100.
* Description: 1080 to 2886.
* Promotional text: 64 to 170.
* Release notes: 200 to 645.

Recommendation:

1. Preserve the price-free description pattern in fastlane/metadata. It is safer across storefront price tiers than the stale generator output described below.
2. Reclaim the five unused en-US keyword characters with terms not already indexed by the name or subtitle, after checking ASC search and competitor language. Do not blindly add punctuation or repeat high-volume terms.
3. Build a locale QA report that flags untranslated English paragraphs, accidental fallback text, terms that refer to a feature not available in that locale, and mismatched localized screenshots. A count pass alone cannot prove localization quality.
4. Add a metadata source manifest containing the canonical app version, product identifiers, legal URLs, and feature names. Generate or validate the website and release notes from it.
5. Track product-page views, conversion to download, download-to-first-session, trial-start rate, paid conversion, and refund or cancellation guardrails by storefront and metadata variant. These are measurement requirements, not current results.

### Metadata risks and stale generators

Evidence:

* scripts/generate_metadata.py:1-12 explicitly warns that its copy contains the old $1.99, $9.99, and $29.99 prices and says running it would put wrong prices into all 50 locales.
* scripts/generate_metadata.py:21-24 writes directly into fastlane/metadata.
* scripts/generate_metadata_all.py contains the same old price ladder throughout its localized data and writes all fields.
* scripts/asc-upload-metadata.py:68-77 uses the fallback keyword string bridgeongg,practice,learn when creating a missing localization.
* scripts/asc-add-missing-localizations.py:232 uses the same bridgeongg fallback.
* fastlane/metadata is currently price-free, which is the safer local source of truth.

Inference: the repository contains a dangerous path where a well-intentioned agent can run a stale generator and overwrite otherwise safer metadata. The bridgeongg fallback is also a direct ASO quality defect if a locale is ever created through that path.

Recommendation:

* Immediately make old generators fail with a nonzero exit status unless they are rewritten to read the canonical source.
* Remove old prices from executable source, or move the files to a clearly named archive that the fleet scanner excludes.
* Make upload scripts reject any old price token, bridgeongg, or a missing canonical product manifest before writing ASC.
* Treat fastlane/metadata as the current copy source only after adding a validation command that checks every locale.

Validation:

* Run a read-only metadata audit that checks all 50 locales, all six length limits, required fields, duplicate fallback hashes, old price tokens, bridgeongg, URL shape, and version references.
* Run the upload command in a dry-run mode and show a zero-write diff before enabling a write.
* Add a regression test that fails if either stale generator can write a current storefront file.

### ASC readiness coverage

scripts/asc-readiness.py:1-92 is correctly described as read-only. It reports the editable version, attached build, recent build processing, en-US screenshot-set counts, age-rating declaration, IAP and subscription records, and the app price schedule. It does not currently report:

* All-locale metadata presence or exact character counts.
* Trial introductory offers and eligibility configuration.
* RevenueCat entitlement, current offering, or package mapping.
* Screenshot dimensions, names, asset hashes, or stale local files.
* Website, privacy, terms, support, or redirect health.
* Version agreement with project.yml, WhatsNew, the website, and operational state files.

Recommendation: keep this script read-only, but add separate checks or a composed readiness report. Do not make a readiness report green when only en-US screenshot counts and ASC object presence are known.

## Screenshot, icon, video, and landing-page acquisition quality

### Asset inventory and visual inspection

Observed local image inventory:

* fastlane/screenshots/en-US/01_screenshot.png through 04_screenshot.png: 1320 x 2868, RGB PNG.
* fastlane/screenshots/en-US/ipad_01_quick_session.png through ipad_06_card_room.png: 2064 x 2752, RGB PNG.
* docs/appstore-screenshot-01.png through 04.png: 1320 x 2868, RGB PNG.
* AppPreviewScreenshots/01-home.png through 04-paywall.png: 1206 x 2622, RGBA PNG.
* docs/screenshots/01-home.png through 04-paywall.png: 1206 x 2622, RGBA PNG.
* Bridge/Assets.xcassets/AppIcon.appiconset/icon-1024.png: 1024 x 1024, RGB PNG.
* docs/icon_256.png: 256 x 256, RGB PNG.
* No local video or app preview movie file was found in the inspected screenshot and docs asset paths.

Visual evidence from the inspected assets:

* fastlane/screenshots/en-US/01_screenshot.png has a strong “Learn Bridge” headline, a clear Home screen, visible free rooms, and a visible Bridge+ Master Tables lock. It communicates the free breadth and the paid depth well.
* fastlane/screenshots/en-US/04_screenshot.png has a clear premium headline and plan hierarchy, but it visibly renders the old $9.99 yearly, $29.99 lifetime, and $1.99 monthly prices. It is not safe to use with the current local $34.99, $79.99, and $8.99 product configuration.
* fastlane/screenshots/en-US/ipad_01_quick_session.png is readable and uses real app UI, but its large empty upper and lower regions make the iPad product story feel sparse. The first iPad screenshot should use the larger surface for a hero, progress, or a more informative Home composition.
* The app icon is a simple, high-contrast ace-of-spades card on green. It is legible at the inspected 1024 x 1024 size. A byte or perceptual hash check should ensure docs/icon_256.png and any public preview icon remain the same brand asset.

The screenshot story currently communicates:

1. Home and four free rooms.
2. Quick Session question flow.
3. Answer and coaching.
4. Bridge+ paywall.

That order is reasonable for downloads, but the paywall image creates a price-trust defect and the first iPad image underuses the platform. The absence of a preview video is not automatically a problem, but it is a missed testable acquisition surface for a visually simple five-minute practice loop.

### Screenshot pipeline findings

BridgeScreenshots/ScreenshotTests.swift:43-72 captures six named surfaces, including Quick Session, Opening, Lead or Hold, Declarer, Home, and Card Room. However:

* BridgeScreenshots/ScreenshotTests.swift:13-17 records problems but does not fail the test.
* BridgeScreenshots/ScreenshotTests.swift:43-79 continues after a failed capture.
* scripts/capture-screenshots.sh:22-35 extracts the app version, runs the Screenshots scheme, and uses an “echo and continue” path when the test fails.
* scripts/asc-upload-screenshots.py:1-22 assumes one iPhone display type and does not validate pixel dimensions or semantic filenames before upload.
* scripts/asc-upload-screenshots.py:81-84 deletes existing screenshots before uploading new ones.
* CLAUDE.md:115-134 documents the capture gotchas and explicitly notes that the test never calls XCTFail.
* scripts/asc-upload-screenshots.py:2-5 calls the project “iPhone-only” even though project.yml:15-35 targets iPhone and iPad.
* fastlane/Fastfile:14-24 downloads into a temporary directory with force enabled, and fastlane/Fastfile:28-44 uploads metadata and screenshots with force enabled and no submit. This is useful operationally but needs a preflight and dry-run guard.

Inference: a capture failure can produce a green-looking operational run with a partial or stale asset directory, then a destructive upload can remove known-good ASC screenshots before the replacement set is proven.

Recommendation:

* Make the capture runner produce a manifest with six expected UI capture names, four iPhone upload assets, six iPad upload assets, dimensions, file hashes, source build, and timestamp.
* Fail if any expected capture is missing, if the capture test records a problem, if dimensions do not match the display family, or if a screenshot is older than the source build.
* Do not delete remote screenshots until the local manifest passes and a dry-run diff is reviewed.
* Keep the separate iPhone and iPad upload paths explicit. Do not let an iPad asset be accidentally uploaded to the iPhone display family.
* Add a visual review checklist for text clipping, dynamic type, price accuracy, legal footer visibility, lock badges, and screenshot order.
* Add a test that the paywall screenshot price comes from the same canonical product manifest as the current StoreKit and ASC configuration.

Validation:

* Capture on a fresh install and a returning install with What’s New already marked.
* Assert the exact expected file names and dimensions.
* Compare the captured paywall price strings with the current localized product fixture.
* Simulate one failed screen and prove the command exits nonzero without deleting remote assets.

### Website and landing-page growth

docs/index.html:8-22 sets the title, description, canonical URL, app ID, and OG image. docs/index.html:23-65 contains JSON-LD for the app, including products at 8.99, 34.99, and 79.99, but softwareVersion is 1.2.0 at line 60. docs/index.html:499-650 presents the five-minute positioning, four rooms, Bridge+, iPhone screenshots, privacy summary, pricing, iOS 17 requirement, and App Store CTA.

Positive evidence:

* The site has a focused promise, “Bridge, in five minutes a day.”
* It presents four free rooms before the paid upgrade.
* It describes Bridge+ as additional volume and depth, rather than charging for beginner basics.
* It includes a functioning App Store ID in JSON-LD and the public product link.
* It has a visible privacy summary and links to support, privacy, and terms.

Growth and consistency opportunities:

* Change or generate the JSON-LD softwareVersion from the current release source. It currently says 1.2.0 while project.yml says 1.2.2.
* Add iPad to the top-level platform promise. project.yml:15-35 and CLAUDE.md:101-113 show first-class iPad support, but docs/index.html:506-519 frames the visual story as iPhone.
* Make the App Store URL and product version come from one manifest. The landing page currently contains a hardcoded US App Store URL and hardcoded JSON-LD prices.
* Add distinct, non-PII campaign parameters to the landing page and record the source before the App Store handoff. Measure page view to store click, not just page views.
* Test a first-screen hero built around the product’s actual first value, such as “Answer one bridge question in five minutes,” against the current broad “Learn Bridge” framing.
* Test a short real interaction video or animated preview against the static screenshot story. The repository has no local movie asset, so no current video claim is made.
* Preserve the no-account and offline core promise, but clarify that purchase and restore require Apple services. The current page says the app works offline while the app also refreshes offerings at launch.

The GitHub workflow .github/workflows/sync-landing-page.yml:1-31 syncs docs changes into an external portfolio repository. Treat the mirror as a release dependency: a passing local docs change is not proof that the public mirror updated. The fleet watchdog should check the workflow result and compare a public page checksum or version marker after a docs release.

## Install to first value to trial flow

### Current journey

| Stage | Current behavior | Evidence | Conversion or UX concern |
| --- | --- | --- | --- |
| Fresh launch | RootView branches to OnboardingView until local hasOnboarded is true | Bridge/RootView.swift:3-21 | No direct first drill before the introductory sequence |
| Value page 1 | Five-minute habit promise | Bridge/Views/OnboardingView.swift:50-55 | Good promise, but no measurable page-level event |
| Value page 2 | Flashcards, points, opening bids, card play | Bridge/Views/OnboardingView.swift:57-61 | Broad promise is not matched by the first Quick Session content mix |
| Value page 3 | Plan a contract and defend, without timers or opponents | Bridge/Views/OnboardingView.swift:63-67 | Good anxiety reduction, but another tap before value |
| Skill selection | Brand new, Know basics, Played real games | Bridge/Views/OnboardingView.swift:120-130 | The choice changes primer behavior, but there is no observed measurement of the choice |
| Trial page | Bridge+ benefits, no plan cards, monthly direct trial CTA | Bridge/Views/OnboardingView.swift:195-239 | Trial is requested before the user has answered a real question |
| Free escape | Get Started appears on the trial page and routes to the tour | Bridge/Views/OnboardingView.swift:241-300 | Escape exists, but it still adds a tour before Home |
| Trial purchase | ensureOfferings, monthly package, Apple purchase sheet | Bridge/Views/OnboardingView.swift:318-350 | Package can be absent or still unavailable; post-purchase entitlement is not confirmed |
| Trial cancel | Cancellation leaves the user on the trial page | Bridge/Views/OnboardingView.swift:339-346 | Correctly non-destructive, but cancellation is not instrumented |
| Fallback paywall | Missing monthly package presents the full PaywallView | Bridge/Views/OnboardingView.swift:81-90,334-337 | Full paywall can recover the path, but failure cause is not explained |
| New-player primer | Six-page How to Play before the feature tour | Bridge/Views/HowToPlayView.swift:21-66,98-134 | A new player can require 5 intro pages plus 6 primer pages before the app |
| Feature tour | Four pages, with skip on every page, final real Quick Session | Bridge/Views/FeatureTourView.swift:67-144 | First value exists, but only after a long serial funnel |
| Home | Get Started creates a 10-item Quick Session | Bridge/Views/HomeView.swift:261-296 | The content is choice-only and excludes Play scenarios |

### Onboarding detours and state coverage

The implementation agent should validate every path below, not only the happy path:

1. Fresh install with network and StoreKit products available.
2. Fresh install with no network before the trial page.
3. Fresh install with RevenueCat configured but current offering nil.
4. Fresh install where StoreKit has a monthly product but no introductory offer for the Apple account.
5. Skill selection with no selection. The primary button is disabled at OnboardingView.swift:286-287.
6. Trial CTA while the price is still loading.
7. Trial CTA with monthly package missing.
8. Apple purchase sheet canceled.
9. Purchase throws a product-unavailable error.
10. Purchase returns success but entitlement refresh is delayed.
11. Restore tapped on onboarding with a valid purchase.
12. Restore tapped on onboarding with no purchase.
13. Restore tapped on onboarding while offline or RevenueCat is unavailable.
14. Terms and privacy links opened from the trial page.
15. Get Started exit from the trial page.
16. New player skips How to Play.
17. Existing player skips the feature tour.
18. Feature tour final Quick Session closed before answering.
19. What’s New presented on a returning user after an update.
20. What’s New asks for an upgrade and then returns to the intended destination.

The onboarding Restore action is a known defect: OnboardingView.swift:292-294 calls restore in a Task and discards the error and result. A user can tap Restore and receive no indication that the tap did anything. SettingsView.swift:146-156 has a better alert/message path and should be the behavioral reference.

The onboarding purchase path has a separate defect: OnboardingView.swift:339-345 starts the tour immediately after PurchaseOutcome.purchased. PaywallView.swift:299-313 calls confirmEntitlement after purchase, but onboarding does not. The user can therefore see the tour or Home while isPro is still false. Add the same entitlement confirmation or a shared purchase coordinator before entering the next state.

### First-value design and experiments

SessionBuilder.quickSession defaults to 10 items at Shared/Content/SessionBuilder.swift:78-98. Its choicePool explicitly excludes plain flashcards and Play scenarios at lines 51-55 and 169-227. The daily Bridge Minute deliberately adds a declarer scenario elsewhere, but the first Get Started path does not.

Inference: the first answer can prove that the quiz mechanics work, but it does not fully prove the store promise of card play and declarer practice. This is a product hypothesis, not a measured conversion claim.

Recommended experiments:

* Variant A, current flow: intro, skill question, trial decision, primer or tour, Quick Session.
* Variant B: intro, skill question, one free representative question, answer explanation, then trial decision.
* Variant C: intro, skill question, direct Home with a highlighted free room and a short first drill.
* Test a 5-item first session against 10 items. Primary metric is first-session completion, with next-day return and trial start as secondary metrics.
* Add one Play scenario or a clearly labeled declarer decision to a first-session variant. Measure comprehension and completion rather than assuming richer content wins.
* Make the tour skippable by default after one value moment, and compare against the current serial tour.
* Preserve the free exit and measure whether it reduces trial starts while increasing first-session completion and later trial starts.

Use a deterministic, persisted variant assignment. Do not infer experiment success from one day of trial starts. Require a guardrail for crash-free sessions, first-answer completion, purchase errors, and refund or cancellation.

## Paywall, offerings, trial, purchase, restore, and legal states

### Current paywall surface map

The app has one custom SwiftUI PaywallView around RevenueCat offerings, with multiple entry sources:

| Source ID or path | Entry | Return behavior | Evidence |
| --- | --- | --- | --- |
| bridge_onboarding_fallback | Onboarding after monthly package is absent | paywallDismissed only rejoins if isPro | Bridge/Views/OnboardingView.swift:81-90,360-365 |
| bridge_home_sheet | Home upgrade card or a locked training tile | Sheet dismisses to Home | Bridge/Views/HomeView.swift:443-465,576-613 |
| bridge_room_sheet | Locked drill row or room upsell | Sheet dismisses to Room | Bridge/Views/RoomView.swift:73-90,140-170 |
| bridge_settings_sheet | Settings membership button | Sheet dismisses to Settings | Bridge/Views/SettingsView.swift:133-158 |
| What’s New upgrade route | Update sheet callback | Home delays and presents paywall | CLAUDE.md:59-64; Bridge/Views/HomeView.swift:87-100,172-180 |
| game-night notification route | AppRouter opens intended destination | Nonmember is routed to paywall before destination | Bridge/AppRouter.swift:10-59; Bridge/Views/HomeView.swift:172-180 |

The feature tour does not use a paywall directly. It shows a locked Bridge+ beat and then provides a free final Quick Session, which is a good education-first pattern.

### Paywall content and native-style knobs

PaywallView.swift:20-54 presents the Bridge+ promise and four benefits. PaywallView.swift:67-80 presents Yearly first, Monthly second, and Lifetime third. PaywallView.swift:144-212 computes localized prices, annual per-month equivalent, monthly anchor, and savings badge. PaywallView.swift:215-285 handles the sheet, impression, offering load, CTA, footer, and dismiss-on-entitlement.

The current screen is not RevenueCat’s hosted native paywall. It is a custom SwiftUI paywall that consumes RevenueCat offerings. The practical native-style knobs available to test are:

* Current offering and package availability.
* Package order.
* Default selected plan.
* Yearly, monthly, or lifetime default.
* Savings badge and annual per-month equivalent.
* Monthly anchor price.
* Intro-offer eligibility and trial wording.
* Source-specific headline, benefit order, and CTA.
* Close affordance, including the current “Close” button visible in the inspected paywall screenshot.
* Restore placement and loading state.
* Terms, privacy, and manage-subscription links.
* Price loading placeholder.
* Error and retry presentation.
* Safe-area placement of the billed-amount microcopy and purchase CTA.

### State-by-state findings

#### Loading and unavailable offerings

SubscriptionService.loadOfferings at Shared/Services/SubscriptionService.swift:92-102 uses try? and leaves offerings nil on error. ensureOfferings at lines 122-131 retries once if current is nil but returns only a Boolean and does not retain a user-facing error.

PaywallView.swift:148 uses “Loading price…” while PaywallView.swift:159-161 and 246-258 can leave plan cards and CTA visible. PaywallView.swift:299-305 attempts ensureOfferings again but does not guard the CTA with package availability before purchase.

Inference: the user can see a polished purchase surface that is not actually ready. Tapping the CTA can end in productsUnavailable or a generic localized error. Onboarding has the same problem, with an explicit fallback only after the monthly package is absent.

Recommendation:

* Model offering state explicitly: idle, loading, ready, unavailable, failed, retrying.
* Disable a plan card and the CTA if its package is absent.
* Show an actionable “Try again” path and an offline explanation.
* Keep the already loaded price on screen while a refresh is in flight.
* Include source and selected plan in the error telemetry.

#### Trial eligibility and inaccurate copy

PaywallPlan.ctaTitle at PaywallView.swift:4-9 always calls the monthly and yearly action “Start 7-Day Free Trial”. PaywallContent.planCards at lines 67-79 always says “7 days free” for yearly and monthly. OnboardingView.monthlyDisclosure at lines 234-239 also defaults to “Includes 7 days free” when no price is available. docs/terms.html:103-108 correctly limits the offer to accounts that Apple shows as eligible.

The local StoreKit file includes an introductory offer, but the runtime does not visibly branch on whether the current Apple account is eligible. The implementation agent should not assume that a configured introductory offer means every customer sees it.

Recommendation:

* Read the product’s current introductory offer and eligibility state before constructing trial copy.
* Use “Continue with Monthly” or equivalent when no trial is available, and show the actual renewal price.
* Keep the full legal eligibility language near the CTA.
* Test eligible, ineligible, previously subscribed, restored, and storefront price cases.

#### Purchase success, cancellation, and delayed entitlement

SubscriptionService.purchase at Shared/Services/SubscriptionService.swift:133-145 maps a canceled StoreKit transaction to a normal PurchaseOutcome.cancelled. This is correct for keeping the user in context. PaywallView confirms entitlement at lines 312-313. Onboarding does not confirm it, as described above.

The service polls three times with a 1.2 second delay at Shared/Services/SubscriptionService.swift:148-162. It does not expose the latency or final failure as a durable event. If the entitlement is not active, PaywallView displays a “purchase went through” message and points to Restore. This is a good recovery message, but the same behavior should be shared with onboarding.

Validation:

* Sandbox monthly, yearly, and lifetime purchase.
* Cancel Apple’s purchase sheet.
* Delay or interrupt the entitlement refresh.
* Relaunch after a purchase.
* Verify the intended locked drill opens after unlock.
* Verify no double charge occurs when the user taps Restore after delayed unlock.

#### Restore

PaywallView.restore at lines 323-336 has a loading flag, success/no-purchase message, and error message. SettingsView.swift:146-156 has a separate message path. OnboardingView.swift:292-294 is the outlier with no result.

Recommendation: create one restore coordinator with a consistent result enum and use it in onboarding, paywall, and Settings. Instrument restore_started, restore_succeeded, restore_empty, and restore_failed. Validate Apple account mismatch, offline, RevenueCat outage, and already active entitlement.

#### Legal links and billing copy

PaywallLinks.terms and PaywallLinks.privacy are in PaywallView.swift:12-18. The paywall footer is at lines 288-297. The local copy includes renewal wording and the current product amount when available. Terms and privacy are visible on onboarding and the full paywall.

Required validation:

* Terms opens Apple’s standard EULA and returns.
* Privacy opens the public page and returns.
* The no-price loading state does not imply a specific amount.
* The exact localized currency and billing period are visible before confirmation.
* The copy changes when the introductory offer is not available.
* Links work on iPhone, iPad, and with no network.

#### Accessibility and degraded UI

The relevant views use custom typography and card controls. PlayDrillView.swift:40-54 disables card buttons after an answer. This may dim the selected and correct cards and can change VoiceOver focus behavior. The other drill controls need a similar pass for answer state, focus order, and spoken result.

PracticeRunView.swift:143-150 provides a Finish or Close button for endless and review modes, but not for timed mode. Timed mode starts a task clock at lines 224-234 and ends automatically. Validate that a player can navigate away without a stuck task, that the timer stops on disappearance, and that a low-power or background transition does not produce a misleading score.

Progress bars commonly use the zero-based index as the value, for example PlayDrillView.swift:27 and PracticeRunView.swift:173-175. Validate that the first question and final question communicate progress as users expect, and that the final state reaches a meaningful complete value.

There are no dedicated VoiceOver, Dynamic Type, contrast, reduced motion, or keyboard-navigation UI tests in the inspected test target. Add a smoke matrix rather than relying only on content unit tests.

## RevenueCat integration, attributes, and events

### Existing behavior

Shared/Services/SubscriptionService.swift:4-8 defines the public SDK key, entitlement Bridge+, and membership constants. The service deliberately returns before configuring RevenueCat in simulator builds at lines 61-75. This protects production charts from simulator customers.

The only explicit analytics call observed is:

* Shared/Services/SubscriptionService.swift:78-90, trackPaywallImpression, which calls RevenueCat CustomPaywallImpressionParams with the paywall ID and can be once-per-session.

SubscriptionService.refreshCustomerInfo and loadOfferings at lines 92-102 suppress errors. Purchase and restore outcomes are not recorded as a general event stream. A repository-wide search found no MetricKit, Crashlytics, Sentry, Firebase Analytics, Amplitude, Mixpanel, os_log, Logger, or other crash/event pipeline.

### Critical entitlement configuration finding

The app checks entitlement “Bridge+” in Shared/Services/SubscriptionService.swift:4-8 and 170-174. CLAUDE.md:19 and fastlane/metadata/review_information/notes.txt:9-18 also describe Bridge+.

scripts/rc-setup.py:78-93 searches for either lookup_key pro or Bridge+. If neither exists, it creates lookup_key pro with display_name Bridge+. scripts/rc-setup.py:95-111 then attaches products to whichever it selected. Bridge/Utilities/Theme.swift:96-100 contains a stale comment saying the RevenueCat entitlement is still pro.

Evidence-based inference: an environment initialized by the setup script can contain a lookup key pro while the app only reads Bridge+. In that state StoreKit or RevenueCat can report a successful purchase but the UI can continue to show locked content. This is a P0 functional and revenue risk. No live RevenueCat state was inspected, so this audit does not claim that production currently has the wrong key.

Recommendation:

1. Make Bridge+ the only accepted canonical lookup key in the setup and audit scripts.
2. Make the setup script fail if a legacy pro entitlement exists instead of silently selecting it.
3. Add a read-only RevenueCat configuration check that prints the entitlement lookup key, attached product IDs, current offering, package lookup keys, and environment without printing secrets.
4. Test monthly, yearly, lifetime, restore, relaunch, and delayed entitlement in sandbox.
5. Remove or update stale comments so an agent cannot infer that pro is still valid.

### Proposed bounded attributes

RevenueCat customer attributes are latest-state context, not a durable event log. Keep them low-cardinality, non-PII, and bounded. Do not put email addresses, free-form feedback, hand text, question IDs, or review prompt text into customer attributes.

Add a small SubscriptionService context wrapper, then call it at these exact locations:

| Attribute | Suggested value | Insertion location | Reason |
| --- | --- | --- | --- |
| app_version | Bundle short version | SubscriptionService.start, after configureIfNeeded and before async refresh at lines 46-53 | Segment releases |
| build_number | Bundle build | Same location | Separate TestFlight or production builds |
| device_family | phone or pad | Same location | Detect iPad-specific degradation |
| locale | Locale.current.identifier | Same location | Segment storefront and copy |
| onboarding_skill_level | new, basics, games | OnboardingView skill selection closure, around lines 156-160 | Explain flow variation |
| paywall_surface | source ID | PaywallView.task at lines 281-284 and onboarding page tracking at lines 77-80 | Compare entry points |
| selected_plan | yearly, monthly, lifetime | Paywall plan selection and immediately before SubscriptionService.purchase at lines 133-145 | Understand plan intent |
| purchase_state | active, inactive, pending, error | SubscriptionService.apply at lines 170-174 | Diagnose unlock state |
| last_restore_result | restored, empty, failed | SubscriptionService.restore at lines 164-168 | Diagnose recovery |
| last_positive_surface | drill, bridge_minute | DrillCompleteView.swift:75-99 and BridgeMinuteView.swift:284-296 | Relate review prompts to value moments |

Use an explicit “set only after value exists” rule for onboarding_skill_level and last_positive_surface. Do not repeatedly write attributes on every render.

### Proposed event contract and insertion locations

The repository needs a separate event abstraction if event history is required. RevenueCat attributes alone cannot answer conversion funnels. If RevenueCat is used for latest-state context, keep event delivery in a separate consented, privacy-reviewed telemetry layer. The events below are names and payloads for the implementation agent, not evidence that they currently exist.

| Event | Insert at | Required properties |
| --- | --- | --- |
| onboarding_page_viewed | OnboardingView page change around lines 77-80 | page index, skill level if known, app version |
| onboarding_trial_viewed | Same lines when page reaches lastPage | source bridge_onboarding_trial, skill level |
| trial_cta_tapped | OnboardingView.primaryAction at lines 326-340 | plan monthly, offering state, source |
| trial_purchase_succeeded | OnboardingView after PurchaseOutcome.purchased at lines 340-345 | product ID, plan, entitlement confirmation result |
| trial_purchase_cancelled | Same switch at lines 341-346 | plan, source |
| trial_purchase_failed | OnboardingView catch at lines 347-349 | error category, not raw sensitive error text |
| paywall_viewed | PaywallView.task at lines 281-284 | source, selected default plan, offering state |
| plan_selected | PaywallContent plan selection closure around lines 67-80 | previous plan, new plan, source |
| purchase_cta_tapped | PaywallView.purchase at lines 299-305 | source, selected plan, product ID |
| purchase_succeeded | SubscriptionService.purchase at lines 133-145 | product ID, plan, entitlement state |
| purchase_cancelled | Same method after PurchaseOutcome.cancelled | product ID, plan |
| purchase_failed | Same method catch path | error category, product ID if known |
| entitlement_unlock_latency | SubscriptionService.confirmEntitlement at lines 148-162 | elapsed milliseconds, success |
| restore_started | PaywallView.restore, Settings, and onboarding restore actions | source |
| restore_succeeded | SubscriptionService.restore at lines 164-168 | source, entitlement state |
| restore_empty | Same location after no active entitlement | source |
| restore_failed | Same location catch path | source, error category |
| feature_locked_tapped | HomeView training tile at lines 443-465 and RoomView locked row at lines 73-90 | source, room ID, feature type |
| drill_started | QuickSessionView or drill view entry | room ID, drill kind, membership state |
| drill_completed | DrillCompleteView.swift:75-99 and BridgeMinuteView.swift:284-296 | room ID, drill kind, score band |
| review_pitch_shown | ReviewPromptSheet.swift:52-92 | positive moment count, entry surface |
| review_opened | ReviewPromptSheet.swift:112-121 | explicit App Store link path |
| review_soft_deferred | ReviewPromptSheet.swift:134-154 | cooldown path |
| feedback_opened | ReviewPromptSheet.swift:194-205 | mail availability |
| feedback_mail_failed | ReviewPromptSheet.swift:194-223 | fallback path |

Do not count review URL opens as review submissions. Apple does not provide a reliable submission callback to this app.

## Ratings and feedback funnel

Shared/Services/ReviewPromptTracker.swift:27-56 stores local launch count, first open, last shown, outcome, positive moments, and soft defer. It waits for two launches, three positive moments, a 120-day cooldown after “Not now,” and a 30-day cooldown after “Maybe later.” Tests cover these gates at BridgeTests/ReviewPromptTrackerTests.swift:17-69.

Bridge/Views/ReviewPromptSheet.swift:13-16 uses a three-step path:

1. Ask whether the player enjoyed the completed practice.
2. Send a positive player to the App Store review URL or a “Maybe later” path.
3. Send a negative player to an email feedback composer.

DrillCompleteView.swift:75-107 and BridgeMinuteView.swift:284-296 record positive moments after a completion, wait 1.4 seconds, and present the sheet. SettingsView.swift:175-183 gives direct Rate and Send Feedback actions.

Positive choices:

* The review ask is delayed until after the success state settles.
* Negative sentiment is diverted to feedback.
* Cooldowns are tested and conservative.
* Settings provides a user-initiated rating path.

Risks:

* Shared/Services/ReviewPromptTracker.swift is local. There is no aggregate funnel event for prompt shown, App Store URL opened, native requestReview invoked, feedback mail opened, or feedback fallback.
* Bridge/Views/ReviewPromptSheet.swift marks openedWriteReview when the URL opens, not when a rating is submitted.
* “Maybe later” invokes the native requestReview path at DrillCompleteView.swift:102-107, but the system can suppress it. The app should treat this as a request attempt, not a rating.
* AppStoreLinks.feedbackEmail at Shared/Services/ReviewPromptTracker.swift:17 is jackwallner+b@gmail.com, while docs/support.html:39-52, docs/privacy-policy.html:123-128, and docs/terms.html:134-139 use jack@wallner.io.

Recommendation:

* Use one canonical support address in the app, landing site, terms, privacy, and support page.
* Instrument the funnel with the bounded events above.
* Keep the warm positive gate, but test three positive moments against five and compare prompt completion, negative feedback, retention, and store conversion.
* Add a lightweight “report a problem” path from a purchase or drill error, separate from the rating ask.
* Do not use RevenueCat customer attributes as a review event log.

## Content and learning UX

### Content coverage

DrillLibrary has four free rooms and one paid room. ContentValidityTests.swift validates room counts, free and plus distribution, nonempty item counts, membership locking, and quick-session membership boundaries at BridgeTests/ContentValidityTests.swift:78-131.

HandGeneratorTests.swift validates generated hands, answer classification, and authored hand agreement at BridgeTests/HandGeneratorTests.swift:83-152. CLAUDE.md:47-51 records a prior authored hand mismatch that this test caught. This is important trust protection for a rules-based learning product.

BridgeMinuteTests.swift validates deterministic daily content, a two-bidding, one-declarer, two-defense mix, legality, and a five-year generator sweep. PracticeRecordStore and ProgressStore tests cover local persistence and review state.

### First-session composition

SessionBuilder.choicePool is deliberately uniform and excludes Play scenarios. Get Started uses this pool from Bridge/Views/HomeView.swift:261-296. The store description claims card-play scenarios and declarer practice in fastlane/metadata/en-US/description.txt, so the first-session composition should be measured against that promise.

Recommendation: add a diagnostic field to a session record for content kinds and room distribution. Use it to verify that the first session includes enough breadth and does not over-index on Auction items. The diagnostic can remain local or be aggregated as a low-cardinality event.

### Empty, stale, or interrupted states

Bridge/Views/Drills/PracticeRunView.swift:72-75 renders DrillCompleteView when finished or when items.isEmpty. For a review run, a stale or empty queue therefore looks like a completion screen rather than “Nothing is due yet.” It has no explicit action to open a room or return to Home.

Recommendation:

* Add a dedicated empty review state with a clear explanation and a “Practice a room” action.
* Add a stale-ID test for reviewSession and a UI test for an empty review queue.
* Ensure an interrupted timed run cannot call completion twice.

## Website, terms, privacy, and support consistency

### Current pages

* docs/index.html is the public landing page.
* docs/support.html and docs/support/index.html contain support instructions.
* docs/privacy-policy.html and docs/privacy-policy/index.html contain the privacy page.
* docs/terms.html and docs/terms/index.html contain the terms page.
* fastlane metadata points to the GitHub Pages flat URLs without a trailing slash.
* PaywallView.swift:12-18 points privacy to the same flat URL and terms to Apple’s standard EULA.

The nested terms copy is semantically identical to the flat terms page with relative-link adjustments. The nested privacy and support copies differ in navigation links so they work from their subdirectory. This is intentional URL-path duplication, not proof that the legal text differs, but it creates a maintenance surface that should be checked byte-for-byte after every legal edit.

Legal evidence:

* docs/privacy-policy.html:86-127 is dated August 17, 2026 and describes local progress, reminders, Apple purchases, and RevenueCat.
* docs/terms.html:86-145 is dated August 17, 2026 and describes educational use, Standard American variation, Bridge+ purchase types, renewal, cancellation, refunds, and restore.
* docs/support.html:22-52 explains restore, cancellation, support, and the support email.

Consistency findings:

1. Support email differs. App feedback uses jackwallner+b@gmail.com at Shared/Services/ReviewPromptTracker.swift:4-18. Public support, privacy, and terms use jack@wallner.io.
2. Website JSON-LD softwareVersion is 1.2.0 at docs/index.html:56-60, while project.yml is 1.2.2.
3. The website says iPhone in the screenshot section while the app supports iPhone and iPad at project.yml:15-35 and CLAUDE.md:101-113.
4. Paywall privacy URL is the flat no-trailing-slash path; legal navigation includes both flat and nested copies. Verify redirects and canonical tags on the public host.
5. docs/index.html:603-608 uses current-looking US prices, while the inspected paywall screenshot and stale scripts use old prices. Do not treat the site as a safe source until the price manifest is centralized.
6. The site says “Works offline” in its spec copy while the app needs Apple and RevenueCat services for offerings, purchase, and restore. Clarify that core practice is offline and membership operations are online-dependent.
7. Terms and privacy are dated August 17, 2026, six days before this audit. The dates are not stale by themselves, but a legal scanner should ensure the flat and nested text remains aligned.

Per instruction, this audit does not classify RevenueCat disclosure wording as a finding. The functional consistency of entitlement, purchase, restore, and links remains in scope.

Validation:

* Fetch every public legal and support URL with redirects enabled and assert a successful final response.
* Check the final URL and canonical tag for the flat and nested forms.
* Compare normalized legal body text between flat and nested copies.
* Scan all source and docs contact addresses and require one canonical address.
* Scan version and product prices across project.yml, StoreKit, metadata, site JSON-LD, release notes, and scripts.

## Release regression, crash, hang, and degraded UX signals

### Current repository capability

Bridge/BridgeApp.swift:19-22 starts subscriptions and records an app launch for the review gate. Shared/Services/SubscriptionService.swift:78-102 sends paywall impressions and suppresses offering errors. There is no crash SDK, MetricKit subscriber, os_log or Logger usage, watchdog, server health endpoint, or production event stream in the repository.

ios27Bridge.md:1-28 is a dated runtime note from August 5, 2026. It says the debug, unit, rebuild, install, and runtime snapshot checks passed, but notes Swift concurrency warnings in Theme.swift and tests and an unused suit value in HandGenerator. It is evidence of a prior check, not proof for version 1.2.2 or build 15.

### Release-watchdog signal contract

The fleet-level Mac watchdog and app scanner should be configurable and report-only by default. It should watch these signals by build, release date, OS, device family, storefront, and app version:

Crash and process health:

* Crash-free users and crash-free sessions.
* Total crash rate and unique affected users.
* Hang or watchdog termination count.
* Launch failure rate and foreground termination.
* Memory pressure, jetsam, and high-memory termination.
* Fatal errors and uncaught exceptions.
* Symbolication completeness and top regression signatures.
* OS version, device model, app version, build, and release channel.

Purchase and entitlement health:

* Offerings load success and current-offering nil count.
* Store product lookup success and productsUnavailable count.
* Paywall impressions without a render-ready package.
* Trial CTA taps, purchase sheet cancellations, failed purchases, and successes.
* Successful transaction followed by inactive Bridge+ entitlement.
* Entitlement unlock latency and delayed unlock count.
* Restore started, restore succeeded, restore empty, and restore failed.
* Product identifier and package lookup mismatches.

User experience health:

* Fresh launch to first interactive screen.
* Onboarding page completion and abandonment by page.
* First question shown, first answer, first explanation shown, and first session completion.
* Empty review queue screen count.
* Navigation loop or repeated paywall presentation.
* Terms, privacy, support, and manage-subscription link failures.
* Notification scheduling errors and denied notification permission.
* Review prompt shown, review link opened, native request attempt, and feedback mail fallback.

Release comparison:

* Compare current production build with the previous 7, 14, and 28 day baselines.
* Use both an absolute minimum count and a relative increase threshold so one crash is not treated like a fleet incident.
* Alert only when multiple users or sessions are affected, except for a single confirmed payment or entitlement failure.
* Watch the first 24 hours, 72 hours, and 7 days after release.
* Include a release annotation with marketing version, build, release timestamp, and commit.
* Group crash signatures, not just raw counts, so one regression is not hidden by many unrelated crashes.

Urgent alert examples:

* Current build has at least five affected users and a crash-free user rate materially below the baseline.
* Offerings unavailable for multiple users in a short window.
* Purchase success events increase while entitlement unlock success falls.
* A new build creates a statistically meaningful increase in launch failures or hangs.
* The public landing page or legal URLs return errors after a docs deployment.

The actual thresholds must be configuration values in the future watchdog script. This audit does not claim that any incident is currently occurring.

### Release smoke matrix

Run a small deterministic matrix on every release candidate and again after production rollout:

1. Fresh iPhone install, network available.
2. Fresh iPhone install, network unavailable.
3. Returning user with What’s New.
4. Free first session.
5. Locked drill to paywall and return.
6. Offerings loading, empty, failed, and retry.
7. Eligible trial and ineligible trial.
8. Monthly, yearly, and lifetime purchase in sandbox.
9. Purchase cancellation.
10. Delayed entitlement.
11. Restore success, restore empty, restore error.
12. Terms and privacy links.
13. Review and feedback paths.
14. Notifications allowed and denied.
15. Game Night notification deep link.
16. iPad portrait and landscape.
17. VoiceOver, Dynamic Type, Dark Mode, reduced motion, and keyboard navigation where applicable.
18. Background and foreground while a timed run is active.

## A/B test plan

All variants should be deterministic, persisted, and assigned before the first relevant surface. Use a feature flag or local configuration that can be disabled without shipping a new paywall implementation. Do not use the audit’s proposed metrics as existing data.

| Experiment | Control | Variant | Primary metric | Guardrails |
| --- | --- | --- | --- | --- |
| First value timing | Trial page before any question | One free question and explanation before trial | First-session completion and trial start | Crash-free, purchase failure, next-day return |
| Onboarding length | 3 value pages, skill, trial, primer/tour | Skip or compress the primer and tour after a free question | Time to first answer | First-answer accuracy, support feedback |
| First session size | 10 choice items | 5 choice items | Completion rate | Next-day return, session depth |
| First-session breadth | Choice-only pool | Include one declarer or Play scenario | First-session completion | Incorrect answer rate, abandonment |
| Trial plan | Monthly direct onboarding trial | Yearly or contextual full plan picker | Trial start and paid conversion | Cancellation, refund, entitlement success |
| Paywall default | Yearly | Monthly or Lifetime default | Purchase conversion by plan | Revenue per install, cancellation, trial activation |
| Paywall order | Yearly, Monthly, Lifetime | Lifetime, Yearly, Monthly or another tested order | Plan selection and purchase | Mis-tap rate, restore, support contacts |
| Price framing | Savings badge and per-month equivalent | Explicit annual saving or simpler price | Purchase conversion | Refund and cancellation |
| CTA copy | Start 7-Day Free Trial | Try Bridge+ Free or Continue with Monthly based on eligibility | CTA to transaction | Billing comprehension, failed purchase |
| Context copy | Shared Bridge+ benefits | Locked-drill, Endless, Game Night, or Settings-specific benefits | Paywall-to-purchase conversion | Dismissal, return to intended feature |
| Free exit | Get Started on trial page | Skip trial to first free drill | First free-session completion | Later trial start |
| iPad first image | Current Quick Session with whitespace | Home or denser first-value composition | Product-page conversion | Screenshot readability |

Paywall-specific implementation locations are PaywallView.swift:67-80 for order and selection, PaywallView.swift:144-212 for pricing and badges, PaywallView.swift:281-284 for impression and load, and PaywallView.swift:299-336 for purchase and restore.

## Prioritized findings and implementation handoff

Severity definitions:

* P0: can cause paid access failure, destructive release damage, or a materially wrong purchase surface.
* P1: likely conversion, trust, operational, or release quality loss that should be fixed before the next serious acquisition push.
* P2: meaningful quality or instrumentation improvement that can follow the P0 and P1 fixes.

| ID | Severity | Evidence | Inference | Recommendation | Effort | Confidence | Validation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ENT-01 | P0 | SubscriptionService checks Bridge+ at 4-8,170-174. rc-setup accepts pro or Bridge+ and creates pro at 78-93. Theme.swift:96-100 says entitlement is still pro. | A setup-created production project can unlock products to a key the app never reads. | Make Bridge+ canonical, reject pro, add read-only config audit, update stale comment. | M | High | Sandbox purchase, restore, relaunch, and entitlement config check |
| PRICE-01 | P0 | StoreKit has 8.99, 34.99, 79.99 at 4-84. The inspected paywall asset shows 1.99, 9.99, 29.99. ASC setup scripts and generators contain old prices. | Users may see inconsistent prices and future tools can overwrite ASC with old prices. | Centralize product prices, regenerate screenshots, archive or rewrite stale writers, block old tokens. | M | High | Asset OCR/manual check, static scan, ASC dry-run |
| CAP-01 | P0 | Screenshot tests do not fail at 13-17 and capture script continues at 22-35. Upload deletes existing screenshots at 81-84. | A partial capture can be published as if it passed. | Emit manifest, fail hard, validate dimensions, require dry-run before delete/upload. | M | High | Force one capture failure and assert nonzero/no remote deletion |
| ENT-02 | P1 | Onboarding starts tour immediately at 331-345, while PaywallView confirms at 299-313. | Paid onboarding users can see locked UI during delayed entitlement. | Share purchase coordinator and await entitlement confirmation before tour. | S | High | Delayed customer-info test |
| PAY-01 | P1 | Offerings errors are swallowed at SubscriptionService:92-102, ensureOfferings only retries at 122-131, CTA remains visible at PaywallView:246-258. | A polished dead CTA can reduce trial starts and create support contacts. | Add explicit load state, disabled unavailable plans, retry, and categorized errors. | M | High | Offline, nil offering, product unavailable, retry UI tests |
| PAY-02 | P1 | Trial copy is unconditional at PaywallView:4-9,67-79 and OnboardingView:234-239, while terms limit eligibility at docs/terms.html:103-108. | Ineligible users can receive inaccurate trial framing. | Branch copy and CTA on intro-offer availability and eligibility. | M | High | Eligible and ineligible sandbox accounts |
| PAY-03 | P1 | Onboarding Restore suppresses result at 292-294. | Users cannot tell whether restore succeeded or failed. | Reuse Settings restore state with loading, success, empty, and error. | S | High | Restore matrix |
| VER-01 | P1 | project.yml is 1.2.2 build 15; WhatsNew releases only 1.2.0 and 1.1; docs JSON-LD is 1.2.0; local ASC state says draft 1.2.1/live 1.2.0. | Update messaging and agents can be stale or absent. | Centralize version, update What’s New for every releasable version, make state files freshness-checked. | M | High | Release fixture with 1.2.2 current release |
| SUP-01 | P1 | App feedback email is jackwallner+b@gmail.com, public pages use jack@wallner.io. | A support request can go to an unexpected inbox and cannot be joined cleanly. | One canonical address and a source scanner. | S | High | Search all source, metadata, docs |
| OBS-01 | P1 | No crash, hang, MetricKit, Logger, or event pipeline found. | Multi-user production regressions cannot be detected from the app repository. | Scaffold report-only Mac watchdog integration and release signal contract. | M | High | Synthetic crash/offerings failure in test environment |
| REV-01 | P1 | Review state is local at ReviewPromptTracker:27-125; URL-open is treated as opened review; feedback contact diverges. | Review funnel cannot be measured and support is inconsistent. | Add bounded funnel events, unify contact, keep local cooldown. | M | High | Review path UI tests and event fixture |
| ASO-01 | P1 | en-US subtitle is exactly 30, promo is 167, keywords 95, and repeated terms are present. | Small metadata opportunity exists, but no evidence yet supports a specific replacement. | Test non-duplicated keywords and product page variants. | S | Medium | ASC search and conversion comparison |
| SITE-01 | P1 | docs/index.html softwareVersion is 1.2.0, site emphasizes iPhone, workflow mirrors externally. | Public acquisition and release messaging can lag the binary. | Generate version, platform, URL, and product facts, then verify the mirror. | M | High | Public URL health and version check |
| FIRST-01 | P2 | SessionBuilder excludes Play and plain flashcards at 51-55,169-227. | First value may under-deliver on the declarer and card-play promise. | Test representative first session and record content mix. | M | High | First-session composition fixture |
| EMPTY-01 | P2 | PracticeRunView renders completion when items.isEmpty at 72-75. | Empty or stale review can look completed with no recovery path. | Add explicit empty review view and test. | S | High | Empty queue UI test |
| A11Y-01 | P2 | PlayDrillView disables all card buttons after answer at 40-54; no dedicated accessibility UI suite found. | Answer states and focus may be confusing or visually dimmed. | Use explicit answered styling, VoiceOver focus, Dynamic Type, and contrast tests. | M | Medium | Accessibility smoke matrix |
| NOTIF-01 | P2 | AppSettings schedules local notifications, but add errors are not surfaced in the inspected path. | Notification preferences can appear enabled when scheduling failed. | Check add errors, expose permission state, add watchdog signal. | S | Medium | Denied permission and scheduling failure |
| DOC-01 | P2 | Root AGENTS.md symlinks to CLAUDE.md; ios27Bridge.md is dated Aug 5; no README; stale generator docs remain. | Agents have a good guide but unclear canonical/archive boundaries. | Keep one root guide, add pointer index, archive stale runtime notes and writers. | S | High | Agent doc inventory and stale-reference scan |

## Concrete non-AI scanner rules

The future fleet scanner should be deterministic and produce JSON plus a human Markdown report. Each rule should include path, line, severity, and a suggested fix. It should never upload, delete, or change files by default.

### Metadata rules

1. Enumerate only storefront locale directories, excluding review_information.
2. Require the ten expected metadata files for each locale.
3. Count name, subtitle, keywords, description, promotional_text, and release_notes after final-newline normalization.
4. Fail on limits 30, 30, 100, 4000, 170, and 4000.
5. Flag empty or whitespace-only values.
6. Flag bridgeongg and any configured old price tokens.
7. Detect identical full descriptions or release notes across non-English locales and report them as possible fallback copy, not automatic failure.
8. Check URL fields for valid HTTPS URLs and record the final redirect target in report-only mode.
9. Compare app ID and bundle ID references across metadata, docs, AppStoreLinks, and Fastlane.
10. Detect stale version strings by comparing project.yml, Info.plist expansion, WhatsNew, release notes, docs JSON-LD, and operational state.
11. Flag keyword duplicates already present in name and subtitle and report reclaimable characters.
12. Verify primary category and secondary category files exist and are parseable.

### Product and entitlement rules

1. Read StoreKit product IDs and compare them with CLAUDE.md, SubscriptionService, rc-setup.py, fastlane review notes, and ASC scripts.
2. Read local prices and compare them with screenshot OCR or a manually supplied asset manifest.
3. Flag old price tokens in executable scripts and generated metadata.
4. Require exactly one canonical entitlement lookup key, Bridge+.
5. Fail if rc-setup.py can create or silently select pro.
6. Verify all three product IDs attach to the intended entitlement and current offering.
7. Verify package lookup keys map to monthly, annual, and lifetime.
8. Flag any purchase path that does not have success, cancel, error, restore, and delayed-entitlement handling.
9. Flag unconditional trial claims when product intro eligibility is not consulted.
10. Flag try? around offerings, purchase, restore, and notification scheduling for user-facing paths.

### Paywall and funnel rules

1. Enumerate every PaywallView source ID and every call site.
2. Require source context on paywall impression, purchase, restore, and error events.
3. Verify the CTA is disabled when its package is absent.
4. Verify loading, unavailable, retry, cancellation, success, and delayed unlock states exist.
5. Verify Terms, Privacy, Restore, and Manage Subscription links exist where relevant.
6. Verify each locked feature returns to the intended feature after a successful purchase.
7. Verify onboarding purchase awaits entitlement before leaving onboarding.
8. Flag any screen that can show a paywall twice during sheet dismissal.
9. Flag progress views whose value starts at zero and validate final progress semantics.
10. Record first-session content kinds and room IDs so the download promise can be compared with actual value.

### Screenshot and asset rules

1. Require the six capture names from ScreenshotTests.swift.
2. Require four current iPhone upload assets at 1320 x 2868.
3. Require six current iPad upload assets at 2064 x 2752.
4. Reject alpha where the upload family requires RGB, unless the asset manifest explicitly permits it.
5. Require the icon at 1024 x 1024 and compare the public icon hash.
6. Reject files with stale modification time relative to the source build or manifest.
7. Fail when a screenshot test reports a problem or exits nonzero.
8. Reject missing, duplicate, or misordered screenshot names.
9. OCR or manual-review flag prices, version numbers, clipped text, and stale membership copy.
10. Do not delete remote assets until the local manifest and dry-run diff pass.

### Site and legal rules

1. Check flat and nested terms, privacy, and support pages for normalized body equivalence and correct relative links.
2. Check App Store, support, privacy, terms, and manage-subscription links for successful responses and expected final URLs.
3. Compare all source and docs contact addresses and require one canonical value.
4. Compare app version in docs JSON-LD with project.yml.
5. Compare product names and prices in site JSON-LD with the canonical product manifest.
6. Flag iPhone-only marketing claims when the target includes iPad.
7. Flag “offline” copy unless the sentence scopes offline behavior to core practice.
8. Check the GitHub sync workflow result after docs changes.
9. Flag legal dates older than the current release only for review, not automatic failure.

### Release and production rules

1. Read current and previous build identifiers from a release manifest.
2. Verify the release smoke matrix has a result for each state.
3. Pull crash, hang, launch, memory, and purchase health inputs from configured external sources when available, without inventing missing values.
4. Compare 1, 7, 14, and 28 day baselines.
5. Alert only after both absolute and relative thresholds are met, except payment unlock failures.
6. Group crash signatures and attach first-seen build and latest-seen build.
7. Flag a new build with no symbolicated diagnostics.
8. Flag current-offering nil spikes and entitlement success declines.
9. Flag public site or legal URL failures after docs deployment.
10. Produce a report-only, email-ready summary, but do not send by default in this repository audit.

## Agent workspace and documentation hygiene

### Current layout and classification

| Path or artifact | Classification | Action for implementation agent |
| --- | --- | --- |
| AGENTS.md | Keep | It is a symlink to CLAUDE.md and is the correct single project guide for agents that read AGENTS.md. Do not replace it with a copy. |
| CLAUDE.md | Keep and update | Keep as the canonical app guide. Update prices, entitlement rules, current release, screenshot failure behavior, and the release-watchdog link. |
| Bridge/Views/Drills/CLAUDE.md | Keep, narrow scope | Keep local flashcard and gesture gotchas, but link it from the root guide and remove stale implementation claims when behavior changes. |
| ios27Bridge.md | Archive after extracting findings | Move to a dated archive location such as docs/archive/ios27Bridge-2026-08-05.md, or clearly label it as historical. Do not treat it as the current release gate. |
| fastlane/metadata | Keep | Treat as the current storefront copy source after validation is added. |
| fastlane/README.md | Generated, do not hand-edit | It is fastlane output and is ignored by .gitignore. Point agents to the root guide and scripts instead. |
| scripts/generate_metadata.py | Update or quarantine | It warns that it writes old prices and can overwrite metadata. Make it fail closed or rewrite it to read the canonical source. |
| scripts/generate_metadata_all.py | Update or quarantine | Same stale-price and write-through risk across all locales. |
| scripts/.asc-state.json | Operational state only | It records draft 1.2.1, live 1.2.0, updated 2026-08-17. Add freshness and schema checks; never treat it as release truth. |
| scripts/.astro-app.json | Operational state only | It has keywordCount 38 and syncedAt 2026-07-28. Reconcile or archive if Astro is no longer the metadata tool. |
| docs/index.html | Keep as public copy | Generate version, product facts, and URLs from a shared manifest or validate them on every release. |
| docs/support.html and nested copy | Keep, validate | Preserve relative-link variants, but add a duplication check. |
| docs/privacy-policy.html and nested copy | Keep, validate | Preserve relative-link variants, but add a duplication check. |
| docs/terms.html and nested copy | Keep, validate | Preserve relative-link variants, but add a duplication check. |
| README.md | Missing, add pointer later | Add a short project entry point only if the fleet convention requires it. It should link to AGENTS.md and CLAUDE.md, not duplicate them. |
| Cursor rules | Not present in the inspected root | If the fleet adopts .cursor/rules, add one pointer rule to AGENTS.md rather than a divergent copy. |

### Canonical Cursor, Claude, and Codex layout

The clean agent layout should be:

* Root AGENTS.md is the canonical symlink or pointer for shared agent instructions.
* Root CLAUDE.md contains the app-specific architecture, product, testing, release, and content rules.
* Cursor, Claude, and Codex should all be directed to those same root files.
* .cursor/rules, if added, should contain only a short pointer and Cursor-specific invocation details. It should not duplicate prices, entitlement names, or release steps.
* Local nested CLAUDE.md files should be limited to rules that apply to that directory. They should link upward for global product and release truth.
* docs/agent or docs/archive should contain historical notes, handoff snapshots, and decision records. Historical notes should carry a date, build, and explicit “not current” label.
* fastlane/metadata is storefront content, not agent instructions.
* Scripts should include a header stating whether they are read-only, dry-run, or mutating, and what source of truth they consume.

### Documentation update triggers

Update the root guide whenever any of these change:

* Bundle ID, versioning, product IDs, prices, trial duration, or entitlement lookup key.
* Onboarding sequence, paywall source IDs, restore behavior, or review cooldown.
* Screenshot scheme, expected filenames, dimensions, or upload behavior.
* Release watchdog inputs or thresholds.
* Canonical support, privacy, terms, or marketing URLs.

Archive rather than silently edit when a document describes a completed release check, an obsolete price ladder, or an abandoned generator. That keeps agents from treating historical intent as current behavior.

## Recommended implementation sequence

### Phase 1, access and purchase safety

1. Canonicalize Bridge+ in RevenueCat setup and add a configuration audit.
2. Centralize product IDs, product names, prices, and trial metadata.
3. Remove or quarantine old-price writers and bridgeongg fallbacks.
4. Fix onboarding purchase confirmation and restore feedback.
5. Make offering availability a visible state machine with retry.
6. Make trial copy conditional on actual intro-offer eligibility.

### Phase 2, release asset safety

1. Add screenshot manifests and hard failures.
2. Regenerate all price-bearing screenshots from current product data.
3. Validate iPhone and iPad dimensions separately.
4. Add website version, product, URL, and platform consistency checks.
5. Reconcile What’s New with the current marketing version.

### Phase 3, observability

1. Choose the production crash and diagnostics source.
2. Add release annotations and build-aware signal collection.
3. Add purchase and entitlement event categories.
4. Scaffold the report-only Mac watchdog with configurable thresholds and email output disabled by default.
5. Add a fleet scanner implementing the deterministic rules above.

### Phase 4, conversion and UX experiments

1. Instrument onboarding and first-session steps.
2. Test first value before trial against the current flow.
3. Test plan order, default plan, price framing, and context-specific paywall copy.
4. Improve iPad screenshot composition and test a preview video.
5. Measure review and feedback funnel outcomes without treating URL opens as ratings.

## Validation checklist for the implementation agent

Before declaring the audit addressed:

* [ ] StoreKit, RevenueCat setup, app entitlement check, review notes, and documentation all use Bridge+.
* [ ] Current product IDs and prices have one source of truth.
* [ ] No executable script can write the old price ladder or bridgeongg.
* [ ] The inspected paywall screenshot no longer shows old prices.
* [ ] Screenshot capture fails on missing or broken screens and validates dimensions.
* [ ] iPhone and iPad assets are uploaded through separate validated paths.
* [ ] Onboarding purchase waits for entitlement confirmation.
* [ ] Onboarding Restore shows loading, success, empty, and error.
* [ ] Paywall CTA is unavailable until its package is ready.
* [ ] Trial copy changes for ineligible accounts.
* [ ] Every paywall source returns to the intended destination after unlock.
* [ ] What’s New has a current release entry for the marketing version.
* [ ] Website JSON-LD version and product facts match the release manifest.
* [ ] Support, privacy, terms, and app feedback use one canonical support address.
* [ ] Legal and support URL smoke checks pass for flat and nested paths.
* [ ] Empty review state has a useful recovery action.
* [ ] Play answer state, Dynamic Type, VoiceOver, contrast, and timed backgrounding are tested.
* [ ] Review prompt and purchase funnel events are bounded and source-tagged.
* [ ] Crash, hang, launch, memory, offering, purchase, entitlement, and restore release signals are available to the watchdog or explicitly marked unavailable.
* [ ] Historical docs and stale generators are archived or clearly marked.
* [ ] The fleet scanner runs report-only and produces stable output on a clean checkout.

## Evidence gaps and explicit non-claims

This audit is repository evidence, not a live account report. It does not claim:

* Current downloads, product page conversion, trial starts, paid conversion, revenue, refunds, ratings, or review count.
* Current production RevenueCat entitlement state, offering state, or customer state.
* That the stale entitlement key is present in production, only that the setup path can create or select it.
* That a particular keyword, screenshot, paywall order, or onboarding variant will improve conversion.
* That any current crash or hang incident exists.
* That public URLs are currently reachable from the network, since this audit did not deploy or probe external services.

The implementation agent should resolve these gaps through read-only ASC and RevenueCat checks, controlled sandbox purchases, release diagnostics, and experiment instrumentation. The requested RevenueCat tracking and data-collection disclosure consistency comparison is intentionally omitted from findings.

## Activity and success context, 2026-08-23

Classification: **active monetizing**. Confidence: **high**. Trend: **no ASC comparison displayed**.

ASC release state: `iOS 1.2.2 Ready for Distribution`. ASC evidence: [Analytics Overview](https://appstoreconnect.apple.com/apps/6791026407/analytics/overview?dateSpec=d90), selected range `dateSpec=d90`.
RevenueCat evidence: [Project Overview](https://app.revenuecat.com/projects/71e29dd0/overview), production mode, selected range `Last 28 days, 2026-07-27 through 2026-08-23`.

### Observed activity

| Source | Metric | Value | Window or comparison |
| --- | --- | ---: | --- |
| ASC | first-time downloads | 71 | 90-day Analytics Overview |
| ASC | redownloads | 2 | 90-day Analytics Overview |
| ASC | conversion rate | 2.03% | comparison not displayed |
| ASC | proceeds | $27 | 90-day Analytics Overview |
| ASC | in-app purchases | 14 | 90-day Analytics Overview |
| RevenueCat | new customers | 71 | last 28 days |
| RevenueCat | active customers | 81 | last 28 days |
| RevenueCat | active trials | 2 | current total |
| RevenueCat | active subscriptions | 4 | current total |
| RevenueCat | MRR | $6 | current total |
| RevenueCat | revenue | $34 | last 28 days |

A missing value above means the source did not expose that metric in this read-only snapshot. It is not a zero.

### Interpretation and implementation focus

Bridge has aligned acquisition signals, 71 ASC first-time downloads and 71 RevenueCat new customers, plus 2 active trials, 4 active subscriptions, and $34 of RevenueCat revenue. This is a small but genuine monetizing product. Protect the current path, measure trial eligibility and mature trial conversion, and use the audit's onboarding and paywall experiments only after the release baseline is captured.

The deterministic classifier recommends: Protect the current paid path, then use release and cohort baselines to decide whether acquisition or conversion is the next constraint.

- Join ASC first-time download, first launch, first value, paywall shown, offer loaded, trial started, trial canceled, trial converted, entitlement active, restore, and purchase failure events with the app version and build.
- Keep ASC's 90-day acquisition and proceeds window separate from RevenueCat's 28-day customer and revenue window. Do not calculate a conversion rate by dividing values from different windows.
- Use a mature trial cohort and a minimum sample before choosing a native paywall or onboarding A/B winner. Record the offering identifier, package, placement, experiment variant, and build.
- Put the app's classification and the next baseline date in the release handoff so Cursor, Claude, and Codex do not optimize from an old qualitative audit.

### Boundary on success or death

This snapshot supports the label **active monetizing**, not a lifetime verdict. The app has current paid activity, but ASC does not expose a positive comparison for the selected window. A later decision should include a clean 28-day RevenueCat trend, ASC acquisition and conversion trend, ratings and review count, crash and hang evidence, and a release-specific cohort.
This dated section supersedes earlier statements in this file that per-app ASC or RevenueCat activity was unavailable as of 2026-08-23. Earlier statements remain historical evidence boundaries for their original audit pass.
