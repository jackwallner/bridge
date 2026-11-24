import XCTest
@testable import Bridge

/// Mirrors Mahj Trainer's `TrialOfferPacerTests`, plus the clock and
/// daylight-saving cases from its low-bug suite, so the two apps pace the
/// one-tap trial ask the same way.
@MainActor
final class TrialOfferPacerTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "TrialOfferPacerTests"
    private let day: TimeInterval = 24 * 60 * 60

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }

    /// Install at 9am, so "day 1" is the next calendar day.
    private var installed: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 9))!
    }

    private func due(_ now: Date, practices: Int = 5) -> Bool {
        TrialOfferPacer.autoOfferDue(practicesSinceOnboarding: practices, installedAt: installed, now: now,
                                     calendar: calendar, defaults: defaults)
    }

    private func ask(_ now: Date) {
        TrialOfferPacer.markAutoShown(installedAt: installed, now: now, calendar: calendar, defaults: defaults)
    }

    func testWaitsForTheSecondPracticeAfterOnboarding() {
        TrialOfferPacer.noteForeground(now: installed, defaults: defaults)
        XCTAssertFalse(due(installed, practices: 0))
        XCTAssertFalse(due(installed, practices: 1))
        XCTAssertTrue(due(installed, practices: 2))
    }

    func testInstallDayAndNextAreOncePerSession() {
        var now = installed
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        XCTAssertTrue(due(now))
        ask(now)
        XCTAssertFalse(due(now + 600), "one ask per session")

        // A quick trip away is the same session, even reported twice.
        TrialOfferPacer.noteBackground(now: now + 700, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + 900, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + 901, defaults: defaults)
        XCTAssertFalse(due(now + 1000))

        // Back after half an hour: a new session, a new ask.
        TrialOfferPacer.noteBackground(now: now + 1000, defaults: defaults)
        now += 1000 + TrialOfferPacer.sessionBreak
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + 1, defaults: defaults)
        XCTAssertTrue(due(now))
        ask(now)

        // The next morning is still session paced.
        TrialOfferPacer.noteBackground(now: now + 60, defaults: defaults)
        now = calendar.date(byAdding: .hour, value: 24, to: installed)!
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        XCTAssertTrue(TrialOfferPacer.isSessionPaced(installedAt: installed, now: now, calendar: calendar))
        XCTAssertTrue(due(now))
        ask(now)
        XCTAssertEqual(defaults.integer(forKey: TrialOfferPacer.dayPacedCountKey), 0)
    }

    func testAtMostThreeASessionPacedDay() {
        var now = installed
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        for visit in 1...4 {
            XCTAssertEqual(due(now), visit <= TrialOfferPacer.sessionPacedDailyCap, "visit \(visit)")
            if due(now) { ask(now) }
            TrialOfferPacer.noteBackground(now: now + 60, defaults: defaults)
            now += 60 + TrialOfferPacer.sessionBreak
            TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        }
        // The cap resets with the next day.
        now = calendar.date(byAdding: .day, value: 1, to: installed)!
        TrialOfferPacer.noteBackground(now: now - 1, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + TrialOfferPacer.sessionBreak, defaults: defaults)
        XCTAssertTrue(due(now + TrialOfferPacer.sessionBreak))
    }

    func testAfterTheFirstTwoDaysAsksAreDaysApart() {
        TrialOfferPacer.noteForeground(now: installed, defaults: defaults)
        var now = calendar.date(byAdding: .day, value: 1, to: installed)!
        ask(now)
        now = calendar.date(byAdding: .day, value: 2, to: installed)!
        XCTAssertFalse(TrialOfferPacer.isSessionPaced(installedAt: installed, now: now, calendar: calendar))
        // Sessions no longer matter; days since the last ask do.
        for gapDays in [3.0, 7, 14, 14] {
            let last = defaults.object(forKey: TrialOfferPacer.lastShownKey) as! Date
            XCTAssertFalse(due(last + (gapDays - 0.5) * day))
            now = last + gapDays * day
            XCTAssertTrue(due(now))
            ask(now)
        }
    }

    func testRatingPromptStandsDownRightAfterAnAutoAsk() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertFalse(TrialOfferPacer.autoShownRecently(now: now, defaults: defaults))
        TrialOfferPacer.markAutoShown(installedAt: nil, now: now, defaults: defaults)
        XCTAssertTrue(TrialOfferPacer.autoShownRecently(now: now + 10, defaults: defaults))
        XCTAssertFalse(TrialOfferPacer.autoShownRecently(now: now + 600, defaults: defaults))
    }

    func testAnAskWaitingOnStoreKitHoldsTheRatingPrompt() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        TrialOfferPacer.autoOffersPending += 1
        defer { TrialOfferPacer.autoOffersPending -= 1 }
        XCTAssertTrue(TrialOfferPacer.autoShownRecently(now: now, defaults: defaults))
    }

    func testTrialOfferIsNotBlockedByAStampFromAClockThatRanAhead() {
        let now = Date()
        let installed = now.addingTimeInterval(-60 * day)
        defaults.set(now.addingTimeInterval(31 * day), forKey: TrialOfferPacer.lastShownKey)
        XCTAssertTrue(TrialOfferPacer.autoOfferDue(practicesSinceOnboarding: 5, installedAt: installed, now: now, defaults: defaults))
        XCTAssertFalse(TrialOfferPacer.autoShownRecently(now: now, defaults: defaults))
        // A stamp in the past still holds the gap.
        defaults.set(now.addingTimeInterval(-day), forKey: TrialOfferPacer.lastShownKey)
        XCTAssertFalse(TrialOfferPacer.autoOfferDue(practicesSinceOnboarding: 5, installedAt: installed, now: now, defaults: defaults))
    }

    func testInstallDayPacingAcrossALebanonClockChange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Beirut")!
        let installed = calendar.date(from: DateComponents(year: 2027, month: 3, day: 28, hour: 20))!
        let monday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 29, hour: 12))!
        let tuesday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 30, hour: 12))!
        XCTAssertTrue(TrialOfferPacer.isSessionPaced(installedAt: installed, now: monday, calendar: calendar))
        XCTAssertFalse(TrialOfferPacer.isSessionPaced(installedAt: installed, now: tuesday, calendar: calendar),
                       "two calendar days after install is day paced")
    }

    /// Members, the onboarding tour, an unread customer record and the remote
    /// switch each stop the automatic ask on their own.
    func testOnlyAnOnboardedResolvedNonMemberWithTheSwitchOnIsAsked() {
        XCTAssertTrue(TrialOfferEligibility.autoOfferAllowed(isMember: false, membershipResolved: true,
                                                            hasOnboarded: true, switchOn: true, due: true))
        XCTAssertFalse(TrialOfferEligibility.autoOfferAllowed(isMember: true, membershipResolved: true,
                                                             hasOnboarded: true, switchOn: true, due: true))
        XCTAssertFalse(TrialOfferEligibility.autoOfferAllowed(isMember: false, membershipResolved: false,
                                                             hasOnboarded: true, switchOn: true, due: true))
        XCTAssertFalse(TrialOfferEligibility.autoOfferAllowed(isMember: false, membershipResolved: true,
                                                             hasOnboarded: false, switchOn: true, due: true))
        XCTAssertFalse(TrialOfferEligibility.autoOfferAllowed(isMember: false, membershipResolved: true,
                                                             hasOnboarded: true, switchOn: false, due: true))
        XCTAssertFalse(TrialOfferEligibility.autoOfferAllowed(isMember: false, membershipResolved: true,
                                                             hasOnboarded: true, switchOn: true, due: false))
    }

    func testPitchCardIsHiddenFromMembersAndTheTour() {
        XCTAssertTrue(BridgePlusPitchCard.isShown(isMember: false, membershipResolved: true, hasOnboarded: true))
        XCTAssertFalse(BridgePlusPitchCard.isShown(isMember: true, membershipResolved: true, hasOnboarded: true))
        XCTAssertFalse(BridgePlusPitchCard.isShown(isMember: false, membershipResolved: false, hasOnboarded: true))
        XCTAssertFalse(BridgePlusPitchCard.isShown(isMember: false, membershipResolved: true, hasOnboarded: false))
    }

    func testTrialOfferSwitchIsOnUnlessExactlyOff() {
        XCTAssertTrue(RemoteConfig.isOn(.trialOffer, in: nil))
        XCTAssertTrue(RemoteConfig.isOn(.trialOffer, in: ["trial_offer": "on"]))
        XCTAssertFalse(RemoteConfig.isOn(.trialOffer, in: ["trial_offer": "off"]))
    }

    /// The results card offers a free week only to an account that can have one.
    func testPitchCardOffersNoFreeWeekToAnIneligibleAccount() {
        XCTAssertEqual(BridgePlusPitchCard.defaultHeadline(trialEligible: true), "Try Bridge+ free for 7 days")
        let ineligible = BridgePlusPitchCard.defaultHeadline(trialEligible: false)
        XCTAssertFalse(ineligible.localizedCaseInsensitiveContains("free"))
        XCTAssertFalse(ineligible.contains("7 days"))
    }

    /// An Apple Account that already had its free week is told the price it
    /// pays today.
    func testTermsWithoutAFreeWeekPromiseNoTrial() {
        let paid = PaywallPricing.terms(amount: "$8.99/month", plan: .monthly, trial: false)
        XCTAssertEqual(paid, "$8.99/month, billed today. Auto-renews until canceled.")
        XCTAssertFalse(paid.localizedCaseInsensitiveContains("free"))
        XCTAssertFalse(PaywallPricing.terms(amount: nil, plan: .monthly, trial: false).localizedCaseInsensitiveContains("free"))
        XCTAssertEqual(PaywallPricing.terms(amount: "$8.99/month", plan: .monthly, trial: true),
                       "7 days free, then $8.99/month. Auto-renews until canceled.")
    }

    func testTheSheetBuysTheOnboardingPlan() {
        XCTAssertEqual(TrialOfferSheet.plan, .monthly)
    }

    func testImpressionIDsSeparateAutoFromTapped() {
        XCTAssertEqual(TrialOfferContext.drillResult.source(auto: false), "bridge_offer_drill")
        XCTAssertEqual(TrialOfferContext.drillResult.source(auto: true), "bridge_offer_drill_auto")
        XCTAssertEqual(TrialOfferContext.handSpent.source(auto: false), "bridge_offer_hand")
        XCTAssertEqual(TrialOfferContext.handSpent.source(auto: true), "bridge_offer_hand_auto")
    }

    func testOfferCopyNeverAssumesTheModeNameOrUsesADash() {
        for line in TrialOfferSheet.benefits + [TrialOfferContext.drillResult.headline, TrialOfferContext.handSpent.headline] {
            XCTAssertFalse(line.localizedCaseInsensitiveContains("Play a Hand"), line)
            XCTAssertFalse(line.contains("\u{2014}"), line)
        }
    }
}
