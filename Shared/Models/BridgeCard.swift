import Foundation

enum Suit: String, Codable, CaseIterable, Sendable {
    case clubs, diamonds, hearts, spades

    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }

    var displayName: String {
        switch self {
        case .clubs: return String(localized: "Clubs")
        case .diamonds: return String(localized: "Diamonds")
        case .hearts: return String(localized: "Hearts")
        case .spades: return String(localized: "Spades")
        }
    }
    var isMajor: Bool { self == .hearts || self == .spades }

    var sortOrder: Int {
        switch self {
        case .spades: return 0
        case .hearts: return 1
        case .diamonds: return 2
        case .clubs: return 3
        }
    }
}

enum Rank: String, Codable, CaseIterable, Sendable {
    case two = "2", three = "3", four = "4", five = "5", six = "6"
    case seven = "7", eight = "8", nine = "9", ten = "10"
    case jack = "J", queen = "Q", king = "K", ace = "A"

    var sortOrder: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    var spokenName: String {
        switch self {
        case .jack: return String(localized: "Jack")
        case .queen: return String(localized: "Queen")
        case .king: return String(localized: "King")
        case .ace: return String(localized: "Ace")
        default: return rawValue
        }
    }

    var highCardPoints: Int {
        switch self {
        case .ace: return 4
        case .king: return 3
        case .queen: return 2
        case .jack: return 1
        default: return 0
        }
    }
}

struct BridgeCard: Hashable, Codable, Sendable {
    let rank: Rank
    let suit: Suit

    init(_ rank: Rank, _ suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    static func c(_ rank: Rank) -> BridgeCard { BridgeCard(rank, .clubs) }
    static func d(_ rank: Rank) -> BridgeCard { BridgeCard(rank, .diamonds) }
    static func h(_ rank: Rank) -> BridgeCard { BridgeCard(rank, .hearts) }
    static func s(_ rank: Rank) -> BridgeCard { BridgeCard(rank, .spades) }

    var shortLabel: String { "\(rank.rawValue)\(suit.symbol)" }
    var spokenName: String {
        let rank = rank.spokenName
        switch suit {
        case .clubs: return String(localized: "\(rank) of Clubs")
        case .diamonds: return String(localized: "\(rank) of Diamonds")
        case .hearts: return String(localized: "\(rank) of Hearts")
        case .spades: return String(localized: "\(rank) of Spades")
        }
    }
    var highCardPoints: Int { rank.highCardPoints }

    var sortKey: Int {
        suit.sortOrder * 20 + (20 - rank.sortOrder)
    }
}

extension Array where Element == BridgeCard {
    var racked: [BridgeCard] { sorted { $0.sortKey < $1.sortKey } }
    var highCardPoints: Int { reduce(0) { $0 + $1.highCardPoints } }
}

extension Rank {
    /// The one-character form used in compact hand strings ("T" is the ten).
    var handCharacter: Character {
        self == .ten ? "T" : Character(rawValue)
    }

    init?(handCharacter: Character) {
        if handCharacter == "T" { self = .ten; return }
        guard let rank = Rank(rawValue: String(handCharacter)) else { return nil }
        self = rank
    }
}

extension BridgeCard {
    /// A hand written the way bridge players write it: suits in order spades,
    /// hearts, diamonds, clubs, separated by spaces, "T" for the ten and "-"
    /// for a void. "AKJ52 Q84 K6 T93" is a 13-card hand. Authored challenge
    /// content is written this way so a reader can check it against the page.
    /// Returns nil for anything malformed, so a typo fails a test instead of
    /// dealing a broken hand.
    static func parseHand(_ text: String) -> [BridgeCard]? {
        let parts = text.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count == 4 else { return nil }
        var cards: [BridgeCard] = []
        for (part, suit) in zip(parts, [Suit.spades, .hearts, .diamonds, .clubs]) {
            guard part != "-" else { continue }
            for character in part {
                guard let rank = Rank(handCharacter: character) else { return nil }
                cards.append(BridgeCard(rank, suit))
            }
        }
        return Set(cards).count == cards.count ? cards : nil
    }

    /// The reverse of `parseHand`, for explanations and test messages.
    static func handString(_ cards: [BridgeCard]) -> String {
        Suit.allCases.sorted { $0.sortOrder < $1.sortOrder }.map { suit in
            let held = cards.filter { $0.suit == suit }.sorted { $0.rank.sortOrder > $1.rank.sortOrder }
            return held.isEmpty ? "-" : String(held.map(\.rank.handCharacter))
        }.joined(separator: " ")
    }
}

extension Array where Element == BridgeCard {
    /// Cards of one suit, highest first.
    func cards(in suit: Suit) -> [BridgeCard] {
        filter { $0.suit == suit }.sorted { $0.rank.sortOrder > $1.rank.sortOrder }
    }
}
