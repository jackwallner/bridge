import Foundation
import RevenueCat
import StoreKit

/// The purchase boundary is injectable so entitlement flows can run without StoreKit.
@MainActor
protocol RevenueCatClient: AnyObject {
    var cachedCustomerInfo: CustomerInfo? { get }
    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo
    func paywallOffering(forceRefresh: Bool) async throws -> RevenueCat.Offering?
    func purchase(package: Package) async throws -> PurchaseResultData
    func restorePurchases() async throws -> CustomerInfo
    func introEligibility(productIdentifiers: [String]) async -> [String: IntroEligibilityStatus]
    func syncPurchases() async throws -> CustomerInfo
    func setSubscriberAttributes(_ attributes: [String: String])
    func recordImpression(_ params: CustomPaywallImpressionParams)
}

extension Purchases: RevenueCatClient {
    func paywallOffering(forceRefresh: Bool) async throws -> RevenueCat.Offering? {
        let offerings: Offerings
        if forceRefresh, let refreshed = try await syncAttributesAndOfferingsIfNeeded() {
            offerings = refreshed
        } else {
            offerings = try await self.offerings()
        }
        return offerings.current
    }

    func introEligibility(productIdentifiers: [String]) async -> [String: IntroEligibilityStatus] {
        await checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers).mapValues(\.status)
    }

    func setSubscriberAttributes(_ attributes: [String: String]) {
        attribution.setAttributes(attributes)
    }

    func recordImpression(_ params: CustomPaywallImpressionParams) {
        trackCustomPaywallImpression(params)
    }
}

enum RevenueCatEnvironment {
    static func key(production: String, isDebug: Bool, isSimulator: Bool, testKey: String?) -> String? {
        if isDebug { return testKey?.hasPrefix("test_") == true ? testKey : nil }
        return !isSimulator && production.hasPrefix("appl_") ? production : nil
    }

    static var isDebug: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
}

enum RevenueCatConfig {
    /// Prod public SDK key (safe to ship; sim builds never configure with it).
    static let apiKey = "appl_ZITvIQJfBJBvvpiATcXJJNmKRXY"
    static let entitlement = "Bridge+"
}

/// What actually happened at Apple's sheet. A cancel is an outcome, not an error.
enum PurchaseOutcome: Sendable {
    case purchased
    case cancelled
}

enum PurchaseError: LocalizedError {
    case productsUnavailable
    case membershipPending

    var errorDescription: String? {
        switch self {
        case .productsUnavailable:
            String(localized: "The App Store isn't reachable right now. Check your connection and try again.")
        case .membershipPending:
            String(localized: "We're still checking your purchases. Try again in a moment.")
        }
    }
}

struct PaywallPrice {
    let amount: Decimal
    let localized: String
    let locale: Locale
}

@MainActor
final class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var isPro = false
    @Published private(set) var currentOffering: Offering?
    @Published private(set) var introEligibility: [String: IntroEligibilityStatus] = [:]
    /// False until a customer record has actually been read, from
    /// RevenueCat's on-device cache or the network. `isPro` is false before
    /// that for members too, so nothing may treat "not a member" as a lapse,
    /// or sell a member a trial, until this is true.
    @Published private(set) var membershipResolved = false
    /// The active entitlement is the free week (RevenueCat `periodType`), not a
    /// paid or lifetime membership.
    @Published private(set) var isTrialing = false
    /// When the current entitlement ends. nil for lifetime and for no membership.
    @Published private(set) var expirationDate: Date?
    /// Set when a trial or membership was just seen turning toward the exit,
    /// and not yet asked about. Home presents the one-question prompt and
    /// clears it. Survives a launch: the ask is stored, not just published.
    @Published private(set) var pendingChurnMoment: ChurnMoment?

    private let clientOverride: (any RevenueCatClient)?
    private var client: any RevenueCatClient { clientOverride ?? Purchases.shared }
    private var lastCustomerInfoDate: Date?
    @Published private(set) var entitlementCheckFailed = false
    var isCheckingEntitlements: Bool {
        isConfigured && !isPro && (membershipRecovery != nil || (!membershipResolved && !entitlementCheckFailed))
    }
    private var isConfigured = false
    private let defaults: UserDefaults
    private let ownsCurrentPurchase: () async -> Bool
    #if DEBUG
    private let localOverrideKey = "subscription.localProOverride"
    #endif
    private let snapshotKey = "membership.lastSnapshot"
    private let churnAskSpentKey = "membership.churnAskSpent"
    private let pendingChurnKey = "membership.pendingChurnMoment"
    private let reinstallSyncKey = "membership.reinstallSyncDone"
    /// How old a customer record may be and still serve as the first baseline.
    static let freshBaselineAge: TimeInterval = 300
    @Published private var membershipRecovery: Task<Void, Never>?
    private var paywallImpressionsThisSession: Set<String> = []

    init(
        client: (any RevenueCatClient)? = nil,
        defaults: UserDefaults = .standard,
        ownsCurrentPurchase: @escaping () async -> Bool = {
            for await result in Transaction.currentEntitlements {
                if case .verified = result { return true }
            }
            return false
        }
    ) {
        clientOverride = client
        self.defaults = defaults
        self.ownsCurrentPurchase = ownsCurrentPurchase
        super.init()
        isConfigured = client != nil
        #if DEBUG
        isPro = defaults.bool(forKey: localOverrideKey)
        #endif
        pendingChurnMoment = defaults.string(forKey: pendingChurnKey)
            .flatMap(ChurnMoment.init(rawValue:))
    }

    /// The offering's metadata (the remote switches) is known: loaded, or
    /// there is no store to ask at all (simulator, screenshots).
    var remoteConfigKnown: Bool { currentOffering != nil || !isConfigured }

    /// The churn prompt was shown (or dismissed). One ask per departure.
    func consumeChurnMoment() {
        pendingChurnMoment = nil
        defaults.removeObject(forKey: pendingChurnKey)
    }

    func start() {
        configureIfNeeded()
        guard isConfigured else {
            // No store at all (simulator, screenshots): nothing will ever
            // load, so what we have is the answer.
            membershipResolved = true
            return
        }
        // The last record RevenueCat saw, from the first frame: a member is a
        // member before the network answers.
        if let cached = client.cachedCustomerInfo { apply(cached) }
        Task {
            // In parallel with offerings: a reinstalled member should be
            // recognised before the trial page can be reached.
            async let recovered: Void = recoverReinstalledMembershipIfNeeded()
            await refreshCustomerInfo()
            await loadOfferings()
            await recovered
        }
    }

    /// A reinstall is a new anonymous RevenueCat user, and iOS does not bring
    /// an existing subscription across on its own, so a paying member looked
    /// like a stranger (and was offered a trial) until they found Restore.
    /// StoreKit already knows what this Apple Account owns: if it holds a
    /// current entitlement and RevenueCat does not, sync once per install.
    /// `syncPurchases` never shows an Apple Account sign-in prompt.
    ///
    /// Retried (from `ensureOfferings`, so before any purchase) until one sync
    /// succeeds: a failed sync on a bad network must not lose it for good.
    /// A second caller (the trial button) waits for a sync already running
    /// instead of skipping it, so a slow sync cannot let a member be sold,
    /// but never holds the button more than a few seconds on a stalled one.
    func recoverReinstalledMembershipIfNeeded() async {
        if membershipRecovery != nil {
            // Poll rather than await the task: an await on it cannot be cut
            // short, and a task group waits for every child before it returns.
            let deadline = Date().addingTimeInterval(3)
            while membershipRecovery != nil, Date() < deadline {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return
        }
        guard isConfigured, !isPro, !defaults.bool(forKey: reinstallSyncKey) else { return }
        let recovery = Task { await recoverReinstalledMembership() }
        membershipRecovery = recovery
        await recovery.value
        membershipRecovery = nil
    }

    private func recoverReinstalledMembership() async {
        guard await ownsCurrentPurchase() else { return }
        guard let info = try? await client.syncPurchases() else { return }
        defaults.set(true, forKey: reinstallSyncKey)
        apply(info)
    }

    /// Dev/testing switch: flips Pro without a live RC key (Settings toggle).
    #if DEBUG
    func setLocalOverride(isPro: Bool) {
        defaults.set(isPro, forKey: localOverrideKey)
        self.isPro = isPro
    }
    #endif

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        #if DEBUG
        let testKey = RevenueCatProbe.isEnabled ? RevenueCatProbe.testStoreKey : nil
        #else
        let testKey: String? = nil
        #endif
        guard let key = RevenueCatEnvironment.key(
            production: RevenueCatConfig.apiKey,
            isDebug: RevenueCatEnvironment.isDebug,
            isSimulator: RevenueCatEnvironment.isSimulator,
            testKey: testKey
        ) else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: key)
                .with(appUserID: RevenueCatProbe.appUserID)
                .build()
        )
        #else
        Purchases.configure(withAPIKey: key)
        #endif
        Purchases.shared.delegate = self
        isConfigured = true
        #if !DEBUG
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        MetaAds.linkRevenueCat()
        #endif
    }

    /// Feeds RevenueCat's `paywall_encounter_v3`. A custom paywall emits no
    /// events of its own, so without this call everything between "installed"
    /// and "started a trial" is invisible for this app.
    func trackPaywallImpression(id: String, oncePerSession: Bool = false) {
        guard isConfigured else { return }
        if oncePerSession {
            guard !paywallImpressionsThisSession.contains(id) else { return }
            paywallImpressionsThisSession.insert(id)
        }
        ConversionDiagnostics.recordPitchView(impressionID: id)
        syncConversionAttributes()
        client.recordImpression(
            CustomPaywallImpressionParams(paywallId: id)
        )
    }

    /// Mirrors the on-device paywall record onto the RevenueCat customer.
    ///
    /// Attributes rather than extra impressions: RevenueCat treats every
    /// impression id as a paywall encounter, so funnel steps sent that way would
    /// drive the encounter rate to 100% and destroy the one server-side number
    /// that currently works.
    ///
    /// `isConfigured` is the load-bearing guard: `Purchases.shared` traps when
    /// RevenueCat was never configured, which is every simulator run.
    ///
    /// `setAttributes` only queues. RevenueCat uploads the queue when the app
    /// backgrounds, or folds it into the POST that creates a customer, and a
    /// customer-info fetch does NOT flush it (measured, not assumed). That is
    /// fine in production, where every session ends in a backgrounding, but it
    /// means a probe run has to background the app before reading anything
    /// back.
    func syncConversionAttributes() {
        guard isConfigured else { return }
        var attributes = ConversionDiagnostics.subscriberAttributes
        guard !attributes.isEmpty else { return }
        if let offering = currentOffering?.identifier {
            attributes["offering_id"] = offering
        }
        // Which trial button wording this customer saw (`RemoteConfig`), for
        // reading an Experiment by attribute as well as by offering.
        attributes.merge(remoteVariantAttributes) { _, new in new }
        client.setSubscriberAttributes(attributes)
    }

    /// `fetchCurrent` when the answer has to be new (right after a purchase):
    /// the default policy hands back a cached record for five minutes, so a
    /// "confirm" loop on it re-read the same stale record three times.
    func refreshCustomerInfo(fetchCurrent: Bool = false) async {
        guard isConfigured else { return }
        entitlementCheckFailed = false
        let policy: CacheFetchPolicy = fetchCurrent ? .fetchCurrent : .cachedOrFetched
        do {
            apply(try await client.customerInfo(fetchPolicy: policy))
        } catch {
            entitlementCheckFailed = true
        }
    }

    func loadOfferings() async {
        guard isConfigured else { return }
        introEligibility = [:]
        currentOffering = try? await client.paywallOffering(forceRefresh: false)
        let identifiers = currentOffering?.availablePackages.map(\.storeProduct.productIdentifier) ?? []
        let result = await client.introEligibility(productIdentifiers: identifiers)
        introEligibility = result
    }

    func isEligibleForIntroOffer(_ plan: PaywallPlan) -> Bool {
        guard let product = package(for: plan)?.storeProduct,
              product.introductoryDiscount?.paymentMode == .freeTrial else { return false }
        return introEligibility[product.productIdentifier] == .eligible
    }

    func package(for plan: PaywallPlan) -> Package? {
        guard let offering = currentOffering else { return nil }
        switch plan {
        case .yearly: return offering.annual
        case .monthly: return offering.monthly
        case .lifetime: return offering.lifetime
        }
    }

    func paywallPrice(for plan: PaywallPlan) -> PaywallPrice? {
        guard let product = package(for: plan)?.storeProduct else { return nil }
        return PaywallPrice(
            amount: product.price,
            localized: product.localizedPriceString,
            locale: product.priceFormatter?.locale ?? .current
        )
    }

    /// Offerings can still be in flight when a player reaches the trial CTA on
    /// a cold, slow network. Give them one more chance to land before we call
    /// the products missing, so the button isn't dead on a fast tapper.
    @discardableResult
    func ensureOfferings() async -> Bool {
        guard isConfigured else { return false }
        await recoverReinstalledMembershipIfNeeded()
        if currentOffering != nil { return true }
        await loadOfferings()
        return currentOffering != nil
    }

    func purchase(_ package: Package?) async throws -> PurchaseOutcome {
        guard isConfigured else { throw PurchaseError.productsUnavailable }
        if !membershipResolved { await refreshCustomerInfo() }
        if isPro { return .purchased }
        guard membershipRecovery == nil else { throw PurchaseError.membershipPending }
        guard membershipResolved else { throw PurchaseError.productsUnavailable }
        guard let package else { throw PurchaseError.productsUnavailable }
        let result = try await client.purchase(package: package)
        // RevenueCat reports a user backing out of Apple's sheet as a normal
        // result, not an error. Treating it as a failure is what used to shove
        // a second paywall in front of someone who just said "not now".
        if result.userCancelled { return .cancelled }
        apply(result.customerInfo)
        // What Apple actually sold, not what the product offers: a returning
        // subscriber buying a plan with a trial is charged on day one.
        let startedTrial = result.customerInfo.entitlements[RevenueCatConfig.entitlement]?.periodType == .trial
        ConversionDiagnostics.recordConversion(
            plan: package.storeProduct.productIdentifier,
            startedTrial: startedTrial,
            offeringID: package.presentedOfferingContext.offeringIdentifier
        )
        syncConversionAttributes()
        return .purchased
    }

    /// StoreKit says the money moved; RevenueCat's entitlement can take a beat
    /// to catch up. Poll briefly rather than leave someone who just paid
    /// staring at the paywall that took their money.
    @discardableResult
    func confirmEntitlement(attempts: Int = 3) async -> Bool {
        guard isConfigured else { return isPro }
        for attempt in 0..<attempts {
            await refreshCustomerInfo(fetchCurrent: true)
            if isPro { return true }
            if attempt < attempts - 1 {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
        }
        return isPro
    }

    func restore() async throws {
        guard isConfigured else { throw PurchaseError.productsUnavailable }
        let info = try await client.restorePurchases()
        apply(info)
    }

    private func apply(_ info: CustomerInfo) {
        guard lastCustomerInfoDate.map({ info.requestDate >= $0 }) ?? true else { return }
        lastCustomerInfoDate = info.requestDate
        let entitlement = info.entitlements[RevenueCatConfig.entitlement]
        let entitled = entitlement?.isActive == true
        #if DEBUG
        let override = defaults.bool(forKey: localOverrideKey)
        #else
        let override = false
        #endif
        isPro = entitled || override
        membershipResolved = true
        isTrialing = entitled && entitlement?.periodType == .trial
        expirationDate = entitled ? entitlement?.expirationDate : nil
        observe(MembershipSnapshot.observed(
            isActive: entitled,
            isTrial: entitlement?.periodType == .trial,
            // A card problem turns willRenew off too, but nobody chose to
            // leave: Apple is still retrying, so it is not a churn moment.
            willRenew: entitlement?.willRenew == true || entitlement?.billingIssueDetectedAt != nil,
            expirationDate: entitlement?.expirationDate
        ), answeredAt: info.requestDate, defaults: defaults)
    }

    /// Compares this customer record with the last one seen and remembers a
    /// churn moment, once per departure. Both snapshots come from RevenueCat,
    /// never from the local override, so a debug toggle cannot fake a lapse.
    ///
    /// The first record ever seen becomes the baseline only if RevenueCat
    /// answered it recently. Launch applies the cached record first, which
    /// can be months old: a member who lapsed on an older build read as
    /// active there, then lapsed a second later, and was asked why they were
    /// leaving about a departure the app never watched.
    func observe(
        _ current: MembershipSnapshot,
        answeredAt: Date = Date(),
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let previous = (defaults.data(forKey: snapshotKey))
            .flatMap { try? JSONDecoder().decode(MembershipSnapshot.self, from: $0) }
        if previous == nil, now.timeIntervalSince(answeredAt) > Self.freshBaselineAge { return }
        defer {
            if let data = try? JSONEncoder().encode(current) {
                defaults.set(data, forKey: snapshotKey)
            }
        }
        if MembershipTransitions.resetsAsk(from: previous, to: current) {
            defaults.removeObject(forKey: churnAskSpentKey)
            // They came back before Home asked: a queued "why are you
            // leaving?" is now false, so drop it.
            pendingChurnMoment = nil
            defaults.removeObject(forKey: pendingChurnKey)
        }
        guard pendingChurnMoment == nil, !defaults.bool(forKey: churnAskSpentKey) else { return }
        guard let moment = MembershipTransitions.churnMoment(from: previous, to: current) else { return }
        defaults.set(true, forKey: churnAskSpentKey)
        defaults.set(moment.rawValue, forKey: pendingChurnKey)
        pendingChurnMoment = moment
    }
}

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        receive(customerInfo)
    }

    @discardableResult
    nonisolated func receive(_ customerInfo: CustomerInfo) -> Task<Void, Never> {
        Task { @MainActor in self.apply(customerInfo) }
    }
}

#if DEBUG
/// Simulator-only proof path for the fleet-wide funnel attributes.
///
/// Under the normal rules the attributes cannot be verified on a simulator: the
/// production key must never be configured there, so RevenueCat is never
/// configured, so nothing is ever sent, so a physical device is the only
/// witness. The Test Store key is a different RevenueCat app inside the same
/// project, so a probe run cannot touch App Store customers, revenue or charts.
///
/// DEBUG only, and only with the launch argument, so it cannot reach a Release
/// build or an ordinary simulator run.
enum RevenueCatProbe {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-rcfunnelprobe")
    }

    static let testStoreKey = "test_ABxpPXHafCAWEHnmFYhGArpyRqX"

    static var appUserID: String {
        ProcessInfo.processInfo.environment["RC_PROBE_USER"] ?? "funnel-probe-bridge"
    }

    static var impressionID: String {
        ProcessInfo.processInfo.environment["RC_PROBE_SURFACE"] ?? "bridge_onboarding_trial"
    }

    /// Drives a Test Store purchase after the impression, so the `converted_*`
    /// half of the funnel record is exercised and not just the impression half.
    static var wantsPurchase: Bool {
        ProcessInfo.processInfo.arguments.contains("-rcfunnelprobepurchase")
    }
}
#endif
