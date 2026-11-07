import XCTest
@testable import Bridge

@MainActor
final class MasteryLedgerTests: XCTestCase {
    private var ledger: MasteryLedger!
    private let day: TimeInterval = 86_400

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "MasteryLedgerTests")!
        defaults.removePersistentDomain(forName: "MasteryLedgerTests")
        ledger = MasteryLedger(defaults: defaults)
    }

    private func mastery(_ known: [String: Int]) -> [RoomMastery] {
        known.map { RoomMastery(roomID: $0.key, known: $0.value, total: 40, level: .learning) }
    }

    func testNoGainWithoutABaselineDay() {
        let now = Date()
        ledger.record(mastery(["card-room": 5]), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now), "the first day has nothing to measure from")
    }

    func testGainIsMeasuredFromTheOldestDayInTheWindow() {
        let now = Date()
        ledger.record(mastery(["card-room": 5]), now: now.addingTimeInterval(-6 * day))
        ledger.record(mastery(["card-room": 9]), now: now.addingTimeInterval(-3 * day))
        ledger.record(mastery(["card-room": 12, "auction-room": 4]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 11)
        XCTAssertEqual(ledger.strongestRoom(now: now)?.roomID, "card-room")
        XCTAssertEqual(ledger.strongestRoom(now: now)?.gain, 7)
    }

    func testEntriesOlderThanTheWindowAreNotTheBaseline() {
        let now = Date()
        ledger.record(mastery(["card-room": 0]), now: now.addingTimeInterval(-30 * day))
        ledger.record(mastery(["card-room": 20]), now: now.addingTimeInterval(-2 * day))
        ledger.record(mastery(["card-room": 22]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 2)
    }

    func testBackwardsWeeksAreReportedAsNothing() {
        let now = Date()
        ledger.record(mastery(["card-room": 20]), now: now.addingTimeInterval(-4 * day))
        ledger.record(mastery(["card-room": 15]), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now))
    }

    func testSameDayRecordsOverwrite() {
        let now = Date()
        ledger.record(mastery(["card-room": 3]), now: now.addingTimeInterval(-1 * day))
        ledger.record(mastery(["card-room": 4]), now: now)
        ledger.record(mastery(["card-room": 8]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 5)
        XCTAssertEqual(ledger.days.count, 2)
    }

    func testPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: "MasteryLedgerTests")!
        let now = Date()
        ledger.record(mastery(["card-room": 3]), now: now.addingTimeInterval(-1 * day))
        ledger.record(mastery(["card-room": 9]), now: now)
        let reloaded = MasteryLedger(defaults: defaults)
        XCTAssertEqual(reloaded.weeklyGain(now: now), 6)
    }

    // MARK: - Membership scope (state machine audit SM-4)

    /// Each ledger day counts the questions the player could open that day,
    /// so re-subscribing within a week used to report old Bridge+ questions
    /// as "+N locked in this week" with no practice at all.
    func testResubscribingDoesNotReportOldLockedInQuestionsAsThisWeeksGain() throws {
        let now = Date()
        let suite = UserDefaults(suiteName: "MasteryLedgerTests.scope.\(UUID().uuidString)")!
        let records = PracticeRecordStore(defaults: suite)
        let scoped = MasteryLedger(defaults: suite)
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
        for id in ids.prefix(5) {
            for _ in 0..<3 { records.record(itemID: id, roomID: room.id, correct: true, now: now.addingTimeInterval(-8 * day)) }
        }
        let memberKnown = records.masteryByRoom(isMember: true, now: now).map(\.known).reduce(0, +)
        let freeKnown = records.masteryByRoom(isMember: false, now: now).map(\.known).reduce(0, +)
        XCTAssertGreaterThan(memberKnown, freeKnown, "PRECONDITION: Bridge+ items are known but hidden from a free player")

        // Lapsed member opens Home as a free player 3 days ago, then re-subscribes.
        scoped.record(records.masteryByRoom(isMember: false, now: now), isMember: false, now: now.addingTimeInterval(-3 * day))
        scoped.record(records.masteryByRoom(isMember: true, now: now), isMember: true, now: now)
        XCTAssertNil(scoped.weeklyGain(now: now), "no practice, but the chip reads +\(scoped.weeklyGain(now: now) ?? 0)")
        XCTAssertNil(scoped.strongestRoom(now: now))
    }

    func testAMemberDayEarlierInTheWindowStaysTheBaseline() {
        let now = Date()
        ledger.record(mastery(["card-room": 10, "plus-room": 5]), isMember: true, now: now.addingTimeInterval(-6 * day))
        ledger.record(mastery(["card-room": 11]), isMember: false, now: now.addingTimeInterval(-3 * day))
        ledger.record(mastery(["card-room": 12, "plus-room": 5]), isMember: true, now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 2)
    }

    func testAFreeWeekStillMeasuresAgainstFreeDays() {
        let now = Date()
        ledger.record(mastery(["card-room": 10, "plus-room": 5]), isMember: true, now: now.addingTimeInterval(-6 * day))
        ledger.record(mastery(["card-room": 11]), isMember: false, now: now.addingTimeInterval(-3 * day))
        ledger.record(mastery(["card-room": 14]), isMember: false, now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 3)
    }

    /// Ledgers saved before the scope existed keep measuring: an unscoped day
    /// compares with any day.
    func testALedgerSavedBeforeScopesStillMeasures() throws {
        let now = Date()
        let suite = UserDefaults(suiteName: "MasteryLedgerTests.legacy.\(UUID().uuidString)")!
        let legacy = [MasteryLedger.dayKey(now.addingTimeInterval(-4 * day)): ["card-room": 6]]
        suite.set(try JSONEncoder().encode(legacy), forKey: "mastery.ledger")
        let upgraded = MasteryLedger(defaults: suite)
        upgraded.record(mastery(["card-room": 9]), isMember: true, now: now)
        XCTAssertEqual(upgraded.weeklyGain(now: now), 3)
        XCTAssertEqual(MasteryLedger(defaults: suite).weeklyGain(now: now), 3, "scope lost on relaunch")
    }

    func testScopeSurvivesARelaunch() {
        let now = Date()
        let suite = UserDefaults(suiteName: "MasteryLedgerTests.relaunch.\(UUID().uuidString)")!
        let first = MasteryLedger(defaults: suite)
        first.record(mastery(["card-room": 4]), isMember: false, now: now.addingTimeInterval(-2 * day))
        first.record(mastery(["card-room": 9, "plus-room": 6]), isMember: true, now: now)
        XCTAssertNil(MasteryLedger(defaults: suite).weeklyGain(now: now))
    }
}
