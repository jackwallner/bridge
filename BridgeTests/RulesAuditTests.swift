import XCTest
@testable import Bridge

final class RulesAuditTests: XCTestCase {
    private func card(_ code: String) -> BridgeCard {
        let suits: [Character: Suit] = ["C": .clubs, "D": .diamonds, "H": .hearts, "S": .spades]
        return BridgeCard(Rank(rawValue: String(code.dropFirst()))!, suits[code.first!]!)
    }
    private func reference() throws -> [String: Any] {
        let url = Bundle(for: Self.self).url(forResource: "rules-reference", withExtension: "json")
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Resources/rules-reference.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
    func testDuplicateScoringTable() throws {
        for row in try XCTUnwrap(reference()["scores"] as? [[String: Any]]) {
            XCTAssertEqual(BridgeRules.score(level: row["level"] as! Int, strain: row["strain"] as! Int,
                                            multiplier: row["multiplier"] as! Int, tricks: row["tricks"] as! Int,
                                            vulnerable: row["vulnerable"] as! Bool), row["score"] as! Int, "\(row)")
        }
    }
    func testLegalAuctionsAndPassedOutHands() throws {
        for row in try XCTUnwrap(reference()["auctions"] as? [[String: Any]]) {
            let result = try XCTUnwrap(BridgeRules.auction(row["calls"] as! [String]))
            XCTAssertEqual(result.ended, row["ended"] as! Bool, "\(row)")
            XCTAssertEqual(result.declarer, row["declarer"] as? Int, "\(row)")
            XCTAssertEqual(result.level, row["level"] as! Int)
            XCTAssertEqual(result.multiplier, row["multiplier"] as! Int)
        }
        for text in try XCTUnwrap(reference()["invalidAuctions"] as? [String]) {
            XCTAssertNil(BridgeRules.auction(text.split(separator: " ").map(String.init)), text)
        }
    }
    func testFollowingAndTrickWinners() throws {
        let reference = try reference()
        for row in reference["legal"] as! [[String: Any]] {
            let actual = BridgeRules.legal((row["hand"] as! [String]).map(card), led: Suit(rawValue: row["led"] as! String))
            XCTAssertEqual(actual, (row["expected"] as! [String]).map(card))
        }
        for row in reference["tricks"] as! [[String: Any]] {
            let trump = (row["trump"] as? String).flatMap(Suit.init(rawValue:))
            XCTAssertEqual(BridgeRules.winner((row["cards"] as! [String]).map(card), trump: trump), row["winner"] as? Int)
        }
    }
    func testSaycOpeningsAndTeachingCounts() throws {
        let hands = DrillLibrary.rooms.flatMap(\.drills).flatMap { drill -> [HandMatchQuestion] in
            if case .handMatch(let questions) = drill.kind { return questions }; return []
        }
        let counts = ["hand-one-spade": 14, "hand-one-heart": 14, "hand-one-nt-16": 16,
                      "hand-one-diamond": 16, "plus-open-spade-six": 13, "plus-open-club": 14]
        for (id, hcp) in counts {
            let hand = try XCTUnwrap(hands.first { $0.id == id })
            XCTAssertEqual(hand.cards.highCardPoints, hcp, id)
            XCTAssertTrue(hand.explanation.contains("\(hcp)"), id)
            XCTAssertEqual(HandGenerator.opening(for: hand.cards), hand.answer, id)
        }
        let shapes: [([Int], Bool)] = [([4, 3, 3, 3], true), ([4, 4, 3, 2], true), ([5, 3, 3, 2], true),
                                      ([5, 4, 2, 2], false), ([6, 3, 2, 2], false), ([4, 4, 4, 1], false)]
        for (lengths, balanced) in shapes {
            let cards = zip(Suit.allCases, lengths).flatMap { suit, count in Rank.allCases.prefix(count).map { BridgeCard($0, suit) } }
            XCTAssertEqual(HandGenerator.Shape(cards).isBalanced, balanced)
        }
        for (clubs, diamonds, minor) in [(3, 3, Suit.clubs), (4, 4, .diamonds), (5, 5, .diamonds)] {
            let cards = Array(Rank.allCases.prefix(clubs)).map { BridgeCard($0, .clubs) }
                + Array(Rank.allCases.prefix(diamonds)).map { BridgeCard($0, .diamonds) }
            XCTAssertEqual(HandGenerator.Shape(cards).longerMinor, minor)
        }
        for row in try reference()["openings"] as! [[String: Any]] {
            XCTAssertEqual(HandGenerator.opening(for: (row["cards"] as! [String]).map(card))?.rawValue, row["answer"] as? String)
        }
        XCTAssertNil(HandGenerator.opening(for: Array(repeating: .s(.ace), count: 13)))
    }
    func testGradedAdviceMatchesTheDisplayedPosition() throws {
        for scenario in ProContent.advancedPlay.filter({ $0.id == "pro-play-safety" }) + PlayContent.scenarios.filter({ $0.id == "play-win-cheaply" }) {
            let previous: [BridgeCard] = scenario.id == "pro-play-safety" ? [.c(.two), .c(.ten), .c(.jack)] : [.c(.four), .c(.six), .c(.nine)]
            let winners = scenario.cards.indices.filter { BridgeRules.winner(previous + [scenario.cards[$0]], trump: nil) == 3 }
            let cheapest = winners.min { scenario.cards[$0].rank.sortOrder < scenario.cards[$1].rank.sortOrder }
            XCTAssertEqual(cheapest, scenario.answerIndex)
            XCTAssertTrue(scenario.situation.contains("fourth"))
        }
        let game = try XCTUnwrap(ProContent.duplicateQuiz.first { $0.id == "pro-game-major" })
        XCTAssertTrue(game.prompt.contains("lowest"))
        XCTAssertEqual(game.choices[game.answerIndex], "4♥")
        let response = try XCTUnwrap(CategoryContent.openingCards.first { $0.id == "bid-response-ranges" })
        for range in ["6 to 10", "10 to 12", "10 or more", "one round", "nonforcing"] { XCTAssertTrue(response.backBody.contains(range)) }
    }
}
