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

    var displayName: String { rawValue.capitalized }
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
        case .jack: return "Jack"
        case .queen: return "Queen"
        case .king: return "King"
        case .ace: return "Ace"
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
    var spokenName: String { "\(rank.spokenName) of \(suit.displayName)" }
    var highCardPoints: Int { rank.highCardPoints }

    var sortKey: Int {
        suit.sortOrder * 20 + (20 - rank.sortOrder)
    }
}

extension Array where Element == BridgeCard {
    var racked: [BridgeCard] { sorted { $0.sortKey < $1.sortKey } }
    var highCardPoints: Int { reduce(0) { $0 + $1.highCardPoints } }
}
