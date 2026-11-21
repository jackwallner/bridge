import XCTest
@testable import Bridge

/// BR-02: Close on Fix My Mistakes before answering showed "0/8 right",
/// counted a drill and kept the streak alive.
final class PracticeRunScoringTests: XCTestCase {
    private let modes: [PracticeMode] = [.review, .timed, .endless(PracticeSkill.allCases[0])]

    func testRunClosedBeforeAnyAnswerIsNotACompletedDrill() {
        for mode in modes {
            XCTAssertNil(mode.completionTotal(attempted: 0), "\(mode)")
        }
    }

    func testRunClosedEarlyIsScoredOutOfWhatWasAnswered() {
        for mode in modes {
            XCTAssertEqual(mode.completionTotal(attempted: 3), 3, "\(mode)")
            XCTAssertEqual(mode.completionTotal(attempted: 8), 8, "\(mode)")
        }
    }

    /// The Timed Challenge ends at a wall-clock deadline, so time spent in
    /// another app or on a call counts against the 90 seconds.
    func testTimedChallengeClockFollowsTheWallClock() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let deadline = start.addingTimeInterval(TimeInterval(PracticeRunView.challengeSeconds))
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start), 90)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(0.4)), 90)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(50)), 40)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(89.5)), 1)
        // Away for ten minutes with 40 seconds on the clock: the run is over.
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(600)), 0)
    }
}
