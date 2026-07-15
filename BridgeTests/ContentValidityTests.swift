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
