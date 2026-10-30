import Foundation
import XCTest

import RevenueCat

@testable import Bridge
/// The fleet paywall record, checked in this app's own build.
///
/// The `rc-funnel-probe` run proves an impression reaches RevenueCat. These
/// prove what is underneath it: the counts, the conversion freeze, RevenueCat's
/// silent 40-character key limit, and the rule that nothing here may carry free
/// text or health data. Every assertion is a claim that will be read off a
/// customer record later, so a wrong value is worse than no value.

final class PaywallFunnelTests: XCTestCase {

    private var suite: UserDefaults!

    override func setUp() {
        super.setUp()
        // A throwaway suite per test. These counters outlive a launch and would
        // otherwise carry between tests and into the real container.
        let name = "conv.tests.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: name)!
        ConversionDiagnostics.defaultsOverride = suite
    }

    override func tearDown() {
        ConversionDiagnostics.defaultsOverride = nil
        suite = nil
        super.tearDown()
    }

    func testCountsPitchesPerSurfaceAndInTotal() {
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_paywall_sheet")

        let attributes = ConversionDiagnostics.subscriberAttributes
        XCTAssertEqual(attributes["pitch_views_total"], "3")
        XCTAssertEqual(attributes["pitch_views_onboarding_trial"], "2")
        XCTAssertEqual(attributes["pitch_last"], "paywall_sheet")
    }

    func testNoAttributesBeforeAnyPitchIsSeen() {
        // Someone never shown a paywall has nothing to say about paywalls.
        // Zeros would make them look like a funnel failure.
        ConversionDiagnostics.recordAppOpen()
        XCTAssertTrue(ConversionDiagnostics.subscriberAttributes.isEmpty)
    }

    func testRecordsHowEarlyTheFirstPitchArrived() {
        ConversionDiagnostics.recordAppOpen()
        ConversionDiagnostics.recordAppOpen()
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")

        let attributes = ConversionDiagnostics.subscriberAttributes
        XCTAssertEqual(attributes["opens_before_first_pitch"], "2")
        XCTAssertEqual(attributes["days_since_install"], "0")
    }

    func testTheEarlinessPairIsFrozenOnTheFirstPitchOnly() {
        ConversionDiagnostics.recordAppOpen()
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")
        ConversionDiagnostics.recordAppOpen()
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_paywall_sheet")

        XCTAssertEqual(
            ConversionDiagnostics.subscriberAttributes["opens_before_first_pitch"],
            "1"
        )
    }

    func testAnInstallThatPredatesThisCodeReportsNoAge() {
        // No recorded app open, so no install stamp. Absent is the honest
        // answer; zero would claim they were asked on their first day.
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")
        XCTAssertNil(ConversionDiagnostics.subscriberAttributes["days_since_install"])
        XCTAssertNotNil(ConversionDiagnostics.subscriberAttributes["pitch_views_total"])
    }

    func testConversionFreezesTheSurfaceAndCountAtTheMomentOfSale() {
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_paywall_sheet")
        ConversionDiagnostics.recordConversion(plan: "yearly", startedTrial: true, offeringID: "default")
        // A pitch after the sale must not rewrite how they converted.
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")

        let attributes = ConversionDiagnostics.subscriberAttributes
        XCTAssertEqual(attributes["converted_surface"], "paywall_sheet")
        XCTAssertEqual(attributes["pitch_views_at_convert"], "2")
        XCTAssertEqual(attributes["converted_plan"], "yearly")
        XCTAssertEqual(attributes["converted_with_trial"], "true")
        XCTAssertEqual(attributes["converted_offering"], "default")
    }

    func testOnlyTheFirstConversionIsRecorded() {
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")
        ConversionDiagnostics.recordConversion(plan: "monthly", startedTrial: true)
        // A renewal or plan change is not a new answer to what sold them.
        ConversionDiagnostics.recordConversion(plan: "yearly", startedTrial: false)

        let attributes = ConversionDiagnostics.subscriberAttributes
        XCTAssertEqual(attributes["converted_plan"], "monthly")
        XCTAssertEqual(attributes["converted_with_trial"], "true")
    }

    func testAttributeKeysStayInsideRevenueCatsLimit() {
        // RevenueCat drops a key over 40 characters, silently.
        let long = String(repeating: "a", count: 80)
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_\(long)")
        for key in ConversionDiagnostics.subscriberAttributes.keys {
            XCTAssertLessThanOrEqual(key.count, 40, "attribute key too long: \(key)")
        }
    }

    func testNoAttributeCarriesFreeTextOrHealthData() {
        ConversionDiagnostics.recordAppOpen()
        ConversionDiagnostics.recordPitchView(impressionID: "bridge_onboarding_trial")
        ConversionDiagnostics.recordConversion(plan: "monthly", startedTrial: false)

        for (key, value) in ConversionDiagnostics.subscriberAttributes {
            XCTAssertFalse(value.contains(" "), "\(key) looks like free text: \(value)")
            XCTAssertLessThanOrEqual(value.count, 64, "\(key) is too long to be a label")
        }
    }
}

@MainActor
private final class MockPurchases: RevenueCatClient {
    var cachedCustomerInfo: CustomerInfo?
    var info = makeInfo(active: false)
    var fetchError: Error?
    var fetchHandler: ((CacheFetchPolicy) async throws -> CustomerInfo)?
    var purchaseCalls = 0
    var restoreCalls = 0
    var cancelPurchase = false
    var syncHandler: (() async throws -> CustomerInfo)?
    var policies: [CacheFetchPolicy] = []
    var eligibility: [String: IntroEligibilityStatus] = [:]

    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo {
        policies.append(fetchPolicy)
        if let fetchHandler { return try await fetchHandler(fetchPolicy) }
        if let fetchError { throw fetchError }
        return info
    }
    var offering: Offering?
    func paywallOffering(forceRefresh: Bool) async throws -> Offering? {
        if let fetchError { throw fetchError }
        return offering
    }
    func purchase(package: Package) async throws -> PurchaseResultData {
        purchaseCalls += 1
        return (nil, info, cancelPurchase)
    }
    func restorePurchases() async throws -> CustomerInfo {
        restoreCalls += 1
        if let fetchError { throw fetchError }
        return info
    }
    func introEligibility(productIdentifiers: [String]) async -> [String: IntroEligibilityStatus] { eligibility }
    func syncPurchases() async throws -> CustomerInfo {
        if let syncHandler { return try await syncHandler() }
        return info
    }
    func setSubscriberAttributes(_ attributes: [String: String]) {}
    func recordImpression(_ params: CustomPaywallImpressionParams) {}
}

@MainActor
private func makeInfo(active: Bool, date: Date = .now, lifetime: Bool = false, identifier: String = RevenueCatConfig.entitlement) -> CustomerInfo {
    let entitlement = EntitlementInfo(
        identifier: identifier, isActive: active, willRenew: active && !lifetime,
        periodType: .normal, latestPurchaseDate: date, originalPurchaseDate: date,
        expirationDate: lifetime ? nil : date.addingTimeInterval(active ? 86_400 : -86_400),
        store: .appStore, productIdentifier: lifetime ? "com.jackwallner.bridge.lifetime" : "com.jackwallner.bridge.monthly",
        isSandbox: true, ownershipType: .purchased
    )
    return CustomerInfo(entitlements: EntitlementInfos(entitlements: [identifier: entitlement]),
                        requestDate: date, firstSeen: date, originalAppUserId: "purchase-unit-test")
}

@MainActor
private func makePackage() -> Package {
    let product = TestStoreProduct(
        localizedTitle: "Monthly", price: 3.99, currencyCode: "USD",
        localizedPriceString: "$3.99", productIdentifier: "com.jackwallner.bridge.monthly",
        productType: .autoRenewableSubscription, localizedDescription: "Monthly access",
        subscriptionPeriod: .init(value: 1, unit: .month),
        introductoryDiscount: TestStoreProductDiscount(
            identifier: "trial", price: 0, localizedPriceString: "$0.00", paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 1, unit: .week), numberOfPeriods: 1, type: .introductory
        ), locale: Locale(identifier: "en_US")
    ).toStoreProduct()
    return Package(identifier: "$rc_monthly", packageType: .monthly, storeProduct: product,
                   offeringIdentifier: "default", webCheckoutUrl: nil)
}

@MainActor
final class PurchaseEntitlementTests: XCTestCase {
    func testDebugAndSimulatorNeverSelectProductionKey() {
        for simulator in [true, false] {
            XCTAssertNil(RevenueCatEnvironment.key(production: "appl_prod", isDebug: true, isSimulator: simulator, testKey: nil))
            XCTAssertNil(RevenueCatEnvironment.key(production: "appl_prod", isDebug: true, isSimulator: simulator, testKey: "appl_prod"))
            XCTAssertEqual(RevenueCatEnvironment.key(production: "appl_prod", isDebug: true, isSimulator: simulator, testKey: "test_qa"), "test_qa")
        }
        XCTAssertNil(RevenueCatEnvironment.key(production: "appl_prod", isDebug: false, isSimulator: true, testKey: "test_qa"))
        XCTAssertEqual(RevenueCatEnvironment.key(production: "appl_prod", isDebug: false, isSimulator: false, testKey: "test_qa"), "appl_prod")
    }

    func testCachedPremiumUnlocksBeforeNetworkRespondsAndSurvivesOffline() async {
        let mock = MockPurchases()
        mock.cachedCustomerInfo = makeInfo(active: true)
        mock.fetchError = URLError(.notConnectedToInternet)
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        service.start()
        XCTAssertTrue(service.isPro)
        await service.refreshCustomerInfo(fetchCurrent: true)
        XCTAssertTrue(service.isPro)
    }

    func testUnresolvedMembershipCannotStartAnotherPurchase() async {
        let mock = MockPurchases()
        mock.fetchError = URLError(.notConnectedToInternet)
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        XCTAssertTrue(service.isCheckingEntitlements)
        _ = try? await service.purchase(makePackage())
        XCTAssertEqual(mock.purchaseCalls, 0)
        XCTAssertFalse(service.isCheckingEntitlements)
    }

    func testRestoreUnlocksLifetimeWithoutBuyingAgain() async throws {
        let mock = MockPurchases()
        mock.info = makeInfo(active: true, lifetime: true)
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        try await service.restore()
        XCTAssertTrue(service.isPro)
        XCTAssertEqual(mock.restoreCalls, 1)
        _ = try await service.purchase(makePackage())
        XCTAssertEqual(mock.purchaseCalls, 0)
        XCTAssertNil(service.expirationDate)
    }

    func testPurchaseAndCancellationUseRevenueCatResult() async throws {
        let mock = MockPurchases()
        mock.info = makeInfo(active: false)
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        await service.refreshCustomerInfo()
        mock.cancelPurchase = true
        let cancelled = try await service.purchase(makePackage())
        XCTAssertEqual(cancelled, .cancelled)
        XCTAssertFalse(service.isPro)
        mock.cancelPurchase = false
        mock.info = makeInfo(active: true)
        let purchased = try await service.purchase(makePackage())
        XCTAssertEqual(purchased, .purchased)
        XCTAssertTrue(service.isPro)
        XCTAssertEqual(mock.purchaseCalls, 2)
    }

    func testDelayedFreeFetchCannotRelockACompletedRestore() async throws {
        let mock = MockPurchases()
        let old = makeInfo(active: false, date: Date(timeIntervalSinceNow: -60))
        mock.info = makeInfo(active: true)
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var continuation: CheckedContinuation<CustomerInfo, Never>?
        mock.fetchHandler = { _ in await withCheckedContinuation { continuation = $0 } }
        let fetch = Task { await service.refreshCustomerInfo(fetchCurrent: true) }
        while continuation == nil { await Task.yield() }
        try await service.restore()
        continuation?.resume(returning: old)
        await fetch.value
        XCTAssertTrue(service.isPro)
    }

    func testListenerUpdatesItsOwnServiceAndIgnoresOlderRecords() async throws {
        let mock = MockPurchases()
        let now = Date()
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        await service.receive(makeInfo(active: true, date: now)).value
        XCTAssertTrue(service.isPro)
        await service.receive(makeInfo(active: false, date: now.addingTimeInterval(-60))).value
        XCTAssertTrue(service.isPro)
        await service.receive(makeInfo(active: false, date: now.addingTimeInterval(60))).value
        XCTAssertFalse(service.isPro)
    }
    func testMissingSDKCannotGrantPremium() async {
        let service = SubscriptionService(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        do {
            _ = try await service.purchase(nil)
            XCTFail("An unavailable store must not create a purchase")
        } catch {}
        XCTAssertFalse(service.isPro)
    }

    func testPendingReinstallRecoveryCannotStartAnotherPurchase() async throws {
        let mock = MockPurchases()
        let recovered = makeInfo(active: true)
        var continuation: CheckedContinuation<CustomerInfo, Never>?
        mock.syncHandler = { await withCheckedContinuation { continuation = $0 } }
        let service = SubscriptionService(
            client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!,
            ownsCurrentPurchase: { true }
        )
        await service.refreshCustomerInfo()
        let recovery = Task { await service.recoverReinstalledMembershipIfNeeded() }
        while continuation == nil { await Task.yield() }
        XCTAssertTrue(service.isCheckingEntitlements)
        do {
            _ = try await service.purchase(makePackage())
            XCTFail("An existing purchase must finish syncing before another sale")
        } catch PurchaseError.membershipPending {
        } catch {
            XCTFail("Unexpected purchase error: \(error)")
        }
        XCTAssertEqual(mock.purchaseCalls, 0)
        continuation?.resume(returning: recovered)
        await recovery.value
        XCTAssertTrue(service.isPro)
        XCTAssertFalse(service.isCheckingEntitlements)
    }

    /// BR-01: a launch fetch that failed left `membershipResolved` false, and
    /// both purchase buttons are disabled until it turns true. Loading prices
    /// again must also read the customer record again.
    func testFailedFirstFetchRecoversWhenPricesLoadAgain() async {
        let mock = MockPurchases()
        mock.offering = Offering(identifier: "default", serverDescription: "Test", paywall: nil,
                                 availablePackages: [makePackage()], webCheckoutUrl: nil)
        mock.fetchError = URLError(.notConnectedToInternet)
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        await service.refreshCustomerInfo()
        await service.loadOfferings()
        XCTAssertFalse(service.isCheckingEntitlements)
        XCTAssertFalse(service.membershipResolved)
        mock.fetchError = nil
        await service.ensureOfferings()
        XCTAssertNotNil(service.paywallPrice(for: .monthly))
        XCTAssertTrue(service.membershipResolved)
    }

    func testFailedFirstFetchRecoversOnTheFirstOfferingsLoad() async {
        let mock = MockPurchases()
        mock.fetchError = URLError(.notConnectedToInternet)
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        await service.refreshCustomerInfo()
        mock.fetchError = nil
        await service.loadOfferings()
        XCTAssertTrue(service.membershipResolved)
    }

    func testUnknownOrIneligibleAccountIsNeverPromisedAFreeTrial() async {
        let mock = MockPurchases()
        mock.offering = Offering(identifier: "default", serverDescription: "Test", paywall: nil,
                                 availablePackages: [makePackage()], webCheckoutUrl: nil)
        mock.eligibility = ["com.jackwallner.bridge.monthly": .ineligible]
        let service = SubscriptionService(client: mock, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        await service.loadOfferings()
        XCTAssertFalse(service.trialCTA(.onboarding).localizedCaseInsensitiveContains("free"))
        XCTAssertFalse(PaywallPricing.terms(service, .monthly).localizedCaseInsensitiveContains("free"))
        XCTAssertFalse(PaywallPricing.planDetail(service, .monthly).localizedCaseInsensitiveContains("free"))
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(trialEligible: service.isEligibleForIntroOffer(.monthly)), "Join \(Membership.name)")
        mock.eligibility = ["com.jackwallner.bridge.monthly": .eligible]
        await service.loadOfferings()
        XCTAssertTrue(service.trialCTA(.onboarding).localizedCaseInsensitiveContains("free"))
        XCTAssertTrue(PaywallPricing.terms(service, .monthly).contains("7 days free"))
    }

}

final class UpgradeIntentTests: XCTestCase {
    func testPurchasedTrainingActionIsConsumedOnce() {
        let destinations: [AppDestination] = [
            .endlessPicker, .bridgeMinute, .gameNightPrep, .timedChallenge, .review, .gameNightPrepSession
        ]
        for destination in destinations {
            var intent = UpgradeIntent<AppDestination>()
            intent.destination = destination
            XCTAssertEqual(intent.consume(isMember: true), destination)
            XCTAssertNil(intent.consume(isMember: true))
        }
    }

    func testCancelledDrillDoesNotOpenAfterALaterUpgrade() {
        var intent = UpgradeIntent<String>()
        intent.destination = "chosen-drill"
        XCTAssertNil(intent.consume(isMember: false))
        XCTAssertNil(intent.consume(isMember: true))
    }

    func testPurchasedDrillPreservesTheChoice() {
        var intent = UpgradeIntent<String>()
        intent.destination = "chosen-drill"
        XCTAssertEqual(intent.consume(isMember: true), "chosen-drill")
        XCTAssertNil(intent.destination)
    }

    func testGenericUpgradeDoesNotInventADestination() {
        var intent = UpgradeIntent<AppDestination>()
        XCTAssertNil(intent.consume(isMember: true))
    }
}
