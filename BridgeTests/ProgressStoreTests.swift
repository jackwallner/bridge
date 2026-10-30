import XCTest
@testable import Bridge

@MainActor
final class ProgressStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: ProgressStore!
    private let originalTimeZone = NSTimeZone.default

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "ProgressStoreTests")
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        store = ProgressStore(defaults: defaults)
    }

    override func tearDown() {
        NSTimeZone.default = originalTimeZone
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        super.tearDown()
    }

    func testRecordSessionIncrementsCounts() {
        store.recordSession(drillID: "meet-cards")
        store.recordSession(drillID: "meet-cards")
        XCTAssertEqual(store.completions(for: "meet-cards"), 2)
        XCTAssertEqual(store.totalSessions, 2)
    }

    /// The tour's closing practice is recorded before onboarding ends, so
    /// Home's extras wait for a practice the player starts after it.
    func testTourPracticeDoesNotCountTowardHomeExtras() {
        XCTAssertFalse(store.hasPracticedSinceOnboarding)
        store.recordSession(drillID: "quick-session")
        store.sessionsAtOnboarding = store.totalSessions
        XCTAssertFalse(store.hasPracticedSinceOnboarding)
        store.recordSession(drillID: "meet-cards")
        XCTAssertTrue(store.hasPracticedSinceOnboarding)
    }

    /// Players who onboarded before 1.2.5 have no stored mark, so any
    /// finished practice counts, as before.
    func testUpgradersCountEveryPractice() {
        store.recordSession(drillID: "meet-cards")
        XCTAssertTrue(store.hasPracticedSinceOnboarding)
    }

    func testStreakStartsAtOne() {
        store.recordSession(drillID: "a")
        XCTAssertEqual(store.streakCount, 1)
    }

    func testSameDaySessionsKeepStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "b", now: day1.addingTimeInterval(3600))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testConsecutiveDaysGrowStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.streakCount, 2)
    }

    func testGapResetsStreakToOne() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400 * 3))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testCurrentStreakHoldsThroughTheNextDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.currentStreak(now: day1.addingTimeInterval(86_400 * 2)), 2)
    }

    func testCurrentStreakDropsToZeroAfterAMissedDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.currentStreak(now: day1.addingTimeInterval(86_400 * 5)), 0)
    }

    func testClockGoingBackwardsDoesNotRewindTheLastDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.streakCount, 2, "Returning to the real date must not count the same day twice")
    }

    private func iso(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    /// BR-03: the last day was stored as an instant (New York midnight), which
    /// is the evening before in Chicago, so a westward trip read as a missed day.
    func testWestwardTravelKeepsTheStreak() {
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        store.recordSession(drillID: "a", now: iso("2026-10-28T20:00:00-04:00"))
        store.recordSession(drillID: "a", now: iso("2026-10-29T20:00:00-04:00"))
        NSTimeZone.default = TimeZone(identifier: "America/Chicago")!
        let friday = iso("2026-10-30T09:00:00-05:00")
        XCTAssertEqual(store.currentStreak(now: friday), 2)
        store.recordSession(drillID: "a", now: friday)
        XCTAssertEqual(store.streakCount, 3)
    }

    func testWestwardTravelDoesNotCountTheSameDayTwice() {
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        store.recordSession(drillID: "a", now: iso("2026-10-29T09:00:00-04:00"))
        NSTimeZone.default = TimeZone(identifier: "America/Los_Angeles")!
        store.recordSession(drillID: "a", now: iso("2026-10-29T20:00:00-07:00"))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testWestwardTravelKeepsGetStartedDoneForTheDay() {
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        store.markQuickSessionCompleted(now: iso("2026-10-29T09:00:00-04:00"))
        NSTimeZone.default = TimeZone(identifier: "America/Los_Angeles")!
        XCTAssertTrue(store.quickSessionCompletedToday(now: iso("2026-10-29T20:00:00-07:00")))
    }

    /// Builds before the fix stored an instant; it must still read.
    func testLegacyStoredInstantStillReads() {
        defaults.set(Calendar.current.startOfDay(for: Date().addingTimeInterval(-86_400)), forKey: "progress.lastActiveDay")
        defaults.set(4, forKey: "progress.streakCount")
        store = ProgressStore(defaults: defaults)
        XCTAssertEqual(store.currentStreak(), 4)
        store.recordSession(drillID: "a")
        XCTAssertEqual(store.streakCount, 5)
    }

    func testRoomProgress() {
        guard let room = DrillLibrary.rooms.first else { return XCTFail("no rooms") }
        XCTAssertEqual(store.roomProgress(room), 0)
        store.recordSession(drillID: room.drills[0].id)
        XCTAssertEqual(store.roomProgress(room), 1 / Double(room.drills.count), accuracy: 0.001)
    }

    func testRecordItemTracksSeenAndMissed() {
        store.recordItem(id: "q1", correct: false)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertTrue(store.missedItems.contains("q1"))
        store.recordItem(id: "q1", correct: true)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertFalse(store.missedItems.contains("q1"), "A correct answer clears the miss")
    }

    func testItemTrackingPersists() {
        store.recordItem(id: "q1", correct: false)
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertTrue(reloaded.seenItems.contains("q1"))
        XCTAssertTrue(reloaded.missedItems.contains("q1"))
    }

    func testResetAllClearsEverythingButOnboarding() {
        store.hasOnboarded = true
        store.recordSession(drillID: "a")
        store.recordItem(id: "q1", correct: false)
        store.resetAll()
        XCTAssertEqual(store.streakCount, 0)
        XCTAssertEqual(store.totalSessions, 0)
        XCTAssertEqual(store.completions(for: "a"), 0)
        XCTAssertTrue(store.seenItems.isEmpty)
        XCTAssertTrue(store.missedItems.isEmpty)
        XCTAssertTrue(store.hasOnboarded, "Reset must not re-trigger onboarding")
    }

    // Rating-ask rules live in ReviewPromptTracker; see ReviewPromptTrackerTests.
}
