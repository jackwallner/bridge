import XCTest
@testable import Bridge

final class MembershipTransitionsTests: XCTestCase {
    private let trialOn = MembershipSnapshot(isActive: true, isTrial: true, willRenew: true)
    private let trialOff = MembershipSnapshot(isActive: true, isTrial: true, willRenew: false)
    private let paidOn = MembershipSnapshot(isActive: true, isTrial: false, willRenew: true)
    private let paidOff = MembershipSnapshot(isActive: true, isTrial: false, willRenew: false)
    private let gone = MembershipSnapshot.none

    func testFirstObservationIsNeverAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: nil, to: gone))
        XCTAssertNil(MembershipTransitions.churnMoment(from: nil, to: trialOff))
    }

    func testTrialTurningRenewalOff() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: trialOn, to: trialOff), .trialRenewalOff)
    }

    func testPaidTurningRenewalOff() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: paidOn, to: paidOff), .paidRenewalOff)
    }

    func testTrialLapsing() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: trialOn, to: gone), .trialLapsed)
        XCTAssertEqual(MembershipTransitions.churnMoment(from: trialOff, to: gone), .trialLapsed)
    }

    func testPaidLapsing() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: paidOff, to: gone), .paidLapsed)
    }

    func testTrialConvertingIsNotAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: trialOn, to: paidOn))
    }

    func testStayingGoneIsNotAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: gone, to: gone))
    }

    func testTurningRenewalBackOnIsNotAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: paidOff, to: paidOn))
    }

    func testComingBackResetsTheAsk() {
        XCTAssertTrue(MembershipTransitions.resetsAsk(from: paidOff, to: paidOn))
        XCTAssertTrue(MembershipTransitions.resetsAsk(from: gone, to: trialOn))
        XCTAssertFalse(MembershipTransitions.resetsAsk(from: paidOn, to: paidOn))
        XCTAssertFalse(MembershipTransitions.resetsAsk(from: nil, to: paidOn))
    }

    @MainActor
    func testServiceRemembersOneMomentPerDeparture() {
        let defaults = UserDefaults(suiteName: "MembershipTransitionsTests")!
        defaults.removePersistentDomain(forName: "MembershipTransitionsTests")
        let service = SubscriptionService.shared
        service.consumeChurnMoment()

        service.observe(trialOn, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)
        service.observe(trialOff, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .trialRenewalOff)

        // Shown, then the trial lapses: no second question for the same exit.
        service.consumeChurnMoment()
        service.observe(gone, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)

        // They come back and leave again later: a fresh ask.
        service.observe(paidOn, defaults: defaults)
        service.observe(paidOff, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .paidRenewalOff)
        service.consumeChurnMoment()
    }

    /// Renewal off, then back on before Home asked: the queued question
    /// would now be false, so it goes.
    @MainActor
    func testComingBackDropsAQueuedQuestion() {
        let defaults = UserDefaults(suiteName: "MembershipTransitionsReturn")!
        defaults.removePersistentDomain(forName: "MembershipTransitionsReturn")
        let service = SubscriptionService.shared
        service.consumeChurnMoment()

        service.observe(trialOn, defaults: defaults)
        service.observe(trialOff, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .trialRenewalOff)
        service.observe(trialOn, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)
        XCTAssertNil(defaults.string(forKey: "membership.pendingChurnMoment"))

        // Leaving again later still gets its one ask.
        service.observe(trialOff, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .trialRenewalOff)
        service.consumeChurnMoment()
    }

    /// A months-old cached record must not become the first baseline: a
    /// member who lapsed on an older build was asked "why are you leaving"
    /// a second after launch.
    @MainActor
    func testStaleCachedRecordIsNeverTheFirstBaseline() {
        let defaults = UserDefaults(suiteName: "MembershipTransitionsStale")!
        defaults.removePersistentDomain(forName: "MembershipTransitionsStale")
        let service = SubscriptionService.shared
        service.consumeChurnMoment()
        let now = Date()

        service.observe(paidOn, answeredAt: now.addingTimeInterval(-60 * 86_400), now: now, defaults: defaults)
        service.observe(gone, answeredAt: now, now: now, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)

        // A fresh first record still counts, so a later departure is caught.
        service.observe(paidOn, answeredAt: now, now: now, defaults: defaults)
        service.observe(paidOff, answeredAt: now, now: now, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .paidRenewalOff)
        service.consumeChurnMoment()
    }

    /// Monthly to lifetime is an upgrade, not a departure. Lifetime reports
    /// willRenew false with no expiration date.
    func testUpgradingToLifetimeIsNotAChurnMoment() {
        let monthly = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: true, expirationDate: Date())
        let lifetime = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: false, expirationDate: nil)
        XCTAssertTrue(lifetime.willRenew)
        XCTAssertNil(MembershipTransitions.churnMoment(from: monthly, to: lifetime))
    }

    func testCancelledSubscriptionStillReadsAsRenewalOff() {
        let on = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: true, expirationDate: Date())
        let off = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: false, expirationDate: Date())
        XCTAssertEqual(MembershipTransitions.churnMoment(from: on, to: off), .paidRenewalOff)
    }
}
