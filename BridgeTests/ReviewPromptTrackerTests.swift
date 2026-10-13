import XCTest
@testable import Bridge

/// The rating-ask rules from the fleet policy: ask from the second launch,
/// wait out a 30-day cooldown, stop only when the player opened the review
/// page, and never let feedback stop the asks.
@MainActor
final class ReviewPromptTrackerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ReviewPromptTracker.resetForTesting()
    }

    override func tearDown() {
        ReviewPromptTracker.resetForTesting()
        super.tearDown()
    }

    private func days(_ n: Double) -> Date { Date().addingTimeInterval(n * 86_400) }

    private func launch(_ times: Int) {
        for _ in 0..<times { ReviewPromptTracker.recordAppLaunch() }
    }

    func testNeverAsksInTheFirstSession() {
        launch(1)
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
    }

    func testAsksAtTheFirstPositiveMomentOfTheSecondLaunch() {
        launch(2)
        XCTAssertFalse(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true),
                       "No moment yet, so no ask")
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertTrue(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
    }

    func testRequiresFinishedOnboarding() {
        launch(2)
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: false))
    }

    func testWaitsOutTheCooldown() {
        launch(2)
        ReviewPromptTracker.markShown()
        XCTAssertFalse(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(29)))
        XCTAssertTrue(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(31)))
    }

    func testOpeningTheReviewPageEndsTheAsks() {
        launch(2)
        ReviewPromptTracker.markOpenedWriteReview()
        XCTAssertFalse(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(3650)))
    }

    func testFeedbackDoesNotStopTheAsks() {
        launch(2)
        ReviewPromptTracker.markFeedbackSubmitted()
        XCTAssertEqual(ReviewPromptTracker.outcome, .submittedFeedback)
        XCTAssertTrue(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(31)))
    }

    func testFeedbackAfterTheReviewPageKeepsTheAsksEnded() {
        launch(2)
        ReviewPromptTracker.markOpenedWriteReview()
        ReviewPromptTracker.markFeedbackSubmitted()
        XCTAssertEqual(ReviewPromptTracker.outcome, .openedWriteReview)
        XCTAssertFalse(ReviewPromptTracker.canRequestReview(hasCompletedSetup: true, now: days(3650)))
    }

    func testBlockedAskKeepsTheMomentPending() {
        launch(2)
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertTrue(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
        // The screen was busy, so nothing was marked: the moment is still there.
        XCTAssertTrue(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
        ReviewPromptTracker.markShown()
        XCTAssertFalse(ReviewPromptTracker.shouldRequestAfterPositiveMoment(hasCompletedSetup: true))
    }

    func testFeedbackMailURLCarriesTheMessage() {
        let url = FeedbackSheet.feedbackMailURL(body: "more play drills please")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.path, AppStoreLinks.feedbackEmail)
        XCTAssertTrue(url?.query?.contains("more%20play%20drills%20please") == true)
    }
}
