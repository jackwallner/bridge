import XCTest
@testable import Bridge

/// The generator is the only content in the app nobody proofreads, so it has
/// to be provable rather than spot-checked.
final class HandGeneratorTests: XCTestCase {

    // MARK: - Classifier

    func testPassesWeakHand() {
        let cards: [BridgeCard] = [
            .s(.queen), .s(.seven), .s(.four),
            .h(.jack), .h(.nine), .h(.six), .h(.three),
            .d(.king), .d(.eight), .d(.five),
            .c(.ten), .c(.four), .c(.two)
        ]
        XCTAssertEqual(cards.highCardPoints, 6)
        XCTAssertEqual(HandGenerator.opening(for: cards), .pass)
    }

    func testOpensNotrumpOnBalancedFifteen() {
        let cards: [BridgeCard] = [
            .s(.ace), .s(.queen), .s(.six),
            .h(.king), .h(.nine), .h(.four),
            .d(.queen), .d(.jack), .d(.seven), .d(.two),
            .c(.king), .c(.eight), .c(.three)
        ]
        XCTAssertEqual(cards.highCardPoints, 15)
        XCTAssertEqual(HandGenerator.opening(for: cards), .oneNotrump)
    }

    func testOpensLongerMinorWhenTooWeakForNotrump() {
        let cards: [BridgeCard] = [
            .s(.king), .s(.nine), .s(.four),
            .h(.queen), .h(.eight), .h(.three),
            .d(.ace), .d(.jack), .d(.seven), .d(.five),
            .c(.king), .c(.six), .c(.two)
        ]
        XCTAssertEqual(cards.highCardPoints, 13)
        XCTAssertEqual(HandGenerator.opening(for: cards), .oneDiamond)
    }

    func testOpensSixCardMajor() {
        let cards: [BridgeCard] = [
            .s(.queen), .s(.five),
            .h(.ace), .h(.king), .h(.jack), .h(.nine), .h(.six), .h(.three),
            .d(.king), .d(.seven), .d(.four),
            .c(.eight), .c(.two)
        ]
        XCTAssertEqual(HandGenerator.opening(for: cards), .oneHeart)
    }

    /// 5-5 in the majors opens the higher ranking suit.
    func testPrefersSpadesWithBothMajors() {
        let cards: [BridgeCard] = [
            .s(.ace), .s(.king), .s(.eight), .s(.five), .s(.two),
            .h(.queen), .h(.jack), .h(.nine), .h(.six), .h(.three),
            .d(.king), .d(.four),
            .c(.seven)
        ]
        XCTAssertEqual(HandGenerator.opening(for: cards), .oneSpade)
    }

    /// Strong hands belong to 2♣ and 2NT, which this app does not teach yet.
    /// They must classify as nil so they never reach a player as a question.
    func testRejectsStrongHands() {
        let cards: [BridgeCard] = [
            .s(.ace), .s(.king), .s(.queen), .s(.four),
            .h(.ace), .h(.king), .h(.three),
            .d(.ace), .d(.queen), .d(.six),
            .c(.king), .c(.five), .c(.two)
        ]
        XCTAssertGreaterThanOrEqual(cards.highCardPoints, 20)
        XCTAssertNil(HandGenerator.opening(for: cards))
    }

    func testRejectsWrongCardCount() {
        XCTAssertNil(HandGenerator.opening(for: [.s(.ace), .s(.king)]))
    }

    // MARK: - Generation

    /// Every generated hand must hold 13 distinct cards and re-classify to the
    /// answer it was generated for. A generated question that grades itself
    /// wrong is worse than no question at all.
    func testGeneratedHandsAreSelfConsistent() {
        for target in HandCategory.allCases {
            guard let hand = HandGenerator.hand(for: target) else {
                XCTFail("Could not generate a hand for \(target.displayName)")
                continue
            }
            XCTAssertEqual(hand.cards.count, 13, "\(target.displayName) hand is not 13 cards")
            XCTAssertEqual(Set(hand.cards).count, 13, "\(target.displayName) hand has duplicate cards")
            XCTAssertEqual(HandGenerator.opening(for: hand.cards), target)
            XCTAssertFalse(hand.explanation.isEmpty)
            XCTAssertFalse(hand.explanation.contains("—"), "No em dashes in copy")
        }
    }

    func testBatchCoversEveryAnswer() {
        let hands = HandGenerator.batch(count: 60)
        XCTAssertGreaterThan(hands.count, 40, "Rejection sampling should still fill most of a batch")
        let answers = Set(hands.map(\.answer))
        XCTAssertEqual(answers.count, HandCategory.allCases.count, "A long batch should reach every answer")
    }

    // MARK: - Generated practice items

    func testEndlessItemsAreWellFormed() {
        for skill in PracticeSkill.allCases {
            let items = EndlessPractice.items(for: skill, count: 12)
            XCTAssertEqual(items.count, 12, "\(skill.rawValue) came up short")
            for item in items {
                XCTAssertTrue(item.id.hasPrefix(skill.itemPrefix))
                XCTAssertEqual(PracticeSkill.skill(forItemID: item.id), skill)
                XCTAssertGreaterThanOrEqual(item.choices.count, 2)
                XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
                XCTAssertEqual(Set(item.choices).count, item.choices.count, "Duplicate answer labels")
                XCTAssertFalse(item.explanation.isEmpty)
                XCTAssertFalse(item.roomID.isEmpty)
                XCTAssertNotNil(DrillLibrary.room(id: item.roomID))
            }
        }
    }

    func testMixedItemsDrawFromEverySkill() {
        let items = EndlessPractice.mixedItems(count: 40)
        XCTAssertEqual(items.count, 40)
        let skills = Set(items.compactMap { PracticeSkill.skill(forItemID: $0.id) })
        XCTAssertEqual(skills.count, PracticeSkill.allCases.count)
    }

    // MARK: - Authored hands agree with the classifier

    /// Cross-checks the hand-written opening drills against the same engine
    /// that grades Endless Practice. If a player can be told "1♦" by one drill
    /// and "1♣" by another for the same shape, the app has lost their trust.
    func testAuthoredHandsMatchTheClassifier() {
        let authored = DrillLibrary.rooms
            .flatMap(\.drills)
            .flatMap { drill -> [HandMatchQuestion] in
                if case .handMatch(let questions) = drill.kind { return questions }
                return []
            }
        XCTAssertFalse(authored.isEmpty)
        for question in authored {
            XCTAssertEqual(question.cards.count, 13, "\(question.id) is not a 13-card hand")
            XCTAssertEqual(Set(question.cards).count, 13, "\(question.id) repeats a card")
            XCTAssertTrue(question.choices.contains(question.answer), "\(question.id) cannot be answered")
            guard let classified = HandGenerator.opening(for: question.cards) else { continue }
            XCTAssertEqual(classified, question.answer, "\(question.id) disagrees with the classifier")
        }
    }
}
