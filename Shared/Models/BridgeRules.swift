import Foundation

/// WBF Laws 16, 18, 19, 22, 44 and 77. Strains are C, D, H, S, NT (0...4).
enum BridgeRules {
    static func legal(_ hand: [BridgeCard], led: Suit?) -> [BridgeCard] {
        let following = hand.filter { $0.suit == led }
        return following.isEmpty ? hand : following
    }

    static func winner(_ trick: [BridgeCard], trump: Suit?) -> Int? {
        guard let lead = trick.first else { return nil }
        return trick.indices.max {
            strength(trick[$0], led: lead.suit, trump: trump) < strength(trick[$1], led: lead.suit, trump: trump)
        }
    }

    private static func strength(_ card: BridgeCard, led: Suit, trump: Suit?) -> Int {
        let group = card.suit == trump ? 2 : card.suit == led ? 1 : 0
        return group * 20 + (group == 0 ? 0 : card.rank.sortOrder)
    }

    /// Declarer's duplicate board score, including overtricks and bonuses.
    static func score(level: Int, strain: Int, multiplier: Int = 1, tricks: Int, vulnerable: Bool) -> Int {
        if level == 0 { return 0 }
        let difference = tricks - level - 6
        if difference < 0 {
            let down = -difference
            if multiplier == 1 { return -down * (vulnerable ? 100 : 50) }
            let penalty = vulnerable ? 200 + (down - 1) * 300
                : 100 + min(down - 1, 2) * 200 + max(down - 3, 0) * 300
            return -penalty * (multiplier / 2)
        }
        let unit = strain < 2 ? 20 : 30
        let contracted = (level * unit + (strain == 4 ? 10 : 0)) * multiplier
        let bonus = contracted >= 100 ? (vulnerable ? 500 : 300) : 50
        let insult = multiplier == 1 ? 0 : 50 * (multiplier / 2)
        let over = multiplier == 1 ? difference * unit : difference * (vulnerable ? 200 : 100) * (multiplier / 2)
        let slam = level == 6 ? (vulnerable ? 750 : 500) : level == 7 ? (vulnerable ? 1500 : 1000) : 0
        return contracted + bonus + insult + over + slam
    }

    struct Auction {
        var ended = false
        var level = 0
        var strain = 0
        var multiplier = 1
        var declarer: Int?
        var nextPlayer = 0
    }

    /// A teaching auction parser. P, X, XX and bids such as 1C or 3NT.
    /// Invalid calls return nil without inventing a contract.
    static func auction(_ calls: [String], dealer: Int = 0) -> Auction? {
        var result = Auction(nextPlayer: dealer)
        var bidder: Int?
        var firstBidder: [Int: Int] = [:]
        var passes = 0
        for call in calls {
            guard !result.ended else { return nil }
            let player = result.nextPlayer
            if call == "P" {
                passes += 1
                result.ended = passes == (bidder == nil ? 4 : 3)
            } else if call == "X" || call == "XX" {
                guard let bidder else { return nil }
                let opponent = player % 2 != bidder % 2
                guard (call == "X" && opponent && result.multiplier == 1)
                    || (call == "XX" && !opponent && result.multiplier == 2) else { return nil }
                result.multiplier *= 2
                passes = 0
            } else {
                guard let level = call.first.flatMap({ Int(String($0)) }), (1...7).contains(level),
                      let strain = ["C", "D", "H", "S", "NT"].firstIndex(of: String(call.dropFirst())),
                      level * 5 + strain > result.level * 5 + result.strain else { return nil }
                result.level = level
                result.strain = strain
                result.multiplier = 1
                bidder = player
                let key = player % 2 * 5 + strain
                if firstBidder[key] == nil { firstBidder[key] = player }
                result.declarer = firstBidder[key]
                passes = 0
            }
            result.nextPlayer = (player + 1) % 4
        }
        return result
    }
}
