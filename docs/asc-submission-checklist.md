# App Store Connect submission checklist — Mahj Trainer

Not a script, a reference for filling the App Store Connect web UI (App Privacy
questionnaire + Age Rating questionnaire) before submitting for review. Nothing
in this file is auto-applied; these two questionnaires have no public API and
must be answered by hand in ASC.

## App Privacy ("App Privacy" tab -> Get Started / Edit)

Data collected: **Purchases** and **Identifiers** only, via the RevenueCat SDK.
No other data types are collected (no Contact Info, no Location, no
Contacts, no User Content, no Browsing/Search History, no Diagnostics beyond
Apple's own automatic crash logs, no Usage Data, no Health/Fitness data).

### Purchases
- Data type: **Purchase History**
- Collected: **Yes**
- Linked to the user's identity: **Yes** (linked to RevenueCat's per-install
  app user ID so entitlement/subscription status can sync across launches)
- Used for tracking (across apps/websites owned by other companies): **No**
- Purpose: **App Functionality** (determines whether the Pro Tables room is
  unlocked)

### Identifiers
- Data type: **User ID** (RevenueCat's anonymous app-user identifier, not an
  Apple ID, email, or name)
- Collected: **Yes**
- Linked to the user's identity: **Yes** (same reasoning as above — it's the
  key RevenueCat uses to associate purchase state with this install)
- Used for tracking: **No**
- Purpose: **App Functionality**

### Everything else: answer "No" / not collected
- Contact Info: No (no account system, no email/name collected in-app)
- Location: No
- Health & Fitness: No
- Financial Info: No (Apple handles payment; the app never sees card data)
- User Content: No
- Search/Browsing History: No
- Usage Data: No (no analytics SDK)
- Diagnostics: No (beyond Apple's own automatic, opt-in crash reporting,
  which Apple already accounts for separately and does not require declaring)

### "Data Not Linked to You" vs "Data Used to Track You"
Do **not** check "Used to Track You" for either data type — RevenueCat's
identifier is app-scoped, not shared with data brokers or used to correlate
activity across other companies' apps/sites. This matches
`docs/privacy-policy.html`, which states RevenueCat receives "an anonymous
identifier and purchase information, never your name or email."

Source: `Shared/Services/SubscriptionService.swift` (RevenueCat is the only
SDK that leaves the device; no analytics, no ad SDKs, no tracking pixels).

## Age Rating questionnaire

Target: **4+**.

Answer **No** / **None** to every content category:
- Cartoon or Fantasy Violence: None
- Realistic Violence: None
- Sexual Content or Nudity: None
- Profanity or Crude Humor: None
- Alcohol, Tobacco, or Drug Use: None
- Mature/Suggestive Themes: None
- Horror/Fear Themes: None
- Medical/Treatment Information: None
- **Simulated Gambling: NO.** Mahj Trainer is a solitaire-style *training*
  app — flashcards, quizzes, and hand-matching drills. There are no
  opponents, no betting, no chips, no stakes, and no wagering mechanic of any
  kind, simulated or otherwise. It never presents mah jongg as a game to win
  money or prizes.
- Contests: None
- Unrestricted Web Access: No (no in-app browser/web view to arbitrary URLs;
  the few outbound links — Terms/EULA, Privacy Policy, Rate on the App
  Store — open in the system browser via `Link`, not an in-app web view)
- User-Generated Content / Communication: None (no chat, no accounts, no
  social features)

Expected result: **4+**, no advisory content descriptors.

## Cross-check against `plan712.md` section 8

- B (subscription legal in metadata): done — see
  `fastlane/metadata/en-US/description.txt` SUBSCRIPTIONS section, mirrored
  (translated) into every other locale.
- C (privacy policy live + support/terms resolve): confirmed —
  `https://jackwallner.github.io/mahj/privacy-policy`,
  `https://jackwallner.github.io/mahj/terms`,
  `https://jackwallner.github.io/mahj/support` all returned HTTP 200 on
  2026-07-12.
- D (age rating = 4+, simulated gambling = No): captured above.
- E (review notes: original hands, non-affiliation, Pro sandbox testing,
  trial terms): written to `fastlane/metadata/review_information/notes.txt`.

## Not covered here (owned elsewhere / by Jack)

- F (OT710 trial page pricing/terms near CTA, paywall fallback): app-code
  verification, not an ASC metadata task.
- G (app icon + launch screen light/dark): app-code/asset verification.
- H (StoreKit products exist in ASC with correct prices/trial): confirm in
  App Store Connect > Monetization > Subscriptions before submitting; this
  session did not create or modify products.
- Submitting for review: **explicitly held for Jack's go**, per task
  instructions. This session pushed metadata only (no submit-for-review
  call was made).
