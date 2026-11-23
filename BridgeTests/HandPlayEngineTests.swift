import XCTest
@testable import Bridge

/// Every authored deal must be a legal, complete hand whose coach's line makes
/// the contract, and South's coached calls must agree with the engines that
/// grade the bidding drills.
final class HandPlayEngineTests: XCTestCase {
    private let deals = HandPlayContent.deals

    func testDealsUseEveryCardOnce() {
        for deal in deals {
            let all = deal.hands.values.flatMap { $0 }
            XCTAssertEqual(Set(all).count, 52, deal.id)
            for seat in Seat.allCases {
                XCTAssertEqual(deal.hands[seat]?.count, 13, "\(deal.id) \(seat)")
            }
            XCTAssertEqual(deal.tricks.count, 13, deal.id)
            XCTAssertEqual(Set(deal.tricks.flatMap { $0 }), Set(all), deal.id)
        }
    }

    func testAuctionsEndWithSouthDeclaring() throws {
        for deal in deals {
            let auction = try XCTUnwrap(deal.auction, deal.id)
            XCTAssertTrue(auction.ended, deal.id)
            XCTAssertEqual(auction.declarer, Seat.south.rawValue, deal.id)
            XCTAssertEqual(deal.openingLeader, .west, deal.id)
        }
    }

    func testCoachedCallsAgreeWithTheEngines() {
        for deal in deals {
            let south = deal.hands[.south] ?? []
            XCTAssertFalse(deal.coachedCalls.isEmpty, deal.id)
            for (index, coached) in deal.coachedCalls {
                XCTAssertEqual(Seat(rawValue: (deal.dealer.rawValue + index) % 4), .south, deal.id)
                switch coached {
                case .opening:
                    XCTAssertEqual(HandGenerator.opening(for: south)?.auctionCall, deal.calls[index], deal.id)
                case .rebid(let situation):
                    XCTAssertEqual(BiddingEngine.call(for: south, in: situation)?.auctionCall, deal.calls[index], deal.id)
                }
            }
        }
    }

    /// Replays the coach's line: every card is the player's own and legal,
    /// and the contract makes.
    func testCoachLineIsLegalAndMakes() {
        for deal in deals {
            var engine = HandPlayEngine(deal: deal)
            playAuction(&engine)
            while engine.phase == .play {
                let card = engine.coachCard
                XCTAssertTrue(engine.legalCards.contains(card), "\(deal.id) trick \(engine.trickIndex + 1): \(card.shortLabel)")
                if engine.pendingDecision != nil {
                    XCTAssertEqual(engine.submitPlay(card)?.verdict, .right, deal.id)
                    engine.dismissNote()
                } else {
                    engine.advancePlay()
                }
            }
            XCTAssertEqual(engine.phase, .finished, deal.id)
            XCTAssertGreaterThanOrEqual(engine.declarerTricks, deal.tricksNeeded, deal.id)
            XCTAssertGreaterThan(engine.score, 0, deal.id)
            XCTAssertEqual(engine.state.right, engine.state.decided, deal.id)
        }
    }

    /// A decision with no wrong card is not a decision, and an also-fine card
    /// must be one the player can actually play there.
    func testDecisionsHaveAWrongCard() {
        for deal in deals {
            XCTAssertGreaterThanOrEqual(deal.decisions.count, 3, deal.id)
            var engine = HandPlayEngine(deal: deal)
            playAuction(&engine)
            var reached = 0
            while engine.phase == .play {
                if let decision = engine.pendingDecision {
                    reached += 1
                    XCTAssertTrue(decision.seat.isDeclarerSide, deal.id)
                    let wrong = engine.legalCards.filter {
                        $0 != engine.coachCard && !engine.isLineEquivalent($0) && !decision.alsoFine.contains($0)
                    }
                    XCTAssertFalse(wrong.isEmpty, "\(deal.id) trick \(decision.trick + 1)")
                    for card in decision.alsoFine {
                        XCTAssertTrue(engine.legalCards.contains(card), "\(deal.id) also fine \(card.shortLabel)")
                    }
                    _ = engine.submitPlay(engine.coachCard)
                    engine.dismissNote()
                } else {
                    engine.advancePlay()
                }
            }
            XCTAssertEqual(reached, deal.decisions.count, "\(deal.id): a decision is never reached")
        }
    }

    func testFinesseIsNotEquivalentToCashingTheAce() throws {
        var engine = HandPlayEngine(deal: HandPlayContent.finesse)
        playAuction(&engine)
        playUntil(&engine, trick: 5, seat: .south)
        XCTAssertEqual(engine.coachCard, .h(.queen))
        XCTAssertFalse(engine.isLineEquivalent(.h(.ace)))
        let note = try XCTUnwrap(engine.submitPlay(.h(.ace)))
        XCTAssertEqual(note.verdict, .miss)
        XCTAssertNotNil(note.whyNot)
        // A miss plays the coach's card, so the rest of the line stays true.
        XCTAssertEqual(engine.state.line[5][2], .h(.queen))
    }

    func testEqualCardIsGradedRightAndPlayed() throws {
        var engine = HandPlayEngine(deal: HandPlayContent.holdUp)
        playAuction(&engine)
        playUntil(&engine, trick: 0, seat: .south)
        XCTAssertEqual(engine.coachCard, .s(.four))
        let note = try XCTUnwrap(engine.submitPlay(.s(.seven)))
        XCTAssertEqual(note.verdict, .right)
        XCTAssertEqual(engine.state.line[0][3], .s(.seven))
        XCTAssertEqual(engine.state.line[1][3], .s(.four))
    }

    func testHoldUpMissExplainsWhyNot() throws {
        var engine = HandPlayEngine(deal: HandPlayContent.holdUp)
        playAuction(&engine)
        playUntil(&engine, trick: 0, seat: .south)
        let note = try XCTUnwrap(engine.submitPlay(.s(.ace)))
        XCTAssertEqual(note.verdict, .miss)
        XCTAssertEqual(note.coachLabel, BridgeCard.s(.four).shortLabel)
        XCTAssertNotNil(note.whyNot)
    }

    func testAlsoFineGradesRightAndKeepsTheLine() throws {
        var engine = HandPlayEngine(deal: HandPlayContent.ruffFirst)
        playAuction(&engine)
        playUntil(&engine, trick: 1, seat: .south)
        let note = try XCTUnwrap(engine.submitPlay(.d(.ace)))
        XCTAssertEqual(note.verdict, .alsoFine)
        XCTAssertEqual(engine.state.line[1][0], .s(.ace))
    }

    func testIllegalCardIsRefused() {
        var engine = HandPlayEngine(deal: HandPlayContent.holdUp)
        playAuction(&engine)
        playUntil(&engine, trick: 0, seat: .south)
        XCTAssertNil(engine.submitPlay(.h(.ace)), "South must follow to the spade lead")
    }

    func testWrongOpeningCallUsesTheEngineNote() throws {
        var engine = HandPlayEngine(deal: HandPlayContent.holdUp)
        let note = try XCTUnwrap(engine.submitCall("1D"))
        XCTAssertEqual(note.verdict, .miss)
        XCTAssertEqual(note.whyNot, HandGenerator.missNote(picked: .oneDiamond, answer: .oneNotrump))
        XCTAssertEqual(engine.state.callsMade, 1)
        XCTAssertNil(engine.submitCall("1NT"), "the next call waits for Continue")
    }

    func testStateRoundTripsThroughCoding() throws {
        var engine = HandPlayEngine(deal: HandPlayContent.drawTrumps)
        playAuction(&engine)
        engine.advancePlay()
        let data = try JSONEncoder().encode(engine.state)
        let decoded = try JSONDecoder().decode(HandPlayState.self, from: data)
        let restored = try XCTUnwrap(HandPlayEngine(state: decoded))
        XCTAssertEqual(restored.state, engine.state)
        XCTAssertEqual(restored.seatToPlay, engine.seatToPlay)
    }

    // MARK: - Helpers

    private func playAuction(_ engine: inout HandPlayEngine) {
        while engine.phase == .auction {
            if engine.pendingCoachedCall != nil {
                _ = engine.submitCall(engine.deal.calls[engine.state.callsMade])
                engine.dismissNote()
            } else {
                engine.advanceCall()
            }
        }
    }

    private func playUntil(_ engine: inout HandPlayEngine, trick: Int, seat: Seat) {
        while engine.phase == .play, !(engine.trickIndex == trick && engine.seatToPlay == seat) {
            if engine.pendingDecision != nil {
                _ = engine.submitPlay(engine.coachCard)
                engine.dismissNote()
            } else {
                engine.advancePlay()
            }
        }
    }
}

@MainActor
final class HandPlayStoreTests: XCTestCase {
    private func store() -> (HandPlayStore, UserDefaults) {
        let name = "HandPlayStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return (HandPlayStore(defaults: defaults), defaults)
    }

    func testFreePlayerGetsOneHandADay() {
        let (store, _) = store()
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertTrue(store.canPlay(isMember: false, now: day))
        store.save(store.currentState(), isMember: false, now: day)
        XCTAssertTrue(store.canPlay(isMember: false, now: day), "a started hand stays playable")
        store.finish()
        XCTAssertFalse(store.canPlay(isMember: false, now: day))
        XCTAssertTrue(store.canPlay(isMember: true, now: day))
        XCTAssertTrue(store.canPlay(isMember: false, now: day.addingTimeInterval(86_400)))
    }

    func testMemberHandDoesNotSpendTheFreeDay() {
        let (store, _) = store()
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        store.save(store.currentState(), isMember: true, now: day)
        store.finish()
        XCTAssertTrue(store.canPlay(isMember: false, now: day))
    }

    func testRotationAndResume() {
        let (store, defaults) = store()
        let first = store.currentState().dealID
        var engine = HandPlayEngine(deal: HandPlayContent.deal(id: first)!)
        _ = engine.submitCall(engine.deal.calls[0])
        store.save(engine.state, isMember: true)
        let reopened = HandPlayStore(defaults: defaults)
        XCTAssertEqual(reopened.currentState(), engine.state)
        reopened.finish()
        XCTAssertNotEqual(reopened.currentState().dealID, first)
        XCTAssertEqual(reopened.handsPlayed, 1)
    }
}
