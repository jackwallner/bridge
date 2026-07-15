import Foundation

struct HowToPlayPage: Identifiable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let cards: [BridgeCard]
    let tip: String?

    init(id: String, icon: String, title: String, body: String, cards: [BridgeCard] = [], tip: String? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.cards = cards
        self.tip = tip
    }
}

enum HowToPlayContent {
    static let pages: [HowToPlayPage] = [
        HowToPlayPage(
            id: "htp-table",
            icon: "person.4.fill",
            title: "Four players, two partnerships",
            body: "Partners sit opposite each other. A 52-card deck is dealt evenly, giving every player 13 cards. North-South compete against East-West.",
            cards: [.s(.ace), .h(.ace), .d(.ace), .c(.ace)]
        ),
        HowToPlayPage(
            id: "htp-tricks",
            icon: "square.stack.3d.up.fill",
            title: "Win tricks",
            body: "Each player contributes one card. You must follow the suit led when you can. The highest card in that suit wins unless a trump is played.",
            cards: [.h(.two), .h(.ten), .h(.king), .h(.ace)],
            tip: "The trick winner leads the next trick."
        ),
        HowToPlayPage(
            id: "htp-auction",
            icon: "quote.bubble.fill",
            title: "Bid a contract",
            body: "Before play, the auction sets a target. A bid names a level from 1 to 7 and a suit or notrump. The level is how many tricks above six your side promises.",
            tip: "A contract of 4♠ promises 10 tricks with spades as trump."
        ),
        HowToPlayPage(
            id: "htp-points",
            icon: "number.circle.fill",
            title: "Count your strength",
            body: "High-card points help describe a hand: ace 4, king 3, queen 2, jack 1. In a beginner framework, pass below opening strength and open around 13 points.",
            cards: [.s(.ace), .h(.king), .d(.queen), .c(.jack)],
            tip: "A balanced 15 to 17 HCP hand usually opens 1NT."
        ),
        HowToPlayPage(
            id: "htp-roles",
            icon: "person.2.fill",
            title: "Declarer, dummy, defenders",
            body: "The player who first named the contract's denomination becomes declarer. Their partner lays dummy face up after the opening lead. The other partnership defends.",
            tip: "Declarer chooses every card played from dummy."
        ),
        HowToPlayPage(
            id: "htp-ready",
            icon: "checkmark.seal.fill",
            title: "You're ready to train",
            body: "That is the shape of bridge: describe the hand, choose a contract, then plan and play 13 tricks. Each room builds one skill in a few focused minutes."
        ),
    ]

    static func recommendedRoom(forSkillLevel skillLevel: String) -> Room {
        let roomID: String
        switch skillLevel {
        case "basics": roomID = "auction-room"
        case "played": roomID = "declarer-room"
        default: roomID = "card-room"
        }
        return DrillLibrary.rooms.first { $0.id == roomID } ?? DrillLibrary.rooms[0]
    }
}
