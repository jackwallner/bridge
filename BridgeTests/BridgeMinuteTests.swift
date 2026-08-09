import XCTest
@testable import Bridge

final class BridgeMinuteContentTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testChallengeIsStableAndSharedForACalendarDay() {
        let day = date(2026, 8, 9)
        let first = BridgeMinuteContent.challenge(for: day, calendar: calendar)
        let second = BridgeMinuteContent.challenge(for: day, calendar: calendar)

        XCTAssertEqual(first.dayKey, "2026-08-09")
        XCTAssertEqual(first.items.map(\.id), second.items.map(\.id))
        XCTAssertEqual(first.items.map(\.choices), second.items.map(\.choices))
        XCTAssertEqual(first.items.map(\.cards), second.items.map(\.cards))
    }

    func testChallengeHasThePromisedFiveQuestionMix() {
        let challenge = BridgeMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)
        let categories = Dictionary(grouping: challenge.questions, by: \.category).mapValues(\.count)

        XCTAssertEqual(challenge.questions.count, 5)
        XCTAssertEqual(categories[.bidding], 2)
        XCTAssertEqual(categories[.declarerPlay], 1)
        XCTAssertEqual(categories[.defense], 2)
    }

    /// The day seed is fixed, so a day that fails to deal fails identically for
    /// every member on that date. Sweep several years of real day keys rather
    /// than trusting a single sampled day: `challenge` indexes into the dealt
    /// hands, and a short batch would crash everyone at once.
    func testEveryDaySeedDealsTheFullQuestionSet() {
        var day = date(2026, 1, 1)
        var checked = 0
        while day < date(2031, 1, 1) {
            let key = BridgeMinuteContent.key(for: day, calendar: calendar)
            let hands = HandGenerator.batch(count: 2, seed: "bridge-minute-\(key)-hands")
            XCTAssertEqual(hands.count, 2, "\(key) dealt \(hands.count) hands")
            checked += 1
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertGreaterThan(checked, 1800)
    }

    func testEveryDailyQuestionIsLegalAndGradeable() {
        let challenge = BridgeMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)

        for question in challenge.questions {
            let item = question.item
            if question.category == .bidding {
                XCTAssertEqual(item.cards.count, 13, "\(item.id) must show a 13-card hand")
            }
            XCTAssertGreaterThanOrEqual(item.choices.count, 2)
            XCTAssertTrue(item.choices.indices.contains(item.answerIndex), "\(item.id) answer out of range")
            XCTAssertFalse(item.explanation.isEmpty, "\(item.id) has no coaching line")
            XCTAssertFalse(item.explanation.contains("\u{2014}"), "\(item.id) contains an em dash")
        }
    }

    /// Generated daily prompts are one-offs: a unique id per question. If they
    /// entered the review queue it would grow without bound with items that can
    /// never be shown again.
    func testGeneratedDailyItemsAreNotReviewable() {
        let challenge = BridgeMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)
        let generated = challenge.questions.filter { $0.category == .bidding }

        XCTAssertFalse(generated.isEmpty)
        for question in generated {
            XCTAssertFalse(question.item.isReviewable)
            XCTAssertEqual(question.item.trackingID, PracticeSkill.openings.rawValue)
        }
    }

    @MainActor
    func testResultScoringAndShareTextMatchTheAnswers() {
        let store = BridgeMinuteStore(defaults: UserDefaults(suiteName: "bridge.minute.tests")!)
        store.resetAll()
        let challenge = BridgeMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)
        let answers = [true, false, true, true, false]

        let result = store.record(challenge: challenge, answers: answers)

        XCTAssertEqual(result.score, 3)
        XCTAssertEqual(result.total, 5)
        XCTAssertTrue(result.shareText.contains("3/5"))
        // Recording the same day twice must not double count it.
        XCTAssertEqual(store.record(challenge: challenge, answers: [true, true, true, true, true]).score, 3)
        store.resetAll()
    }
}
