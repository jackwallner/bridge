import XCTest
@testable import Bridge

final class ContentValidityTests: XCTestCase {
    private var allDrills: [Drill] { DrillLibrary.rooms.flatMap(\.drills) }

    private var allHandMatch: [HandMatchQuestion] {
        allDrills.flatMap { drill in
            if case .handMatch(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allQuiz: [QuizQuestion] {
        allDrills.flatMap { drill in
            if case .quiz(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allPlay: [PlayScenario] {
        allDrills.flatMap { drill in
            if case .play(let scenarios) = drill.kind { return scenarios }
            return []
        }
    }

    private var allFlashcards: [Flashcard] {
        allDrills.flatMap { drill in
            if case .flashcards(let cards) = drill.kind { return cards }
            return []
        }
    }

    func testOpeningHandsAreLegalThirteenCardHands() {
        for question in allHandMatch {
            XCTAssertEqual(question.cards.count, 13, "\(question.id) must contain 13 cards")
            XCTAssertEqual(Set(question.cards).count, 13, "\(question.id) contains a duplicate physical card")
            XCTAssertTrue(question.choices.contains(question.answer), "\(question.id) answer missing from choices")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "\(question.id) has duplicate choices")
        }
    }

    func testQuestionAnswersAreInRange() {
        for question in allQuiz {
            XCTAssertGreaterThanOrEqual(question.choices.count, 2, "\(question.id) needs choices")
            XCTAssertTrue(question.choices.indices.contains(question.answerIndex), "\(question.id) answer is out of range")
        }
        for scenario in allPlay {
            XCTAssertFalse(scenario.cards.isEmpty, "\(scenario.id) needs playable cards")
            XCTAssertTrue(scenario.cards.indices.contains(scenario.answerIndex), "\(scenario.id) answer is out of range")
            XCTAssertEqual(Set(scenario.cards).count, scenario.cards.count, "\(scenario.id) contains duplicate choices")
        }
        for card in allFlashcards {
            guard let choice = card.choice else { continue }
            XCTAssertEqual(choice.options.count, 2, "\(card.id) must have two choices")
            XCTAssertTrue(choice.options.indices.contains(choice.answerIndex), "\(card.id) answer is out of range")
        }
    }

    func testAllContentIDsAreUnique() {
        var ids: [String] = []
        for room in DrillLibrary.rooms {
            ids.append(room.id)
            for drill in room.drills {
                ids.append(drill.id)
                switch drill.kind {
                case .flashcards(let cards): ids += cards.map(\.id)
                case .quiz(let questions): ids += questions.map(\.id)
                case .handMatch(let questions): ids += questions.map(\.id)
                case .play(let scenarios): ids += scenarios.map(\.id)
                }
            }
        }
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate content IDs found")
    }

    func testRoomMembershipModel() {
        XCTAssertEqual(DrillLibrary.rooms.count, 5)
        XCTAssertEqual(DrillLibrary.rooms.filter(\.isFree).count, 4)
        XCTAssertEqual(DrillLibrary.rooms.last?.id, "master-tables")
        XCTAssertFalse(DrillLibrary.rooms.last?.isFree ?? true)

        for room in DrillLibrary.rooms where room.isFree {
            XCTAssertFalse(room.drills.filter { !$0.isPlus }.isEmpty)
            XCTAssertEqual(room.drills.filter(\.isPlus).count, 1)
        }
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                XCTAssertGreaterThan(drill.kind.itemCount, 0)
                XCTAssertFalse(room.isLocked(drill, isMember: true))
                XCTAssertEqual(room.isLocked(drill, isMember: false), !room.isFree || drill.isPlus)
            }
        }
    }

    // MARK: - Independent recounts

    private static let numberWords: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
        "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
        "nineteen": 19, "twenty": 20, "twenty-one": 21
    ]

    private static func number(_ token: String) -> Int? {
        Int(token) ?? numberWords[token.lowercased()]
    }

    private func matches(_ pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).map { match in
            (1..<match.numberOfRanges).compactMap { index in
                Range(match.range(at: index), in: text).map { String(text[$0]) }
            }
        }
    }

    /// The deck holds 40 high-card points. Every guide and quiz that quotes an
    /// average hand of 10 depends on it.
    func testDeckHoldsFortyPoints() {
        let deck = Suit.allCases.flatMap { suit in Rank.allCases.map { BridgeCard($0, suit) } }
        XCTAssertEqual(deck.count, 52)
        XCTAssertEqual(deck.highCardPoints, 40)
    }

    /// Recounts the cards of every authored opening hand and compares the
    /// point total and suit lengths its explanation quotes. A hand that says
    /// "14 HCP" over 12 points is exactly how a wrong answer key ships.
    func testAuthoredOpeningExplanationsQuoteTheRealHand() {
        let pointsPattern = "\\b(\\d+|zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty)\\s+(?:HCP|high-card points?|points)\\b"
        let lengthPattern = "\\b(three|four|five|six|seven)(?:-card)?\\s+(spades?|hearts?|diamonds?|clubs?)\\b"
        var checked = 0
        for question in allHandMatch {
            let actualPoints = question.cards.highCardPoints
            for match in matches(pointsPattern, in: question.explanation) {
                XCTAssertEqual(Self.number(match[0]), actualPoints, "\(question.id) quotes the wrong points: \(question.explanation)")
                checked += 1
            }
            for match in matches(lengthPattern, in: question.explanation) {
                let suit = Suit.allCases.first { match[1].lowercased().hasPrefix($0.rawValue.dropLast()) }
                let actual = question.cards.filter { $0.suit == suit }.count
                XCTAssertEqual(Self.number(match[0]), actual, "\(question.id) quotes the wrong suit length: \(question.explanation)")
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 15, "The recount should reach most authored hands")
    }

    /// The generated Count the Points drill must agree with an independent
    /// sum, in both the marked answer and the written breakdown.
    func testGeneratedPointCountsAreRight() {
        for item in EndlessPractice.items(for: .pointCount, count: 60) {
            let recount = item.cards.reduce(0) { total, card in
                switch card.rank {
                case .ace: return total + 4
                case .king: return total + 3
                case .queen: return total + 2
                case .jack: return total + 1
                default: return total
                }
            }
            XCTAssertEqual(Int(item.choices[item.answerIndex]), recount)
            XCTAssertTrue(item.explanation.contains("totals \(recount) high-card points"), item.explanation)
        }
    }

    /// The answer's place among the sorted choices must not give it away:
    /// with the old window it was never first or last.
    func testPointCountAnswerCanSitAnywhereInTheChoices() {
        let items = EndlessPractice.items(for: .pointCount, count: 400)
        var positions = [Int](repeating: 0, count: 4)
        for item in items {
            XCTAssertEqual(item.choices.count, 4)
            positions[item.answerIndex] += 1
        }
        for count in positions {
            XCTAssertGreaterThan(count, items.count / 8, "\(positions)")
        }
    }

    func testNoEmDashesInPlayerFacingContent() {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy += [room.name, room.tagline]
            for drill in room.drills {
                copy += [drill.title, drill.subtitle]
                switch drill.kind {
                case .flashcards(let cards):
                    copy += cards.flatMap { [$0.frontTitle, $0.frontSubtitle ?? "", $0.backTitle, $0.backBody] + ($0.choice?.options ?? []) }
                case .quiz(let questions):
                    copy += questions.flatMap { [$0.prompt, $0.explanation] + $0.choices }
                case .handMatch(let questions):
                    copy += questions.map(\.explanation)
                case .play(let scenarios):
                    copy += scenarios.flatMap { [$0.situation, $0.reasoning, $0.tip] }
                }
            }
        }
        copy += HowToPlayContent.pages.flatMap { [$0.title, $0.body, $0.tip ?? ""] }
        for text in copy {
            XCTAssertFalse(text.contains("\u{2014}"), "Em dash found: \(text)")
        }
    }

    func testQuickSessionRespectsMembership() {
        let free = SessionBuilder.quickSession(count: 500, seen: [], missed: [], includePro: false)
        let member = SessionBuilder.quickSession(count: 500, seen: [], missed: [], includePro: true)
        XCTAssertGreaterThanOrEqual(free.count, 10)
        XCTAssertGreaterThan(member.count, free.count)
        XCTAssertEqual(Set(free.map(\.id)).count, free.count)
        XCTAssertEqual(Set(member.map(\.id)).count, member.count)
        for item in member {
            XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
        }
    }
}
