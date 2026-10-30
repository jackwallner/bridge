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
}
