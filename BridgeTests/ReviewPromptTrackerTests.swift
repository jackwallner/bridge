import XCTest
@testable import Bridge

@MainActor
final class ReviewPromptTrackerTests: XCTestCase {
    private let day = TimeInterval(86_400)

    override func setUp() {
        super.setUp()
        ReviewPromptTracker.resetForTesting()
    }

    override func tearDown() {
        ReviewPromptTracker.resetForTesting()
        super.tearDown()
    }

    func testNeverAsksInTheFirstSession() {
        ReviewPromptTracker.recordAppLaunch()
        XCTAssertFalse(ReviewPromptTracker.shouldRequestReview())
        ReviewPromptTracker.recordAppLaunch()
        XCTAssertTrue(ReviewPromptTracker.shouldRequestReview(), "the second launch is the only tenure gate")
    }

    func testCallingThePromptStartsTheThirtyDayCooldown() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.markShown()
        XCTAssertFalse(ReviewPromptTracker.shouldRequestReview())
        XCTAssertFalse(ReviewPromptTracker.shouldRequestReview(now: Date().addingTimeInterval(29 * day)))
        let after = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.cooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldRequestReview(now: after))
    }

    func testOpeningTheWriteReviewPageEndsTheAsks() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.markOpenedWriteReview()
        XCTAssertFalse(ReviewPromptTracker.shouldRequestReview(now: Date().addingTimeInterval(3650 * day)))
    }

    /// Feedback is never the "no" branch of a rating question: someone who
    /// wrote in can still rate later. Installs that saved the old funnel's
    /// outcome must be asked again too.
    func testSentFeedbackDoesNotStopTheAsks() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.outcome = .submittedFeedback
        XCTAssertTrue(ReviewPromptTracker.shouldRequestReview())
    }
}
