// Kept outside the test target so the build stays green. To rerun, copy to
// BridgeTests/StateMachineAuditRepro.swift and run
// gh-sim test --scheme Bridge --only BridgeTests/StateMachineAuditRepro
// Results of run 42287448922 are in state-machines-2026-11-06.md.
import Combine
import Foundation
import UserNotifications
import XCTest

import RevenueCat

@testable import Bridge

/// State machine audit repro, 2026-11-06. Failing tests are expected: each one
/// asserts the behaviour the app promises and fails on today's code. Every
/// test asserts its own preconditions first (XCTAssert with "PRECONDITION"),
/// so a failure with that prefix means the setup broke, not the claim.
@MainActor
final class StateMachineAuditRepro: XCTestCase {

    private func freshDefaults(_ tag: String = #function) -> UserDefaults {
        let name = "audit.\(tag).\(UUID().uuidString)"
        return UserDefaults(suiteName: name)!
    }

    // MARK: - SM-B1 Flashcard undo restores the queue but not the practice record

    /// `FlashcardDrillView.choose` / `commit` call `PracticeRecordStore.record`
    /// once per answer (FlashcardDrillView.swift:237, :349). `undo()` (:363)
    /// only rewinds the on-screen queue. There is no store API to retract an
    /// answer, so the sequence the view produces for "wrong pick, Undo, right
    /// pick" is exactly the two `record` calls below.
    func testUndoThenRightAnswerLeavesOneAttemptAndNoDueMistake() throws {
        // Pick a real, free, self-test flashcard that Fix My Mistakes can replay.
        let card = try XCTUnwrap(
            DrillLibrary.rooms
                .filter { $0.isFree }
                .flatMap { room in room.drills.filter { !$0.isPlus }.map { (room, $0) } }
                .compactMap { room, drill -> (String, String)? in
                    guard case .flashcards(let cards) = drill.kind,
                          let c = cards.first(where: { $0.choice != nil }) else { return nil }
                    return (room.id, c.id)
                }
                .first(where: { SessionBuilder.reviewableItemIDs.contains($0.1) }),
            "PRECONDITION: a free choice flashcard that is reviewable"
        )
        let (roomID, itemID) = card
        let controlID = try XCTUnwrap(
            SessionBuilder.reviewableItemIDs.sorted().first(where: { $0 != itemID }),
            "PRECONDITION: a second reviewable id for the control"
        )

        let store = PracticeRecordStore(defaults: freshDefaults())
        XCTAssertTrue(store.records.isEmpty, "PRECONDITION: empty store")
        // Answered two days ago so any 1-day interval is already due today.
        let then = Date().addingTimeInterval(-2 * 86_400)

        // Control: a single right answer. Not a mistake, nothing due.
        store.record(itemID: controlID, roomID: roomID, correct: true, now: then)
        XCTAssertEqual(store.records[controlID]?.attempts, 1, "PRECONDITION: control is one attempt")
        XCTAssertFalse(store.records[controlID]?.needsReview ?? true, "CONTROL: one right answer is not a mistake")
        XCTAssertFalse(store.reviewQueue(limit: 50).contains(controlID), "CONTROL: not in Fix My Mistakes")

        // Scenario: wrong pick, tap Undo, right pick. The player's final answer is right.
        store.record(itemID: itemID, roomID: roomID, correct: false, now: then)   // choose(wrong)
        // undo(): no store call exists.
        store.record(itemID: itemID, roomID: roomID, correct: true, now: then)    // choose(right)

        let record = try XCTUnwrap(store.records[itemID])
        XCTAssertEqual(record.attempts, 1, "undone answer still counted: attempts=\(record.attempts) correct=\(record.correct) streak=\(record.streak)")
        XCTAssertFalse(record.needsReview, "undone wrong answer still makes the item a mistake: needsReview=\(record.needsReview)")
        XCTAssertFalse(store.reviewQueue(limit: 50).contains(itemID), "item is queued in Fix My Mistakes; dueCount=\(store.dueCount)")
    }

    // MARK: - SM-B2 Game night reminder is only cancelled on an observed isPro flip

    func testGameNightReminderIsOffWhenTheFirstRecordSaysNotAMember() async {
        let defaults = freshDefaults()
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.gameNightReminderEnabled, "PRECONDITION: reminder on from a previous membership")

        let mock = AuditPurchases()
        mock.info = auditInfo(active: false)
        let service = SubscriptionService(client: mock, defaults: freshDefaults(), ownsCurrentPurchase: { false })
        XCTAssertFalse(service.isPro, "PRECONDITION: starts not-pro")

        // Home's hook (HomeView.swift:141-148): SwiftUI onChange fires on a change
        // of value after the view appeared, never for the first value.
        var hookFires = 0
        let hook = service.$isPro.removeDuplicates().dropFirst().sink { isMember in
            hookFires += 1
            if !isMember, settings.gameNightReminderEnabled { settings.gameNightReminderEnabled = false }
        }
        defer { hook.cancel() }

        await service.receive(auditInfo(active: false)).value
        XCTAssertTrue(service.membershipResolved, "PRECONDITION: a record was read")
        XCTAssertFalse(service.isPro, "PRECONDITION: record says not a member")

        XCTAssertEqual(hookFires, 0, "hook never fired")
        XCTAssertFalse(settings.gameNightReminderEnabled, "weekly Game Night reminder still enabled for a non-member")
    }

    func testGameNightReminderIsOffAfterAnObservedLapse_control() async {
        let defaults = freshDefaults()
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: defaults)
        let mock = AuditPurchases()
        let service = SubscriptionService(client: mock, defaults: freshDefaults(), ownsCurrentPurchase: { false })
        var hookFires = 0
        let hook = service.$isPro.removeDuplicates().dropFirst().sink { isMember in
            hookFires += 1
            if !isMember, settings.gameNightReminderEnabled { settings.gameNightReminderEnabled = false }
        }
        defer { hook.cancel() }
        let now = Date()
        await service.receive(auditInfo(active: true, date: now.addingTimeInterval(-60))).value
        XCTAssertTrue(service.isPro, "PRECONDITION: member first")
        await service.receive(auditInfo(active: false, date: now)).value
        XCTAssertFalse(service.isPro)
        XCTAssertEqual(hookFires, 2)
        XCTAssertFalse(settings.gameNightReminderEnabled, "CONTROL: an observed lapse turns it off")
    }

    // MARK: - SM-B3 Nothing re-schedules a reminder the toggle says is on

    func testEnabledReminderTogglesAreBackedByPendingRequestsAfterLaunch() async throws {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let before = await center.pendingNotificationRequests()
        XCTAssertTrue(before.isEmpty, "PRECONDITION: nothing pending (state after a backup restore, or after iOS dropped them)")

        let defaults = freshDefaults()
        defaults.set(true, forKey: "settings.reminderEnabled")
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
        defaults.set(9, forKey: "settings.reminderHour")
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.reminderEnabled, "PRECONDITION: Settings shows Daily Reminder on")
        XCTAssertTrue(settings.gameNightReminderEnabled, "PRECONDITION: Game Night toggle shows on")

        // Control: the scheduler works in this environment. Changing the time
        // while the toggle is on goes through scheduleReminder().
        var control = DateComponents(); control.hour = 10; control.minute = 30
        settings.reminderTime = Calendar.current.date(from: control)!
        let afterControl = await center.pendingNotificationRequests()
        try XCTSkipUnless(afterControl.contains { $0.identifier == "bridge.dailyReminder" },
                          "INCONCLUSIVE: this simulator's center did not keep an unauthorised add (pending=\(afterControl.map(\.identifier))), so launch-time scheduling cannot be observed here")
        center.removeAllPendingNotificationRequests()

        // Claim: after a launch, an enabled toggle has a request behind it.
        let relaunched = AppSettings(defaults: defaults)
        XCTAssertTrue(relaunched.reminderEnabled && relaunched.gameNightReminderEnabled, "PRECONDITION: relaunched toggles on")
        try await Task.sleep(nanoseconds: 500_000_000)
        let pending = await center.pendingNotificationRequests().map(\.identifier).sorted()
        XCTAssertTrue(pending.contains("bridge.dailyReminder"), "daily reminder toggle on, pending=\(pending)")
        XCTAssertTrue(pending.contains("bridge.gameNightReminder"), "game night toggle on, pending=\(pending)")
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - SM-B4 Weekly gain counts items that only became visible by changing membership

    func testResubscribingDoesNotReportOldLockedInQuestionsAsThisWeeksGain() throws {
        let day: TimeInterval = 86_400
        let now = Date()
        let records = PracticeRecordStore(defaults: freshDefaults())
        let ledger = MasteryLedger(defaults: freshDefaults())

        // A Bridge+ extra set (locked for a free player).
        let locked = try XCTUnwrap(
            DrillLibrary.rooms.compactMap { room -> (Room, [String])? in
                let ids = room.drills
                    .filter { room.isLocked($0, isMember: false) }
                    .compactMap { drill -> [String]? in
                        if case .quiz(let q) = drill.kind { return q.map(\.id) }
                        return nil
                    }
                    .first
                return ids.map { (room, $0) }
            }.first,
            "PRECONDITION: a locked quiz set"
        )
        let (room, ids) = locked
        // Learned long ago (outside the 7-day window): three right answers, 8 days back.
        for id in ids.prefix(5) {
            for _ in 0..<3 { records.record(itemID: id, roomID: room.id, correct: true, now: now.addingTimeInterval(-8 * day)) }
        }
        let memberKnown = records.masteryByRoom(isMember: true, now: now).map(\.known).reduce(0, +)
        let freeKnown = records.masteryByRoom(isMember: false, now: now).map(\.known).reduce(0, +)
        XCTAssertGreaterThan(memberKnown, freeKnown, "PRECONDITION: Bridge+ items are known but hidden from a free player")
        XCTAssertTrue(records.records.values.allSatisfy { $0.lastAnswered < now.addingTimeInterval(-7 * day) },
                      "PRECONDITION: nothing answered in the last 7 days")

        // Control: same membership on both days, no practice, no gain.
        let controlLedger = MasteryLedger(defaults: freshDefaults())
        controlLedger.record(records.masteryByRoom(isMember: true, now: now), now: now.addingTimeInterval(-3 * day))
        controlLedger.record(records.masteryByRoom(isMember: true, now: now), now: now)
        XCTAssertNil(controlLedger.weeklyGain(now: now), "CONTROL: no practice, no gain")

        // Lapsed member opens Home as a free player 3 days ago, then re-subscribes.
        ledger.record(records.masteryByRoom(isMember: false, now: now), now: now.addingTimeInterval(-3 * day))
        ledger.record(records.masteryByRoom(isMember: true, now: now), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now), "chip would read +\(String(describing: ledger.weeklyGain(now: now))) questions locked in this week with no practice")
    }
}

// MARK: - Fixtures (copies of the shapes used in PaywallFunnelTests)

@MainActor
private final class AuditPurchases: RevenueCatClient {
    var cachedCustomerInfo: CustomerInfo?
    var info = auditInfo(active: false)
    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo { info }
    func paywallOffering(forceRefresh: Bool) async throws -> Offering? { nil }
    func purchase(package: Package) async throws -> PurchaseResultData { (nil, info, false) }
    func restorePurchases() async throws -> CustomerInfo { info }
    func introEligibility(productIdentifiers: [String]) async -> [String: IntroEligibilityStatus] { [:] }
    func syncPurchases() async throws -> CustomerInfo { info }
    func setSubscriberAttributes(_ attributes: [String: String]) {}
    func recordImpression(_ params: CustomPaywallImpressionParams) {}
}

@MainActor
private func auditInfo(active: Bool, date: Date = .now) -> CustomerInfo {
    let id = RevenueCatConfig.entitlement
    let entitlement = EntitlementInfo(
        identifier: id, isActive: active, willRenew: active,
        periodType: .normal, latestPurchaseDate: date, originalPurchaseDate: date,
        expirationDate: date.addingTimeInterval(active ? 86_400 : -86_400),
        store: .appStore, productIdentifier: "com.jackwallner.bridge.monthly",
        isSandbox: true, ownershipType: .purchased
    )
    return CustomerInfo(entitlements: EntitlementInfos(entitlements: [id: entitlement]),
                        requestDate: date, firstSeen: date, originalAppUserId: "audit-unit-test")
}
