import Foundation

/// Deals a defender's hand against a contract and names the opening lead a
/// beginner Standard American table agrees on. Same contract as
/// `HandGenerator`: the classifier says nil for anything arguable, and
/// generation is rejection sampling on top.
///
/// The rules (also in `.claude/rules/generators.md`):
/// - Against notrump, lead from your longest suit. It must be a single suit of
///   five or six cards, and no other suit may hold touching honors (A-K, K-Q,
///   Q-J, J-10), or there would be a second good lead. With no touching honors
///   in the long suit lead the fourth best card. With a sequence of three
///   headed by a king, queen or jack (K-Q-J, Q-J-10, J-10-9) lead its top card.
/// - Against a suit contract, lead the top of two touching honors headed by an
///   ace, king or queen in a side suit: the ace from A-K, the king from K-Q,
///   the queen from Q-J. Exactly one suit may have them, no other suit may
///   hold touching honors, and no side suit may be a singleton or void (that is
///   a ruffing lead, a different plan).
enum LeadGenerator {

    enum Contract: Hashable, Sendable {
        case notrump(level: Int)
        case suit(Suit, level: Int)

        var label: String {
            switch self {
            case .notrump(let level): return "\(level)NT"
            case .suit(let suit, let level): return "\(level)\(suit.symbol)"
            }
        }

        var trump: Suit? {
            if case .suit(let suit, _) = self { return suit }
            return nil
        }
    }

    enum Reason: Equatable, Sendable {
        case fourthBest(Suit)
        case topOfSequence(Suit)
        case topOfTouchingHonors(Suit)

        var suit: Suit {
            switch self {
            case .fourthBest(let suit), .topOfSequence(let suit), .topOfTouchingHonors(let suit): return suit
            }
        }
    }

    struct Lead: Equatable, Sendable {
        let card: BridgeCard
        let reason: Reason
    }

    // MARK: - Classification

    static func lead(for cards: [BridgeCard], against contract: Contract) -> Lead? {
        guard cards.count == 13 else { return nil }
        switch contract {
        case .notrump: return notrumpLead(cards)
        case .suit(let trump, _): return suitLead(cards, trump: trump)
        }
    }

    private static func notrumpLead(_ cards: [BridgeCard]) -> Lead? {
        let lengths = Suit.allCases.map { (suit: $0, length: cards.cards(in: $0).count) }
        guard let longest = lengths.map(\.length).max(), (5...6).contains(longest) else { return nil }
        let longSuits = lengths.filter { $0.length == longest }
        guard longSuits.count == 1, let long = longSuits.first?.suit else { return nil }
        let held = cards.cards(in: long)
        for suit in Suit.allCases where suit != long {
            guard !hasTouchingHonors(cards.cards(in: suit)) else { return nil }
        }
        if let top = sequenceTop(held) {
            return Lead(card: top, reason: .topOfSequence(long))
        }
        guard !hasTouchingHonors(held) else { return nil }
        return Lead(card: held[3], reason: .fourthBest(long))
    }

    private static func suitLead(_ cards: [BridgeCard], trump: Suit) -> Lead? {
        let sides = Suit.allCases.filter { $0 != trump }
        guard sides.allSatisfy({ cards.cards(in: $0).count >= 2 }) else { return nil }
        let withCombo = Suit.allCases.filter { topTouchingPair(cards.cards(in: $0)) != nil }
        guard withCombo.count == 1, let suit = withCombo.first, suit != trump else { return nil }
        for other in Suit.allCases where other != suit {
            guard !hasTouchingHonors(cards.cards(in: other)) else { return nil }
        }
        guard let top = topTouchingPair(cards.cards(in: suit)) else { return nil }
        return Lead(card: top, reason: .topOfTouchingHonors(suit))
    }

    /// Two cards in a row that are both honors (A K Q J 10): the suit has a
    /// sequence the defender could lead from.
    static func hasTouchingHonors(_ held: [BridgeCard]) -> Bool {
        zip(held, held.dropFirst()).contains { isTouching($0.rank, $1.rank) }
    }

    private static func isTouching(_ high: Rank, _ low: Rank) -> Bool {
        high.sortOrder - low.sortOrder == 1 && low.sortOrder >= Rank.ten.sortOrder
    }

    /// The top card of the highest pair of touching honors headed by an ace,
    /// king or queen.
    private static func topTouchingPair(_ held: [BridgeCard]) -> BridgeCard? {
        for (high, low) in zip(held, held.dropFirst()) where isTouching(high.rank, low.rank) {
            return high.rank.sortOrder >= Rank.queen.sortOrder ? high : nil
        }
        return nil
    }

    /// The top of three cards in a row headed by a king, queen or jack.
    private static func sequenceTop(_ held: [BridgeCard]) -> BridgeCard? {
        guard held.count >= 3 else { return nil }
        let top = held[0]
        guard (Rank.jack.sortOrder...Rank.king.sortOrder).contains(top.rank.sortOrder) else { return nil }
        let consecutive = top.rank.sortOrder - held[1].rank.sortOrder == 1 && held[1].rank.sortOrder - held[2].rank.sortOrder == 1
        return consecutive ? top : nil
    }

    // MARK: - Generation

    enum Kind: CaseIterable, Sendable {
        case notrumpFourthBest, notrumpSequence, suitSequence
    }

    struct GeneratedLead: Sendable {
        let contract: Contract
        let cards: [BridgeCard]
        let answer: BridgeCard
        /// One card per suit, spades first.
        let choices: [BridgeCard]
        let explanation: String
        let notes: [String?]

        var answerIndex: Int { choices.firstIndex(of: answer) ?? 0 }
        var prompt: String {
            "The opponents reach \(contract.label) and you are on lead. Which card do you lead?"
        }
    }

    private static let fullDeck: [BridgeCard] = Suit.allCases.flatMap { suit in
        Rank.allCases.map { BridgeCard($0, suit) }
    }

    static func question<R: RandomNumberGenerator>(
        kind target: Kind, using generator: inout R, attempts: Int = 40_000
    ) -> GeneratedLead? {
        for _ in 0..<attempts {
            let cards = Array(fullDeck.shuffled(using: &generator).prefix(13)).racked
            let contract = randomContract(for: target, using: &generator)
            guard let found = lead(for: cards, against: contract), kind(of: found, contract: contract) == target,
                  let choices = choices(for: cards, answer: found.card, contract: contract)
            else { continue }
            return GeneratedLead(
                contract: contract,
                cards: cards,
                answer: found.card,
                choices: choices,
                explanation: explain(found, cards: cards, contract: contract),
                notes: choices.map { $0 == found.card ? nil : whyNot($0, cards: cards, lead: found, contract: contract) }
            )
        }
        return nil
    }

    private static func kind(of lead: Lead, contract: Contract) -> Kind {
        switch lead.reason {
        case .fourthBest: return .notrumpFourthBest
        case .topOfSequence: return .notrumpSequence
        case .topOfTouchingHonors: return .suitSequence
        }
    }

    private static func randomContract<R: RandomNumberGenerator>(for kind: Kind, using generator: inout R) -> Contract {
        switch kind {
        case .notrumpFourthBest, .notrumpSequence: return .notrump(level: 3)
        case .suitSequence: return .suit([Suit.hearts, .spades].randomElement(using: &generator) ?? .spades, level: 4)
        }
    }

    static func batch(count: Int) -> [GeneratedLead] {
        var generator = SystemRandomNumberGenerator()
        return batch(count: count, using: &generator)
    }

    static func batch(count: Int, seed: String) -> [GeneratedLead] {
        var generator = StableSeededGenerator(seed: seed)
        return batch(count: count, using: &generator)
    }

    private static func batch<R: RandomNumberGenerator>(count: Int, using generator: inout R) -> [GeneratedLead] {
        var kinds: [Kind] = []
        while kinds.count < count { kinds += Kind.allCases.shuffled(using: &generator) }
        return kinds.prefix(count).compactMap { question(kind: $0, using: &generator) }.shuffled(using: &generator)
    }

    /// One card per suit the defender holds: the answer for its suit, and the
    /// lead a beginner would reach for from each of the others.
    private static func choices(for cards: [BridgeCard], answer: BridgeCard, contract: Contract) -> [BridgeCard]? {
        let picks = Suit.allCases.sorted { $0.sortOrder < $1.sortOrder }.compactMap { suit -> BridgeCard? in
            let held = cards.cards(in: suit)
            guard !held.isEmpty else { return nil }
            if suit == answer.suit { return answer }
            switch held.count {
            case 1, 2: return held[0]
            case 3: return held[2]
            default: return held[3]
            }
        }
        return picks.count >= 3 ? picks : nil
    }

    // MARK: - Explanations

    private static func holding(_ held: [BridgeCard]) -> String {
        held.map(\.rank.rawValue).joined(separator: "-")
    }

    static func explain(_ lead: Lead, cards: [BridgeCard], contract: Contract) -> String {
        let suit = lead.reason.suit
        let held = cards.cards(in: suit)
        switch lead.reason {
        case .fourthBest:
            return "Against \(contract.label) lead your longest suit. You hold \(held.count) \(suit.displayName.lowercased()) with no touching honors, so lead the fourth best card, the \(lead.card.shortLabel). It also tells partner how long the suit is."
        case .topOfSequence:
            return "Against \(contract.label) lead your longest suit. In \(suit.displayName.lowercased()) you hold \(holding(Array(held.prefix(3)))) in a row, so lead the top of the sequence, the \(lead.card.shortLabel). Partner knows you hold the cards just below it."
        case .topOfTouchingHonors:
            let pair = holding(Array(held.prefix(2)))
            return "Lead the top of two touching honors. You hold \(pair) in \(suit.displayName.lowercased()), so lead the \(lead.card.shortLabel). It cannot give away a trick and it tells partner you hold the next card down."
        }
    }

    static func whyNot(_ card: BridgeCard, cards: [BridgeCard], lead: Lead, contract: Contract) -> String {
        let suit = card.suit
        let name = suit.displayName.lowercased()
        let answerSuit = lead.reason.suit.displayName.lowercased()
        switch lead.reason {
        case .fourthBest, .topOfSequence:
            return "\(suit.displayName) is not your longest suit. Against notrump you want to set up the suit you hold the most of, which is your \(answerSuit)."
        case .topOfTouchingHonors:
            if suit == contract.trump {
                return "Leading a trump rarely helps when declarer is happy with trumps. Your \(answerSuit) honors give a safer lead."
            }
            return "Your \(name) has no touching honors, so leading it hands declarer a free card. Lead from your \(answerSuit) honors instead."
        }
    }
}
