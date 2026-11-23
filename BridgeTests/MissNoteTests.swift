import XCTest
@testable import Bridge

/// "Why not X?" notes on opening questions. Each note states what the picked
/// call needs, so it is only honest when the hand really fails that rule.
final class MissNoteTests: XCTestCase {

    private func length(_ cards: [BridgeCard], _ suit: Suit) -> Int {
        cards.filter { $0.suit == suit }.count
    }

    /// The rule each suit note states, checked against the cards directly
    /// rather than through `HandGenerator.Shape`.
    private func meetsStatedRule(_ cards: [BridgeCard], _ call: HandCategory) -> Bool {
        let spades = length(cards, .spades), hearts = length(cards, .hearts)
        let diamonds = length(cards, .diamonds), clubs = length(cards, .clubs)
        let longMajor = max(spades, hearts) >= 5 ? max(spades, hearts) : 0
        let longMinor = max(clubs, diamonds)
        switch call {
        case .oneClub:
            return clubs > longMajor && (clubs > diamonds || (clubs == 3 && diamonds == 3))
        case .oneDiamond:
            return diamonds > longMajor && (diamonds > clubs || (diamonds == clubs && diamonds >= 4))
        case .oneHeart:
            return hearts >= 5 && hearts > spades && hearts >= longMinor
        case .oneSpade:
            return spades >= 5 && spades >= hearts && spades >= longMinor
        case .pass, .oneNotrump:
            return false
        }
    }

    func testEveryWrongPickHasAnHonestNote() {
        let hands = HandGenerator.batch(count: 400, seed: "miss-notes")
        XCTAssertEqual(Set(hands.map(\.answer)), Set(HandCategory.allCases))
        for hand in hands {
            XCTAssertNil(HandGenerator.missNote(picked: hand.answer, answer: hand.answer))
            for picked in HandCategory.allCases where picked != hand.answer {
                let note = HandGenerator.missNote(picked: picked, answer: hand.answer)
                XCTAssertNotNil(note, "\(picked) over \(hand.answer)")
                XCTAssertFalse(note?.contains("—") ?? true)
                let suitNoteShown = hand.answer != .pass && hand.answer != .oneNotrump && picked != .pass && picked != .oneNotrump
                if suitNoteShown {
                    XCTAssertFalse(meetsStatedRule(hand.cards, picked), "\(hand.cards) meets the \(picked) note but opens \(hand.answer)")
                }
            }
        }
    }

    func testAuthoredHandsCarryNotesThroughTheShuffle() {
        let items = SessionBuilder.choiceItems(in: "auction-room", includePro: true)
        let openings = items.filter { item in item.choices.allSatisfy { label in HandCategory.allCases.contains { $0.displayName == label } } }
        XCTAssertFalse(openings.isEmpty)
        for item in openings {
            let answer = HandCategory.allCases.first { $0.displayName == item.choices[item.answerIndex] }!
            XCTAssertNil(item.note(forPick: item.answerIndex), item.id)
            for pick in item.choices.indices where pick != item.answerIndex {
                let picked = HandCategory.allCases.first { $0.displayName == item.choices[pick] }!
                XCTAssertEqual(item.note(forPick: pick), HandGenerator.missNote(picked: picked, answer: answer), item.id)
            }
        }
    }

    func testEndlessOpeningsCarryNotes() {
        for item in EndlessPractice.items(for: .openings, count: 12) {
            XCTAssertNil(item.note(forPick: item.answerIndex))
            for pick in item.choices.indices where pick != item.answerIndex {
                XCTAssertNotNil(item.note(forPick: pick), item.id)
            }
        }
    }

    func testItemsWithoutNotesStaySilent() {
        let item = QuickItem(id: "x", prompt: "p", cards: [], choices: ["a", "b"], answerIndex: 0,
                             explanation: "e", sourceLabel: "s", roomID: "r")
        XCTAssertNil(item.note(forPick: 1))
        XCTAssertNil(item.note(forPick: 5))
    }
}
