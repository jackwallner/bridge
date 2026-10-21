import XCTest
@testable import Bridge

/// The trial flow's copy is the shipped copy; only the button wording varies,
/// and only among the wordings compiled in (`TrialCTA`).
@MainActor
final class TrialCopyTests: XCTestCase {
    func testTermsAreTheShippedLines() {
        XCTAssertEqual(
            PaywallPricing.terms(amount: "$9.99/month", plan: .monthly),
            "7 days free, then $9.99/month. Auto-renews until canceled."
        )
        XCTAssertEqual(PaywallPricing.terms(amount: nil, plan: .yearly), "Includes 7 days free. Auto-renews until canceled.")
        XCTAssertEqual(PaywallPricing.terms(amount: "$49.99", plan: .lifetime), "$49.99 one-time. Not a subscription, nothing renews.")
    }

    /// An Apple Account that already had its free week is charged on day one,
    /// so no line promises a trial and the billed amount leads.
    func testIneligibleAccountsSeeTheBilledTodayLine() {
        XCTAssertEqual(
            PaywallPricing.terms(amount: "$8.99/month", plan: .monthly, trial: false),
            "$8.99/month, billed today. Auto-renews until canceled."
        )
        XCTAssertEqual(
            PaywallPricing.terms(amount: nil, plan: .yearly, trial: false),
            "Billed today. Auto-renews until canceled."
        )
        XCTAssertEqual(
            PaywallPricing.terms(amount: "$79.99", plan: .lifetime, trial: false),
            "$79.99 one-time. Not a subscription, nothing renews."
        )
        XCTAssertEqual(PaywallPlan.yearly.ctaTitle(trialEligible: false), "Join \(Membership.name)")
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(trialEligible: true), "Start 7-Day Free Trial")
        XCTAssertEqual(
            PaywallPlan.lifetime.ctaTitle(trialEligible: false),
            PaywallPlan.lifetime.ctaTitle()
        )
        for plan in PaywallPlan.allCases {
            for amount in [nil, "$8.99/month"] {
                let line = PaywallPricing.terms(amount: amount, plan: plan, trial: false)
                XCTAssertFalse(line.localizedCaseInsensitiveContains("free"), line)
                XCTAssertFalse(line.contains("\u{2014}"), line)
            }
        }
    }

    func testControlIsTheShippedButton() {
        XCTAssertEqual(PaywallPlan.yearly.ctaTitle(), "Start 7-Day Free Trial")
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(), "Start 7-Day Free Trial")
        XCTAssertFalse(PaywallPlan.lifetime.ctaTitle().contains("Trial"))
        XCTAssertEqual(TrialCTA.sevenDay.title(.onboarding), "Start 7-day free trial")
    }

    /// No metadata, a typo, or a non-string all mean the control.
    func testOfferingMetadataPicksOnlyAKnownArm() {
        XCTAssertEqual(TrialCTA.from(metadata: nil), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: [:]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "mine"]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": 1]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "my"]), .my)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "your"]), .your)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "seven_day"]), .sevenDay)
    }

    func testEveryArmNamesTheTrialOnBothSurfaces() {
        for arm in TrialCTA.allCases {
            for surface in [TrialCTA.Surface.onboarding, .paywall] {
                let title = arm.title(surface)
                XCTAssertTrue(title.localizedCaseInsensitiveContains("free trial"), title)
                XCTAssertLessThanOrEqual(title.count, 24, title)
                XCTAssertFalse(title.contains("\u{2014}"), title)
            }
        }
    }

    /// Switches are on unless RevenueCat says exactly "off".
    func testSwitchesDefaultOn() {
        // The keys set in RevenueCat; renaming one would silently disarm it.
        XCTAssertEqual(RemoteSwitch.allCases.map(\.rawValue), ["att_prompt", "rating_prompt", "challenge"])
        for remoteSwitch in RemoteSwitch.allCases {
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: nil))
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: "on"]))
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: false]))
            XCTAssertFalse(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: "off"]))
        }
    }

    /// The onboarding trial page must always name the plan its button buys.
    func testOnboardingTrialDisclosureNamesTheMonthlyPlan() {
        XCTAssertTrue(PaywallPricing.terms(amount: "$8.99/month", plan: .monthly).contains("$8.99/month"))
    }
}
