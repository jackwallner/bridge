import Foundation

/// Deals a responder's hand after partner opens one of a suit and names the
/// response a beginner Standard American table would make. Same contract as
/// `HandGenerator`: the classifier returns nil for anything arguable, and
/// generation is rejection sampling on top, so a hand only reaches a player
/// when exactly one call is right under the rules written in
/// `.claude/rules/generators.md`.
///
/// The framework (the right hand opponent passes):
/// - 5 or fewer points: pass. 6 to 8 is a minimum response, 10 to 12 invites
///   game. 13 or more is a forcing hand and 9 is a borderline count, so
///   neither is dealt.
/// - Partner opened a major: with three or more cards in it, raise (2M with a
///   minimum, 3M with an invitation and four cards). Otherwise show a four-card
///   spade suit over 1♥, then 1NT with a minimum, then a five-card suit at the
///   two level with an invitation.
/// - Partner opened a minor: show a four-card major first (hearts before
///   spades with equal length), then 1♦ over 1♣ with four diamonds, then raise
///   with five or more cards (a minimum only), else 1NT with a minimum or 2♣
///   over 1♦ with five clubs and an invitation.
/// Shortness (a singleton or void) next to a fit is a splinter or a dummy
/// point question, and a five-card side suit next to a fit is a choice of
/// plans, so those hands are not dealt.
enum ResponseGenerator {

    // MARK: - Classification

    /// The response, or nil when the hand is outside what this app teaches or
    /// is a genuine judgment call.
    static func response(to opening: Suit, hand cards: [BridgeCard]) -> BridgeCall? {
        guard cards.count == 13 else { return nil }
        let shape = HandGenerator.Shape(cards)
        let hcp = shape.highCardPoints
        if hcp >= 13 || hcp == 5 || hcp == 9 { return nil }
        // A void or a seven-card suit is a different kind of hand: it is not
        // what a newer player is learning to respond with.
        guard shape.sortedLengths[0] <= 6, shape.sortedLengths[3] >= 1 else { return nil }
        let fit = shape.length(opening)
        if hcp <= 4 { return fit >= 5 ? nil : .pass }
        let minimum = hcp <= 8
        return opening.isMajor
            ? respondToMajor(opening, shape, minimum: minimum)
            : respondToMinor(opening, shape, minimum: minimum)
    }

    private static func respondToMajor(_ opening: Suit, _ shape: HandGenerator.Shape, minimum: Bool) -> BridgeCall? {
        let fit = shape.length(opening)
        if fit >= 3 {
            let shortness = shape.lengths.values.contains { $0 <= 1 }
            let fiveCardSide = Suit.allCases.contains { $0 != opening && shape.length($0) >= 5 }
            guard !shortness, !fiveCardSide else { return nil }
            if minimum { return .bid(2, opening) }
            return fit >= 4 ? .bid(3, opening) : nil
        }
        if opening == .hearts, shape.length(.spades) >= 4 { return .bid(1, .spades) }
        if minimum { return .notrump(1) }
        guard let suit = onlyLongestSuit(shape, excluding: opening, atLeast: 5) else { return nil }
        return .bid(2, suit)
    }

    private static func respondToMinor(_ opening: Suit, _ shape: HandGenerator.Shape, minimum: Bool) -> BridgeCall? {
        let fit = shape.length(opening)
        let hearts = shape.length(.hearts)
        let spades = shape.length(.spades)
        if hearts >= 4 || spades >= 4 {
            // A big fit for partner's minor next to a four-card major is a
            // choice of plans.
            guard fit < 5 else { return nil }
            let suit: Suit = spades > hearts ? .spades : (hearts > spades ? .hearts : (spades >= 5 ? .spades : .hearts))
            return .bid(1, suit)
        }
        if opening == .clubs, shape.length(.diamonds) >= 4 {
            return fit >= 5 ? nil : .bid(1, .diamonds)
        }
        if fit == 4 { return nil }
        if fit >= 5 { return minimum ? .bid(2, opening) : nil }
        if minimum { return .notrump(1) }
        if opening == .diamonds, shape.length(.clubs) >= 5,
           onlyLongestSuit(shape, excluding: .diamonds, atLeast: 5) == .clubs {
            return .bid(2, .clubs)
        }
        return nil
    }

    /// The single longest suit other than `excluded`, when it has at least
    /// `atLeast` cards and no other suit matches its length.
    private static func onlyLongestSuit(_ shape: HandGenerator.Shape, excluding excluded: Suit, atLeast: Int) -> Suit? {
        let others = Suit.allCases.filter { $0 != excluded }
        guard let longest = others.map({ shape.length($0) }).max(), longest >= atLeast else { return nil }
        let matches = others.filter { shape.length($0) == longest }
        return matches.count == 1 ? matches[0] : nil
    }

    // MARK: - Kinds

    /// What sort of call a response is, so a batch can spread across all of
    /// them and distractors can be drawn from the others.
    enum Kind: CaseIterable, Sendable {
        case pass, simpleRaise, jumpRaise, oneLevelSuit, notrump, twoLevelSuit
    }

    static func kind(of call: BridgeCall, opening: Suit) -> Kind {
        if call.isPass { return .pass }
        if call.denomination == .notrump { return .notrump }
        if call.denomination == Denomination(opening) { return call.level == 2 ? .simpleRaise : .jumpRaise }
        return call.level == 1 ? .oneLevelSuit : .twoLevelSuit
    }

    // MARK: - Generation

    struct GeneratedResponse: Sendable {
        let opening: Suit
        let cards: [BridgeCard]
        let answer: BridgeCall
        /// In auction order, the answer among them.
        let choices: [BridgeCall]
        let explanation: String
        /// Parallel to `choices`: why each wrong call is wrong, nil for the answer.
        let notes: [String?]

        var answerIndex: Int { choices.firstIndex(of: answer) ?? 0 }
        var prompt: String { "Partner opens 1\(opening.symbol) and the next player passes. What is your response?" }
    }

    static func question<R: RandomNumberGenerator>(
        kind target: Kind, using generator: inout R, attempts: Int = 3000
    ) -> GeneratedResponse? {
        let deck = fullDeck
        for _ in 0..<attempts {
            let opening = Suit.allCases.randomElement(using: &generator) ?? .hearts
            let cards = Array(deck.shuffled(using: &generator).prefix(13)).racked
            guard let call = response(to: opening, hand: cards), kind(of: call, opening: opening) == target
            else { continue }
            return build(opening: opening, cards: cards, answer: call, using: &generator)
        }
        return nil
    }

    static func batch(count: Int) -> [GeneratedResponse] {
        var generator = SystemRandomNumberGenerator()
        return batch(count: count, using: &generator)
    }

    static func batch(count: Int, seed: String) -> [GeneratedResponse] {
        var generator = StableSeededGenerator(seed: seed)
        return batch(count: count, using: &generator)
    }

    private static func batch<R: RandomNumberGenerator>(count: Int, using generator: inout R) -> [GeneratedResponse] {
        var kinds: [Kind] = []
        while kinds.count < count { kinds += Kind.allCases.shuffled(using: &generator) }
        let dealt = kinds.prefix(count).compactMap { question(kind: $0, using: &generator) }
        return dealt.shuffled(using: &generator)
    }

    private static let fullDeck: [BridgeCard] = Suit.allCases.flatMap { suit in
        Rank.allCases.map { BridgeCard($0, suit) }
    }

    /// The answer plus three plausible wrong calls, in auction order.
    static func build<R: RandomNumberGenerator>(
        opening: Suit, cards: [BridgeCard], answer: BridgeCall, using generator: inout R
    ) -> GeneratedResponse {
        let wrong = candidates(opening: opening).filter { $0 != answer }
        // One of each other kind first, so the choices are not four versions
        // of the same idea.
        var chosen: [BridgeCall] = []
        let answerKind = kind(of: answer, opening: opening)
        for kind in Kind.allCases.shuffled(using: &generator) where kind != answerKind && chosen.count < 3 {
            if let call = wrong.filter({ self.kind(of: $0, opening: opening) == kind }).randomElement(using: &generator) {
                chosen.append(call)
            }
        }
        for call in wrong.shuffled(using: &generator) where chosen.count < 3 && !chosen.contains(call) {
            chosen.append(call)
        }
        let choices = (chosen + [answer]).sorted()
        return GeneratedResponse(
            opening: opening,
            cards: cards,
            answer: answer,
            choices: choices,
            explanation: explain(opening: opening, cards: cards, answer: answer),
            notes: choices.map { $0 == answer ? nil : whyNot($0, opening: opening, cards: cards, answer: answer) }
        )
    }

    /// Every call a beginner might reach for after 1x, legal in the auction.
    static func candidates(opening: Suit) -> [BridgeCall] {
        var calls: [BridgeCall] = [.pass, .notrump(1), .bid(2, opening), .bid(3, opening)]
        for suit in Suit.allCases where suit != opening {
            if Denomination(suit) > Denomination(opening) { calls.append(.bid(1, suit)) }
            calls.append(.bid(2, suit))
        }
        return calls
    }

    // MARK: - Explanations

    static func explain(opening: Suit, cards: [BridgeCard], answer: BridgeCall) -> String {
        let shape = HandGenerator.Shape(cards)
        let hcp = shape.highCardPoints
        let points = "\(hcp) high-card point\(hcp == 1 ? "" : "s")"
        let fit = shape.length(opening)
        let partner = "partner's \(opening.displayName.lowercased())"
        switch kind(of: answer, opening: opening) {
        case .pass:
            return "\(points) is under the 6 you need to respond. Pass and let partner's opening stand."
        case .simpleRaise:
            return fit >= 5 && !opening.isMajor
                ? "\(points) and \(fit) \(opening.displayName.lowercased()), with no four-card major to show. A raise to \(answer.label) shows 6 to 8 points and long support for partner's minor."
                : "\(points) and \(fit) cards in \(partner). Support a major first: a raise to \(answer.label) shows 6 to 8 points and three or more cards in it."
        case .jumpRaise:
            return "\(points) and \(fit) cards in \(partner). A jump to \(answer.label) shows 10 to 12 points and four-card support, an invitation to game."
        case .oneLevelSuit:
            return oneLevelLine(answer, shape: shape, points: points)
        case .notrump:
            return "\(points), no fit for \(partner), and no suit to bid at the one level. 1NT shows 6 to 8 points and a hand with nothing better to say."
        case .twoLevelSuit:
            let suit = answer.denomination.suit ?? .clubs
            return "\(points) and \(shape.length(suit)) \(suit.displayName.lowercased()), with no fit for \(partner). A new suit at the two level needs about 10 points and a five-card suit, which you have."
        }
    }

    private static func oneLevelLine(_ answer: BridgeCall, shape: HandGenerator.Shape, points: String) -> String {
        guard let suit = answer.denomination.suit else { return "" }
        let length = shape.length(suit)
        var line = "\(points) and \(length) \(suit.displayName.lowercased()). Show a four-card major at the one level before anything else."
        if suit == .diamonds {
            line = "\(points) and \(length) diamonds, with no four-card major. Show your diamonds at the one level."
        } else if shape.length(.hearts) == 4 && shape.length(.spades) == 4 {
            line += " With four of each major, bid hearts first."
        } else if shape.length(.hearts) >= 5 && shape.length(.spades) >= 5 {
            line += " With five of each, bid the spades."
        } else if shape.length(.hearts) >= 4 && shape.length(.spades) >= 4 {
            line += " With two majors, bid the longer one."
        }
        return line
    }

    /// Why a particular wrong call does not fit this hand, written from the
    /// rules the call would need.
    static func whyNot(_ call: BridgeCall, opening: Suit, cards: [BridgeCard], answer: BridgeCall) -> String {
        let shape = HandGenerator.Shape(cards)
        let hcp = shape.highCardPoints
        let fit = shape.length(opening)
        let name = opening.displayName.lowercased()
        switch kind(of: call, opening: opening) {
        case .pass:
            return "Pass is for 5 points or fewer. You hold \(hcp), enough to respond."
        case .notrump:
            if opening.isMajor, fit >= 3 { return "You have \(fit) \(name), so support partner's major instead of bidding notrump." }
            if hcp >= 10 { return "1NT shows only 6 to 8 points. With \(hcp) you have more to say than that." }
            if hcp < 6 { return "1NT needs at least 6 points. You hold \(hcp)." }
            return "You have a better description of this hand than 1NT: a suit to show first."
        case .simpleRaise:
            if opening.isMajor, fit < 3 { return "A raise promises three or more cards in partner's suit. You have \(fit)." }
            if !opening.isMajor, fit < 5 { return "A minor is raised only with five or more cards. You have \(fit)." }
            if hcp >= 10 { return "A simple raise shows 6 to 8 points. With \(hcp) you can invite game." }
            return "Another call describes this hand better."
        case .jumpRaise:
            if hcp < 10 { return "A jump raise invites game with 10 to 12 points. With \(hcp), a simple raise is enough." }
            if fit < 4 { return "A jump raise promises four-card support. You have \(fit)." }
            return "Another call describes this hand better."
        case .oneLevelSuit:
            let suit = call.denomination.suit ?? .spades
            let length = shape.length(suit)
            if length < 4 { return "A new suit at the one level promises four or more cards. You hold \(length) \(suit.displayName.lowercased())." }
            if opening.isMajor, fit >= 3 { return "You have \(fit) \(name), so support partner's major before showing a new suit." }
            return "Another suit comes first: bid the major, hearts before spades when they are the same length."
        case .twoLevelSuit:
            let suit = call.denomination.suit ?? .clubs
            let length = shape.length(suit)
            if hcp < 10 { return "A new suit at the two level needs about 10 points. You hold \(hcp)." }
            if length < 5 { return "A new suit at the two level needs five cards. You hold \(length) \(suit.displayName.lowercased())." }
            if opening.isMajor, fit >= 3 { return "You have \(fit) \(name), so support partner's major before showing a new suit." }
            return "Another call describes this hand better."
        }
    }
}
