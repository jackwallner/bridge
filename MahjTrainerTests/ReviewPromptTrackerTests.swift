import XCTest
@testable import MahjTrainer

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

    private func earnTheAsk() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordAppLaunch()
        for _ in 0..<ReviewPromptTracker.minimumPositiveMoments {
            ReviewPromptTracker.recordPositiveMoment()
        }
    }

    func testGateStaysShutUntilThePlayerHasDoneEnough() {
        ReviewPromptTracker.recordAppLaunch()
        ReviewPromptTracker.recordPositiveMoment()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment())

        earnTheAsk()
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment())
    }

    func testNotNowHoldsTheGateShutForTheCooldown() {
        earnTheAsk()
        ReviewPromptTracker.markShown()

        let day = TimeInterval(86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: Date().addingTimeInterval(30 * day)))
        let afterCooldown = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.cooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: afterCooldown))
    }

    /// "Maybe later" spends only Apple's silent prompt, so it must not cost us
    /// the full 120-day jail the way a flat "Not now" does.
    func testMaybeLaterUsesTheShortCooldown() {
        earnTheAsk()
        ReviewPromptTracker.markSoftDeferred()

        let day = TimeInterval(86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: Date().addingTimeInterval(10 * day)))
        let afterSoftCooldown = Date().addingTimeInterval(TimeInterval(ReviewPromptTracker.softDeferCooldownDays + 1) * day)
        XCTAssertTrue(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: afterSoftCooldown))
    }

    func testRatingOrFeedbackRetiresThePromptForGood() {
        earnTheAsk()
        ReviewPromptTracker.markOpenedWriteReview()

        let inTenYears = Date().addingTimeInterval(3650 * 86_400)
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: inTenYears))
        XCTAssertEqual(ReviewPromptTracker.outcome, .openedWriteReview)

        ReviewPromptTracker.resetForTesting()
        earnTheAsk()
        ReviewPromptTracker.markFeedbackSubmitted()
        XCTAssertFalse(ReviewPromptTracker.shouldShowAfterPositiveMoment(now: inTenYears))
        XCTAssertEqual(ReviewPromptTracker.outcome, .submittedFeedback)
    }

    func testFeedbackMailURLCarriesTheMessage() {
        let url = ReviewPromptSheet.feedbackMailURL(body: "more charleston drills please")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.path, AppStoreLinks.feedbackEmail)
        XCTAssertTrue(url?.query?.contains("more%20charleston%20drills%20please") == true)
    }
}
