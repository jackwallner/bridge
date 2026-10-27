import Foundation

/// A suit or notrump, as a bid names it. Ranked low to high, the order the
/// auction uses.
enum Denomination: Int, CaseIterable, Comparable, Sendable {
    case clubs, diamonds, hearts, spades, notrump

    init(_ suit: Suit) {
        switch suit {
        case .clubs: self = .clubs
        case .diamonds: self = .diamonds
        case .hearts: self = .hearts
        case .spades: self = .spades
        }
    }

    var suit: Suit? {
        switch self {
        case .clubs: return .clubs
        case .diamonds: return .diamonds
        case .hearts: return .hearts
        case .spades: return .spades
        case .notrump: return nil
        }
    }

    var symbol: String { suit?.symbol ?? "NT" }

    static func < (lhs: Denomination, rhs: Denomination) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// One call in the auction: a pass or a bid. Responses and contracts are
/// written with the same symbols the cards use.
struct BridgeCall: Hashable, Comparable, Sendable {
    /// 0 means pass.
    let level: Int
    let denomination: Denomination

    static let pass = BridgeCall(level: 0, denomination: .clubs)

    static func bid(_ level: Int, _ suit: Suit) -> BridgeCall {
        BridgeCall(level: level, denomination: Denomination(suit))
    }

    static func notrump(_ level: Int) -> BridgeCall {
        BridgeCall(level: level, denomination: .notrump)
    }

    var isPass: Bool { level == 0 }

    var label: String { isPass ? String(localized: "Pass") : "\(level)\(denomination.symbol)" }

    /// Auction order: a higher level outranks a lower one, and within a level
    /// clubs < diamonds < hearts < spades < notrump.
    static func < (lhs: BridgeCall, rhs: BridgeCall) -> Bool {
        (lhs.level, lhs.denomination) < (rhs.level, rhs.denomination)
    }
}
