import StoreKit
import StoreKitTest
import XCTest
@testable import Bridge

/// The trial page and paywall only promise a free week when StoreKit says this
/// Apple Account still has one. Runs against the app's StoreKit fixture, so no
/// RevenueCat, no sandbox account and no real purchase.
///
/// The lapsed half (buy with the free week, let it expire, expect false) is not
/// here: `Product.purchase` waits forever on a headless CI runner. It was
/// checked in Mahj, whose test is the same shape.
final class TrialEligibilityTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Bridge/Bridge.storekit")
        session = try SKTestSession(contentsOf: fixture)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    override func tearDown() {
        session?.clearTransactions()
        session = nil
        super.tearDown()
    }

    private func product(_ id: String) async throws -> Product {
        let products = try await Product.products(for: [id])
        return try XCTUnwrap(products.first, "\(id) missing from the fixture")
    }

    /// Both subscriptions carry the one-week intro offer, and a new account
    /// has not used it.
    func testNewAccountGetsTheFreeWeek() async throws {
        for id in ["com.jackwallner.bridge.monthly", "com.jackwallner.bridge.yearly"] {
            let item = try await product(id)
            XCTAssertNotNil(item.subscription?.introductoryOffer, "\(id) lost its free week")
            let eligible = await SubscriptionService.isTrialEligible(item)
            XCTAssertTrue(eligible, "a new account gets the free week on \(id)")
        }
    }

    /// Lifetime is not a subscription: it never carries trial copy, so it reads
    /// as eligible rather than hiding anything.
    func testLifetimeIsNotGatedByTheFreeWeek() async throws {
        let lifetime = try await product("com.jackwallner.bridge.lifetime")
        let eligible = await SubscriptionService.isTrialEligible(lifetime)
        XCTAssertTrue(eligible)
    }

    /// Unknown products cannot establish eligibility or promise a free week.
    func testUnknownProductDoesNotPromiseAFreeWeek() async {
        let eligible = await SubscriptionService.isTrialEligible(nil)
        XCTAssertFalse(eligible)
    }
}
