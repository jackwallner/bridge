import Combine
import Foundation
import XCTest

import RevenueCat

@testable import Bridge

/// The weekly Game Night reminder belongs to Bridge+. A member who lapses
/// while away for more than three days launches with a cached record that
/// RevenueCat already judges as lapsed, so `isPro` never changes and an
/// edge-triggered "turn it off on a lapse" never runs. These drive
/// `SubscriptionService.start()` and the app's level-triggered rule.
@MainActor
final class GameNightMembershipTests: XCTestCase {
    private let day: TimeInterval = 86_400

    private func defaults(_ tag: String = #function) -> UserDefaults {
        UserDefaults(suiteName: "GameNightMembershipTests.\(tag).\(UUID().uuidString)")!
    }

    private func settingsWithGameNightOn() -> AppSettings {
        let store = defaults()
        store.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: store)
        XCTAssertTrue(settings.gameNightReminderEnabled, "PRECONDITION: reminder on from the membership")
        return settings
    }

    /// Wires the rule exactly as BridgeApp does and starts the service.
    private func launch(_ service: SubscriptionService, settings: AppSettings) -> AnyCancellable {
        let hook = service.$membershipConfirmed.removeDuplicates().dropFirst().sink { confirmed in
            guard confirmed else { return }
            settings.enforceGameNightMembership(isMember: service.isPro)
        }
        service.start()
        return hook
    }

    private func waitForConfirmation(_ service: SubscriptionService) async {
        for _ in 0..<50 where !service.membershipConfirmed {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    func testLapsedMembersStaleRecordTurnsTheReminderOffWithoutAnIsProChange() async {
        let settings = settingsWithGameNightOn()
        let client = GameNightPurchases()
        client.cachedCustomerInfo = gameNightInfo(active: false, date: Date().addingTimeInterval(-5 * day))
        client.info = gameNightInfo(active: false, date: Date())
        let service = SubscriptionService(client: client, defaults: defaults(), ownsCurrentPurchase: { false })
        var timeline: [Bool] = []
        let watch = service.$isPro.sink { timeline.append($0) }
        defer { watch.cancel() }

        let hook = launch(service, settings: settings)
        defer { hook.cancel() }
        await waitForConfirmation(service)

        XCTAssertFalse(timeline.contains(true), "PRECONDITION: isPro never true, so no onChange(of: isPro) can fire")
        XCTAssertTrue(service.membershipConfirmed, "membership answer never confirmed")
        XCTAssertFalse(settings.gameNightReminderEnabled, "weekly Game Night reminder still on for a non-member")
    }

    func testMemberWhoseCacheReadsLapsedKeepsTheReminderOnceTheServerAnswers() async {
        let settings = settingsWithGameNightOn()
        let client = GameNightPurchases()
        client.cachedCustomerInfo = gameNightInfo(active: false, date: Date().addingTimeInterval(-5 * day))
        client.info = gameNightInfo(active: true, date: Date())
        let service = SubscriptionService(client: client, defaults: defaults(), ownsCurrentPurchase: { false })

        let hook = launch(service, settings: settings)
        defer { hook.cancel() }
        await waitForConfirmation(service)

        XCTAssertTrue(service.membershipConfirmed)
        XCTAssertTrue(service.isPro)
        XCTAssertTrue(settings.gameNightReminderEnabled, "a renewed member lost the reminder to a stale cache")
    }

    func testReinstalledMemberKeepsTheReminderUntilTheSyncAnswers() async {
        let settings = settingsWithGameNightOn()
        let client = GameNightPurchases()
        client.info = gameNightInfo(active: false, date: Date())
        client.synced = gameNightInfo(active: true, date: Date().addingTimeInterval(1))
        let service = SubscriptionService(client: client, defaults: defaults(), ownsCurrentPurchase: { true })

        let hook = launch(service, settings: settings)
        defer { hook.cancel() }
        await waitForConfirmation(service)

        XCTAssertTrue(service.membershipConfirmed)
        XCTAssertTrue(service.isPro, "PRECONDITION: the sync found the membership")
        XCTAssertTrue(settings.gameNightReminderEnabled, "a reinstalled member lost the reminder before the sync answered")
    }

    func testReinstalledMemberKeepsTheReminderWhenTheSyncFails() async throws {
        let settings = settingsWithGameNightOn()
        let client = GameNightPurchases()
        client.info = gameNightInfo(active: false, date: Date())
        client.syncError = URLError(.timedOut)
        let service = SubscriptionService(client: client, defaults: defaults(), ownsCurrentPurchase: { true })

        let hook = launch(service, settings: settings)
        defer { hook.cancel() }
        try await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertTrue(service.membershipResolved, "PRECONDITION: RevenueCat answered")
        XCTAssertFalse(service.membershipConfirmed, "a failed reinstall sync counted as confirmed")
        XCTAssertTrue(settings.gameNightReminderEnabled, "a member lost the reminder to a failed sync")
    }

    func testOfflineLaunchOnAStaleCacheLeavesTheReminderAlone() async throws {
        let settings = settingsWithGameNightOn()
        let client = GameNightPurchases()
        client.cachedCustomerInfo = gameNightInfo(active: false, date: Date().addingTimeInterval(-5 * day))
        client.fetchError = URLError(.notConnectedToInternet)
        let service = SubscriptionService(client: client, defaults: defaults(), ownsCurrentPurchase: { false })

        let hook = launch(service, settings: settings)
        defer { hook.cancel() }
        try await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertTrue(service.membershipResolved, "PRECONDITION: the cache was read")
        XCTAssertFalse(service.membershipConfirmed, "a cache-only answer counted as confirmed")
        XCTAssertTrue(settings.gameNightReminderEnabled)
    }
}

/// Honours the fetch policy as RevenueCat 5.80.3 does
/// (`CustomerInfoManager.swift:157-176`): `.cachedOrFetched` returns any
/// cached record, stale or not, without waiting for the network, and
/// `.notStaleCachedOrFetched` refetches a stale one. A network answer or a
/// sync replaces the cache.
@MainActor
private final class GameNightPurchases: RevenueCatClient {
    var cachedCustomerInfo: CustomerInfo?
    var info = gameNightInfo(active: false, date: .now)
    var synced: CustomerInfo?
    var fetchError: Error?
    var syncError: Error?

    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo {
        let cacheIsFresh = cachedCustomerInfo.map {
            Date().timeIntervalSince($0.requestDate) < SubscriptionService.freshBaselineAge
        } ?? false
        switch fetchPolicy {
        case .fromCacheOnly:
            if let cachedCustomerInfo { return cachedCustomerInfo }
            throw URLError(.resourceUnavailable)
        case .cachedOrFetched:
            if let cachedCustomerInfo { return cachedCustomerInfo }
        case .notStaleCachedOrFetched:
            if cacheIsFresh, let cachedCustomerInfo { return cachedCustomerInfo }
        case .fetchCurrent:
            break
        @unknown default:
            break
        }
        if let fetchError { throw fetchError }
        cachedCustomerInfo = info
        return info
    }
    func paywallOffering(forceRefresh: Bool) async throws -> Offering? { nil }
    func purchase(package: Package) async throws -> PurchaseResultData { (nil, info, false) }
    func restorePurchases() async throws -> CustomerInfo { info }
    func introEligibility(productIdentifiers: [String]) async -> [String: IntroEligibilityStatus] { [:] }
    func syncPurchases() async throws -> CustomerInfo {
        if let syncError { throw syncError }
        let result = synced ?? info
        cachedCustomerInfo = result
        return result
    }
    func setSubscriberAttributes(_ attributes: [String: String]) {}
    func recordImpression(_ params: CustomPaywallImpressionParams) {}
}

@MainActor
private func gameNightInfo(active: Bool, date: Date) -> CustomerInfo {
    let id = RevenueCatConfig.entitlement
    let entitlement = EntitlementInfo(
        identifier: id, isActive: active, willRenew: active,
        periodType: .normal, latestPurchaseDate: date, originalPurchaseDate: date,
        expirationDate: date.addingTimeInterval(active ? 30 * 86_400 : -86_400),
        store: .appStore, productIdentifier: "com.jackwallner.bridge.monthly",
        isSandbox: true, ownershipType: .purchased
    )
    return CustomerInfo(entitlements: EntitlementInfos(entitlements: [id: entitlement]),
                        requestDate: date, firstSeen: date, originalAppUserId: "game-night-unit-test")
}
