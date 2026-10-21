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

    // MARK: - SAYC edge cases

    /// SAYC opens one of a suit with 13 or more. A 12 opens only when points
    /// plus the two longest suits reach 20 (the Rule of 20).
    func testTwelveOpensOnlyByRuleOfTwenty() {
        // 12 HCP, 5-3-3-2: 12 + 5 + 3 = 20.
        let fiveThreeThreeTwo: [BridgeCard] = [
            .s(.ace), .s(.queen), .s(.seven), .s(.five), .s(.three),
            .h(.king), .h(.six), .h(.four),
            .d(.jack), .d(.eight), .d(.two),
            .c(.queen), .c(.nine)
        ]
        XCTAssertEqual(fiveThreeThreeTwo.highCardPoints, 12)
        XCTAssertEqual(HandGenerator.Shape(fiveThreeThreeTwo).ruleOfTwenty, 20)
        XCTAssertEqual(HandGenerator.opening(for: fiveThreeThreeTwo), .oneSpade)

        // 12 HCP, 4-3-3-3: 12 + 4 + 3 = 19, a judgment call, so not graded.
        let fourThreeThreeThree: [BridgeCard] = [
            .s(.ace), .s(.queen), .s(.seven), .s(.five),
            .h(.king), .h(.six), .h(.four),
            .d(.jack), .d(.eight), .d(.two),
            .c(.queen), .c(.nine), .c(.three)
        ]
        XCTAssertEqual(fourThreeThreeThree.highCardPoints, 12)
        XCTAssertEqual(HandGenerator.Shape(fourThreeThreeThree).ruleOfTwenty, 19)
        XCTAssertNil(HandGenerator.opening(for: fourThreeThreeThree))
    }

    /// 13 opens with no help from the Rule of 20, and 4-3-3-3 with three of
    /// each minor opens the short club.
    func testThirteenOpensFlatAndThreeThreeMinorsOpenClub() {
        let cards: [BridgeCard] = [
            .s(.ace), .s(.queen), .s(.seven), .s(.five),
            .h(.king), .h(.six), .h(.four),
            .d(.jack), .d(.eight), .d(.two),
            .c(.king), .c(.nine), .c(.three)
        ]
        XCTAssertEqual(cards.highCardPoints, 13)
        XCTAssertEqual(HandGenerator.opening(for: cards), .oneClub)
    }

    /// SAYC opens the longest suit: 5 spades and 6 clubs opens 1♣, 5 hearts
    /// and 6 diamonds opens 1♦.
    func testLongerMinorBeatsFiveCardMajor() {
        let spadesAndClubs: [BridgeCard] = [
            .s(.king), .s(.queen), .s(.eight), .s(.five), .s(.three),
            .h(.four),
            .d(.two),
            .c(.ace), .c(.king), .c(.nine), .c(.eight), .c(.six), .c(.three)
        ]
        XCTAssertEqual(HandGenerator.opening(for: spadesAndClubs), .oneClub)

        let heartsAndDiamonds: [BridgeCard] = [
            .s(.four),
            .h(.king), .h(.queen), .h(.eight), .h(.five), .h(.three),
            .c(.two),
            .d(.ace), .d(.king), .d(.nine), .d(.eight), .d(.six), .d(.three)
        ]
        XCTAssertEqual(HandGenerator.opening(for: heartsAndDiamonds), .oneDiamond)
    }

    /// Equal length opens the higher ranking suit: 5-5 and 6-6 across a major
    /// and a minor both open the major.
    func testEqualMajorAndMinorOpensTheMajor() {
        let fiveFive: [BridgeCard] = [
            .s(.ace), .s(.king), .s(.eight), .s(.five), .s(.three),
            .h(.four),
            .d(.two), .d(.three),
            .c(.ace), .c(.queen), .c(.nine), .c(.eight), .c(.six)
        ]
        XCTAssertEqual(HandGenerator.Shape(fiveFive).pattern, "5-5-2-1")
        XCTAssertEqual(HandGenerator.opening(for: fiveFive), .oneSpade)

        let sixSix: [BridgeCard] = [
            .s(.ace), .s(.king), .s(.queen), .s(.eight), .s(.five), .s(.three),
            .h(.two),
            .c(.king), .c(.jack), .c(.nine), .c(.seven), .c(.six), .c(.four)
        ]
        XCTAssertEqual(HandGenerator.Shape(sixSix).pattern, "6-6-1-0")
        XCTAssertEqual(HandGenerator.opening(for: sixSix), .oneSpade)
    }

    /// SAYC: 4-4 in the minors opens 1♦.
    func testFourFourMinorsOpenDiamonds() {
        let cards: [BridgeCard] = [
            .s(.king), .s(.seven), .s(.three),
            .h(.ace), .h(.five),
            .d(.queen), .d(.jack), .d(.eight), .d(.two),
            .c(.king), .c(.nine), .c(.six), .c(.four)
        ]
        XCTAssertEqual(cards.highCardPoints, 13)
        XCTAssertEqual(HandGenerator.opening(for: cards), .oneDiamond)
    }

    /// 4-4-4-1 has no longest suit and SAYC is silent, so it is not graded.
    func testFourFourFourOneIsNotGraded() {
        let cards: [BridgeCard] = [
            .s(.ace), .s(.king), .s(.seven), .s(.five),
            .h(.queen), .h(.eight), .h(.four), .h(.two),
            .d(.king), .d(.jack), .d(.three), .d(.two),
            .c(.six)
        ]
        XCTAssertEqual(cards.highCardPoints, 13)
        XCTAssertNil(HandGenerator.opening(for: cards))
    }

    /// 11 is a judgment call and 1NT is exactly 15 to 17.
    func testElevenIsNotGradedAndNotrumpEdges() {
        let eleven: [BridgeCard] = [
            .s(.ace), .s(.queen), .s(.seven), .s(.five),
            .h(.king), .h(.six), .h(.four),
            .d(.eight), .d(.five), .d(.two),
            .c(.queen), .c(.nine), .c(.three)
        ]
        XCTAssertEqual(eleven.highCardPoints, 11)
        XCTAssertNil(HandGenerator.opening(for: eleven))

        // 14 HCP balanced is below the notrump range, so it opens a minor.
        let fourteen: [BridgeCard] = [
            .s(.ace), .s(.queen), .s(.seven), .s(.five),
            .h(.king), .h(.six), .h(.four),
            .d(.queen), .d(.eight), .d(.two),
            .c(.king), .c(.nine), .c(.three)
        ]
        XCTAssertEqual(fourteen.highCardPoints, 14)
        XCTAssertEqual(HandGenerator.opening(for: fourteen), .oneClub)
    }

    /// SAYC 1NT is a balanced 15 to 17: 15 and 17 are in, 14 and 18 are out.
    func testNotrumpRangeIsFifteenToSeventeen() {
        func balanced(_ spades: [Rank], _ hearts: [Rank], _ diamonds: [Rank], _ clubs: [Rank]) -> [BridgeCard] {
            spades.map { BridgeCard($0, .spades) } + hearts.map { BridgeCard($0, .hearts) }
                + diamonds.map { BridgeCard($0, .diamonds) } + clubs.map { BridgeCard($0, .clubs) }
        }
        let fifteen = balanced([.ace, .queen, .seven, .five], [.king, .jack, .four], [.queen, .eight, .two], [.king, .nine, .three])
        let seventeen = balanced([.ace, .king, .seven, .five], [.king, .jack, .four], [.queen, .eight, .two], [.ace, .nine, .three])
        let eighteen = balanced([.ace, .king, .seven, .five], [.king, .jack, .four], [.queen, .eight, .two], [.ace, .jack, .three])
        XCTAssertEqual(fifteen.highCardPoints, 15)
        XCTAssertEqual(seventeen.highCardPoints, 17)
        XCTAssertEqual(eighteen.highCardPoints, 18)
        XCTAssertEqual(HandGenerator.opening(for: fifteen), .oneNotrump)
        XCTAssertEqual(HandGenerator.opening(for: seventeen), .oneNotrump)
        XCTAssertEqual(HandGenerator.opening(for: eighteen), .oneClub)
    }

    /// Every explanation must state the numbers it grades with, so the
    /// coaching line can never contradict the rule behind the answer.
    func testExplanationsQuoteTheRuleThatGradedThem() {
        var generator = StableSeededGenerator(seed: "sayc-explanations")
        for _ in 0..<40 {
            for target in HandCategory.allCases {
                guard let hand = HandGenerator.hand(for: target, using: &generator) else {
                    XCTFail("No hand for \(target.displayName)")
                    continue
                }
                let shape = HandGenerator.Shape(hand.cards)
                XCTAssertTrue(hand.explanation.contains("\(shape.highCardPoints) high-card point"), hand.explanation)
                if target == .pass {
                    XCTAssertTrue(hand.explanation.contains("13 or more"), hand.explanation)
                }
                if shape.highCardPoints == 12 {
                    XCTAssertTrue(hand.explanation.contains("Rule of 20"), "A 12 opens only by the Rule of 20: \(hand.explanation)")
                    XCTAssertGreaterThanOrEqual(shape.ruleOfTwenty, 20)
                }
                if target == .oneClub || target == .oneDiamond, shape.hasFiveCardMajor {
                    XCTAssertGreaterThanOrEqual(shape.longestMinorLength, shape.length(shape.longestMajor ?? .spades) + 1)
                }
            }
        }
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
            let classified = HandGenerator.opening(for: question.cards)
            XCTAssertNotNil(classified, "\(question.id) is a hand the classifier does not grade")
            XCTAssertEqual(classified, question.answer, "\(question.id) disagrees with the classifier")
        }
    }
}
