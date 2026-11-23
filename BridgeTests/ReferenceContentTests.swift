import XCTest
@testable import Bridge

/// The glossary is read mid-game, so every number it quotes is checked
/// against the rules that grade the drills.
final class ReferenceContentTests: XCTestCase {

    private func definition(_ id: String) -> String {
        ReferenceContent.glossary.first { $0.id == id }?.definition ?? ""
    }

    private let deck: [BridgeCard] = Suit.allCases.flatMap { suit in Rank.allCases.map { BridgeCard($0, suit) } }

    func testIDsAreUniqueAndEveryGroupHasEntries() {
        let ids = ReferenceContent.glossary.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for group in GlossaryGroup.allCases {
            XCTAssertFalse(ReferenceContent.terms(in: group).isEmpty, group.title)
        }
    }

    func testNoEmDashes() {
        for term in ReferenceContent.glossary {
            XCTAssertFalse(term.term.contains("—") || term.definition.contains("—"), term.id)
        }
    }

    func testSearchFindsOtherNames() {
        XCTAssertTrue(ReferenceContent.terms(in: .hands, matching: "hcp").contains { $0.id == "g-hcp" })
        XCTAssertTrue(ReferenceContent.terms(in: .play, matching: "sluff").contains { $0.id == "g-discard" })
        XCTAssertTrue(ReferenceContent.terms(in: .bidding, matching: "stayman").contains { $0.id == "g-convention" })
        XCTAssertTrue(GlossaryGroup.allCases.allSatisfy { ReferenceContent.terms(in: $0, matching: "zzzz").isEmpty })
    }

    func testHighCardPointsAddUpTo40() {
        XCTAssertEqual(deck.count, 52)
        XCTAssertEqual(deck.highCardPoints, 40)
        XCTAssertEqual([Rank.ace, .king, .queen, .jack].map(\.highCardPoints), [4, 3, 2, 1])
        XCTAssertTrue(definition("g-hcp").contains("ace 4, king 3, queen 2, jack 1"))
        XCTAssertTrue(definition("g-hcp").contains("40"))
    }

    func testOneNotrumpRangeMatchesTheGrader() {
        XCTAssertTrue(definition("g-1nt").contains("15 to 17"))
        // Balanced 4-3-3-3 hands with no five-card major open 1NT at 15 and
        // 17, and not at 14 or 18.
        func hand(_ diamonds: [Rank], _ clubs: [Rank], hcp: Int) -> [BridgeCard] {
            let cards = [Rank.ace, .king, .three, .two].map { BridgeCard($0, .spades) }
                + [Rank.ace, .three, .two].map { BridgeCard($0, .hearts) }
                + diamonds.map { BridgeCard($0, .diamonds) }
                + clubs.map { BridgeCard($0, .clubs) }
            XCTAssertEqual(cards.count, 13)
            XCTAssertEqual(cards.highCardPoints, hcp)
            return cards
        }
        let fifteen = hand([.king, .three, .two], [.jack, .three, .two], hcp: 15)
        let seventeen = hand([.king, .three, .two], [.queen, .jack, .two], hcp: 17)
        let fourteen = hand([.king, .three, .two], [.four, .three, .two], hcp: 14)
        let eighteen = hand([.king, .jack, .two], [.king, .three, .two], hcp: 18)
        XCTAssertEqual(HandGenerator.opening(for: fifteen), .oneNotrump)
        XCTAssertEqual(HandGenerator.opening(for: seventeen), .oneNotrump)
        XCTAssertNotEqual(HandGenerator.opening(for: fourteen), .oneNotrump)
        XCTAssertNotEqual(HandGenerator.opening(for: eighteen), .oneNotrump)
    }

    func testQuotedScoresMatchTheScorer() {
        // Strains: 0 clubs, 1 diamonds, 2 hearts, 3 spades, 4 notrump.
        // Game: the five contracts named reach the game bonus, one level lower doesn't.
        for (level, strain) in [(3, 4), (4, 2), (4, 3), (5, 0), (5, 1)] {
            XCTAssertEqual(BridgeRules.score(level: level, strain: strain, tricks: level + 6, vulnerable: false) - (level * (strain < 2 ? 20 : 30) + (strain == 4 ? 10 : 0)), 300)
            XCTAssertEqual(BridgeRules.score(level: level - 1, strain: strain, tricks: level + 5, vulnerable: false) - ((level - 1) * (strain < 2 ? 20 : 30) + (strain == 4 ? 10 : 0)), 50)
        }
        XCTAssertTrue(definition("g-game").contains("3NT, 4♥, 4♠, 5♣ or 5♦"))
        // Trick score: 1NT is 40, 2NT 70, 1♣ 20, 1♠ 30, part score bonus 50.
        XCTAssertEqual(BridgeRules.score(level: 1, strain: 4, tricks: 7, vulnerable: false), 40 + 50)
        XCTAssertEqual(BridgeRules.score(level: 2, strain: 4, tricks: 8, vulnerable: false), 70 + 50)
        XCTAssertEqual(BridgeRules.score(level: 1, strain: 0, tricks: 7, vulnerable: false), 20 + 50)
        XCTAssertEqual(BridgeRules.score(level: 1, strain: 3, tricks: 7, vulnerable: false), 30 + 50)
        XCTAssertTrue(definition("g-part-score").contains("50"))
        // Game bonus 500 vulnerable, 300 not.
        XCTAssertEqual(BridgeRules.score(level: 4, strain: 3, tricks: 10, vulnerable: true), 120 + 500)
        XCTAssertTrue(definition("g-vulnerable").contains("500 vulnerable and 300 not vulnerable"))
        // Undertricks undoubled: 50 a trick, 100 vulnerable.
        XCTAssertEqual(BridgeRules.score(level: 4, strain: 2, tricks: 8, vulnerable: false), -100)
        XCTAssertEqual(BridgeRules.score(level: 4, strain: 2, tricks: 8, vulnerable: true), -200)
        XCTAssertTrue(definition("g-undertrick").contains("50 points, or 100"))
        // Overtricks undoubled score like contracted tricks.
        XCTAssertEqual(BridgeRules.score(level: 2, strain: 2, tricks: 9, vulnerable: false), 60 + 50 + 30)
        // Contract needs six plus the level.
        XCTAssertTrue(definition("g-contract").contains("4♥ needs ten tricks"))
        XCTAssertEqual(BridgeRules.score(level: 4, strain: 2, tricks: 9, vulnerable: false), -50)
    }

    func testBalancedShapesMatchTheClassifier() {
        XCTAssertTrue(definition("g-balanced").contains("4-3-3-3, 4-4-3-2 and 5-3-3-2"))
        let shapes: [[Int]: Bool] = [[4, 3, 3, 3]: true, [4, 4, 3, 2]: true, [5, 3, 3, 2]: true, [5, 4, 2, 2]: false, [4, 4, 4, 1]: false, [5, 4, 4, 0]: false]
        for (lengths, balanced) in shapes {
            let cards = zip(Suit.allCases, lengths).flatMap { suit, count in Rank.allCases.prefix(count).map { BridgeCard($0, suit) } }
            XCTAssertEqual(HandGenerator.Shape(cards).isBalanced, balanced, "\(lengths)")
        }
    }
}
