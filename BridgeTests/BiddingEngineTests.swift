import XCTest
@testable import Bridge

/// Responding and opener's rebid (1.3). Authored questions must agree with the
/// engine that grades Endless Practice, for the same reason
/// `HandGeneratorTests.testAuthoredHandsMatchTheClassifier` exists: two drills
/// that disagree about one hand cost the player's trust.
final class BiddingEngineTests: XCTestCase {

    private func hand(_ text: String) -> [BridgeCard] {
        // "S:AKJ75 H:K4 D:A983 C:52"
        var cards: [BridgeCard] = []
        for part in text.split(separator: " ") where part.count > 2 {
            let suit: Suit
            switch part.first {
            case "S": suit = .spades
            case "H": suit = .hearts
            case "D": suit = .diamonds
            default: suit = .clubs
            }
            var ranks = String(part.dropFirst(2))
            while !ranks.isEmpty {
                if ranks.hasPrefix("10") {
                    cards.append(BridgeCard(.ten, suit))
                    ranks.removeFirst(2)
                } else {
                    let rank = Rank(rawValue: String(ranks.removeFirst()))!
                    cards.append(BridgeCard(rank, suit))
                }
            }
        }
        XCTAssertEqual(cards.count, 13, text)
        return cards
    }

    private func call(_ text: String, _ situation: BiddingSituation) -> BiddingCall? {
        BiddingEngine.call(for: hand(text), in: situation)
    }

    // MARK: - Authored content

    func testAuthoredQuestionsMatchTheEngine() {
        for question in BiddingContent.responses + BiddingContent.rebids {
            XCTAssertEqual(question.cards.count, 13, question.id)
            XCTAssertEqual(Set(question.cards).count, 13, "\(question.id) repeats a card")
            XCTAssertTrue(question.choices.contains(question.answer), "\(question.id) hides its answer")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, question.id)
            XCTAssertEqual(BiddingEngine.call(for: question.cards, in: question.situation), question.answer, question.id)
        }
    }

    func testAuthoredChoicesAreInBiddingOrder() {
        for question in BiddingContent.responses + BiddingContent.rebids {
            let order = question.choices.compactMap { BiddingCall.allCases.firstIndex(of: $0) }
            XCTAssertEqual(order, order.sorted(), question.id)
        }
    }

    func testAuthoredExplanationsQuoteTheRealPoints() {
        for question in BiddingContent.responses + BiddingContent.rebids {
            let hcp = question.cards.highCardPoints
            XCTAssertTrue(question.explanation.hasPrefix("\(hcp) high-card points"), "\(question.id) says the wrong count")
        }
    }

    func testAuctionRoomTeachesTheNextBids() throws {
        let room = try XCTUnwrap(DrillLibrary.room(id: "auction-room"))
        let free = room.drills.filter { !$0.isPlus }.map(\.id)
        XCTAssertTrue(free.contains("respond-to-partner"))
        XCTAssertTrue(free.contains("opener-rebid"))
    }

    // MARK: - Responder

    func testResponderRanges() {
        XCTAssertEqual(call("S:Q873 H:92 D:J865 C:Q74", .response(.hearts)), .pass)
        XCTAssertEqual(call("S:K84 H:Q963 D:J72 C:853", .response(.hearts)), .twoHearts)
        XCTAssertEqual(call("S:KJ752 H:84 D:Q63 C:1074", .response(.hearts)), .oneSpade)
        XCTAssertEqual(call("S:73 H:KJ64 D:Q852 C:K93", .response(.spades)), .oneNotrump)
        XCTAssertEqual(call("S:Q964 H:A73 D:K1082 C:J5", .response(.spades)), .threeSpades)
        XCTAssertEqual(call("S:82 H:A6 D:KQ974 C:K853", .response(.spades)), .twoDiamonds)
    }

    func testResponderJudgmentCallsAreNotGraded() {
        // 13 or more: game-forcing methods are a later lesson.
        XCTAssertNil(call("S:AQ4 H:KJ5 D:Q872 C:K63", .response(.hearts)))
        // Three hearts and four spades: a raise and 1♠ are both taught.
        XCTAssertNil(call("S:KJ84 H:Q73 D:J52 C:963", .response(.hearts)))
        // A ten-count without support sits between 1NT and a two-level suit.
        XCTAssertNil(call("S:73 H:KJ6 D:AQ85 C:9842", .response(.spades)))
        // Three-card support with limit-raise values: style varies.
        XCTAssertNil(call("S:Q96 H:A73 D:K1082 C:J54", .response(.spades)))
        // Five points with shortness: dummy points reach a raise.
        XCTAssertNil(call("S:J852 H:7 D:Q9643 C:Q82", .response(.spades)))
        // Two equal two-level suits.
        XCTAssertNil(call("S:832 H:A6 D:KJ97 C:KJ85", .response(.hearts)))
    }

    func testTwoLevelHeartsNeedsFiveOverSpades() {
        // Four hearts and four clubs, 12 points: some teach 2♥ on four.
        XCTAssertNil(call("S:82 H:AJ64 D:K72 C:KJ53", .response(.spades)))
        XCTAssertEqual(call("S:82 H:AJ6 D:K72 C:KJ853", .response(.spades)), .twoClubs)
        XCTAssertEqual(call("S:82 H:AJ642 D:K72 C:KJ5", .response(.spades)), .twoHearts)
    }

    // MARK: - Opener

    func testRebidAfterRaise() {
        XCTAssertEqual(call("S:K73 H:AQ964 D:Q85 C:Q2", .rebidAfterRaise(.hearts)), .pass)
        XCTAssertEqual(call("S:AKJ75 H:K4 D:AJ83 C:52", .rebidAfterRaise(.spades)), .threeSpades)
        // 15 high-card points counts as minimum by plain points: not graded.
        XCTAssertNil(call("S:AKJ75 H:K4 D:A983 C:52", .rebidAfterRaise(.spades)))
        // Seven hearts play far above twelve points.
        XCTAssertNil(call("S:5 H:AKQ8642 D:K93 C:72", .rebidAfterRaise(.hearts)))
        XCTAssertEqual(call("S:A5 H:AKJ84 D:KQ6 C:Q73", .rebidAfterRaise(.hearts)), .fourHearts)
        // 16 balanced with five hearts: the app does not grade the opening, so
        // it never grades the rebid either.
        XCTAssertNil(call("S:A5 H:AKJ84 D:Q86 C:Q73", .rebidAfterRaise(.hearts)))
    }

    func testRebidAfterOneSpade() {
        XCTAssertEqual(call("S:KJ84 H:AQ1063 D:K5 C:72", .rebidAfterOneSpade), .twoSpades)
        // A singleton lifts the support points toward a jump raise.
        XCTAssertNil(call("S:AQ84 H:KJ963 D:5 C:K72", .rebidAfterOneSpade))
        XCTAssertEqual(call("S:Q4 H:AJ863 D:K72 C:KJ5", .rebidAfterOneSpade), .oneNotrump)
        XCTAssertEqual(call("S:J3 H:AKJ974 D:Q62 C:Q5", .rebidAfterOneSpade), .twoHearts)
        XCTAssertEqual(call("S:7 H:KQ852 D:AJ6 C:KJ43", .rebidAfterOneSpade), .twoClubs)
        // A medium hand has jump rebids; not graded here.
        XCTAssertNil(call("S:Q4 H:AKJ63 D:KQ82 C:J5", .rebidAfterOneSpade))
        // Both minors: which to show is style.
        XCTAssertNil(call("S: H:KQ852 D:AJ64 C:KJ43", .rebidAfterOneSpade))
    }

    func testRebidAfterOneNotrump() {
        XCTAssertEqual(call("S:AQ863 H:K72 D:Q94 C:Q5", .rebidAfterOneNotrump), .pass)
        XCTAssertEqual(call("S:KQ974 H:AJ62 D:K5 C:83", .rebidAfterOneNotrump), .twoHearts)
        XCTAssertEqual(call("S:AQJ852 H:K4 D:963 C:Q7", .rebidAfterOneNotrump), .twoSpades)
        // Six spades and four hearts: rebid spades or show hearts is style.
        XCTAssertNil(call("S:AQJ852 H:KQ42 D:96 C:7", .rebidAfterOneNotrump))
    }

    // MARK: - Generation

    func testGeneratedQuestionsAreSelfConsistent() {
        var generator = StableSeededGenerator(seed: "bidding-tests")
        for responses in [true, false] {
            let batch = BiddingEngine.batch(responses: responses, count: 40, using: &generator)
            XCTAssertEqual(batch.count, 40)
            for question in batch {
                XCTAssertEqual(BiddingEngine.call(for: question.cards, in: question.situation), question.answer)
                XCTAssertTrue(question.choices.contains(question.answer))
                XCTAssertEqual(question.situation.isResponse, responses)
                XCTAssertFalse(question.explanation.isEmpty)
                XCTAssertFalse(question.explanation.contains("—"))
            }
        }
    }

    func testEveryReachableAnswerCanBeDealt() {
        var generator = StableSeededGenerator(seed: "bidding-reach")
        for situation in BiddingSituation.all {
            for answer in BiddingEngine.reachableAnswers(situation) {
                XCTAssertNotNil(BiddingEngine.question(situation, answer: answer, using: &generator),
                                "\(situation) never deals \(answer)")
                XCTAssertTrue(situation.candidates.contains(answer))
            }
        }
    }

    func testEndlessSkillsUseTheEngine() {
        for skill in [PracticeSkill.responses, .rebids] {
            let items = EndlessPractice.items(for: skill, count: 12)
            XCTAssertEqual(items.count, 12)
            for item in items {
                XCTAssertEqual(PracticeSkill.skill(forItemID: item.id), skill)
                XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
                XCTAssertEqual(item.cards.count, 13)
            }
        }
    }
}
