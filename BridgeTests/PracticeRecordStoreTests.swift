import XCTest
@testable import Bridge

@MainActor
final class PracticeRecordStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: PracticeRecordStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "PracticeRecordStoreTests")!
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        store = PracticeRecordStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        super.tearDown()
    }

    private let room = "card-room"

    func testRecordsAccuracy() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.record(itemID: "q1", roomID: room, correct: false)
        let record = store.records["q1"]
        XCTAssertEqual(record?.attempts, 2)
        XCTAssertEqual(record?.correct, 1)
        XCTAssertEqual(record?.accuracy, 0.5)
    }

    /// A missed item goes into the queue; two clean answers retire it. Without
    /// the second condition an item would either nag forever or vanish on the
    /// first lucky guess.
    func testMissedItemEntersAndLeavesTheQueue() {
        store.record(itemID: "q1", roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue(), ["q1"])

        store.record(itemID: "q1", roomID: room, correct: true)
        XCTAssertEqual(store.reviewQueue(), [], "One correct answer schedules it a day out")

        store.record(itemID: "q1", roomID: room, correct: true)
        XCTAssertFalse(store.records["q1"]!.needsReview, "Two in a row retires it")
    }

    func testQueueRanksWorstFirst() {
        // q1: 1 of 3. q2: 2 of 3. Both due, q1 should lead.
        for correct in [false, false, false] {
            store.record(itemID: "q1", roomID: room, correct: correct)
        }
        store.record(itemID: "q2", roomID: room, correct: true)
        store.record(itemID: "q2", roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue().first, "q1")
    }

    /// Generated items mint a new id per question. They must roll up onto one
    /// per-skill row and must never enter the review queue, or the queue would
    /// fill with questions that can never be shown again.
    func testGeneratedItemsCollapseAndStayOutOfTheQueue() {
        let prefix = PracticeSkill.openings.itemPrefix
        store.record(itemID: prefix + "a", roomID: room, correct: false)
        store.record(itemID: prefix + "b", roomID: room, correct: true)

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records[PracticeSkill.openings.rawValue]?.attempts, 2)
        XCTAssertTrue(store.reviewQueue().isEmpty)
        XCTAssertEqual(store.dueCount, 0)
    }

    func testRoomStatsAggregate() {
        store.record(itemID: "q1", roomID: "card-room", correct: true)
        store.record(itemID: "q2", roomID: "card-room", correct: false)
        store.record(itemID: "q3", roomID: "auction-room", correct: true)

        let stats = store.roomStats()
        XCTAssertEqual(stats.count, 2)
        let cardRoom = stats.first { $0.id == "card-room" }
        XCTAssertEqual(cardRoom?.attempts, 2)
        XCTAssertEqual(cardRoom?.accuracy, 0.5)
        XCTAssertEqual(store.overallAccuracy, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testChallengeScoreKeepsTheBest() {
        store.recordChallengeScore(12)
        store.recordChallengeScore(7)
        XCTAssertEqual(store.bestChallengeScore, 12)
    }

    func testPersistsAcrossInstances() {
        store.record(itemID: "q1", roomID: room, correct: true)
        let reloaded = PracticeRecordStore(defaults: defaults)
        XCTAssertEqual(reloaded.records["q1"]?.attempts, 1)
    }

    func testResetClearsEverything() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.recordChallengeScore(9)
        store.resetAll()
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(store.bestChallengeScore, 0)
        XCTAssertTrue(PracticeRecordStore(defaults: defaults).records.isEmpty)
    }
}

final class WhatsNewTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WhatsNewTests")!
        defaults.removePersistentDomain(forName: "WhatsNewTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "WhatsNewTests")
        super.tearDown()
    }

    func testNeverShownBeforeOnboarding() {
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: false, defaults: defaults))
    }

    /// A player updating from a build that predates the feature has no stored
    /// marker at all. That is exactly who the sheet is for.
    func testShownToAnUpgraderWithNoMarker() {
        XCTAssertTrue(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    func testShownOnlyOnce() {
        WhatsNew.markSeen(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    func testFreshInstallBaselineSuppressesIt() {
        WhatsNew.markCurrentAsBaseline(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    func testReleaseNotesAreWellFormed() {
        let release = try! XCTUnwrap(WhatsNew.currentRelease)
        XCTAssertEqual(release.version, WhatsNew.currentVersion)
        XCTAssertFalse(release.items.isEmpty)
        XCTAssertEqual(Set(release.items.map(\.id)).count, release.items.count)
        for item in release.items {
            XCTAssertFalse(item.title.isEmpty)
            XCTAssertFalse(item.body.isEmpty)
            XCTAssertFalse(item.body.contains("—"), "No em dashes in copy")
        }
    }
}
