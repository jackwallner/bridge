import Foundation

/// The calls a beginner answer can be after partner's one-level major opening.
enum BiddingCall: String, CaseIterable, Sendable {
    case pass
    case oneSpade
    case oneNotrump
    case twoClubs
    case twoDiamonds
    case twoHearts
    case twoSpades
    case threeHearts
    case threeSpades
    case fourHearts
    case fourSpades

    var displayName: String {
        switch self {
        case .pass: return String(localized: "Pass")
        case .oneSpade: return "1♠"
        case .oneNotrump: return "1NT"
        case .twoClubs: return "2♣"
        case .twoDiamonds: return "2♦"
        case .twoHearts: return "2♥"
        case .twoSpades: return "2♠"
        case .threeHearts: return "3♥"
        case .threeSpades: return "3♠"
        case .fourHearts: return "4♥"
        case .fourSpades: return "4♠"
        }
    }

    /// English labels for authored content, which is looked up by English text.
    var authoredLabel: String { self == .pass ? "Pass" : displayName }

    static func two(_ suit: Suit) -> BiddingCall {
        switch suit {
        case .clubs: return .twoClubs
        case .diamonds: return .twoDiamonds
        case .hearts: return .twoHearts
        case .spades: return .twoSpades
        }
    }

    static func three(_ major: Suit) -> BiddingCall { major == .spades ? .threeSpades : .threeHearts }
    static func four(_ major: Suit) -> BiddingCall { major == .spades ? .fourSpades : .fourHearts }
}

/// Where the auction stands when the player has to call. Every situation is
/// uncontested, and the responder has not passed.
enum BiddingSituation: Hashable, Sendable {
    /// Partner opened one of `major`; the player responds.
    case response(Suit)
    /// The player opened one of `major` and partner raised to two.
    case rebidAfterRaise(Suit)
    /// The player opened 1♥ and partner responded 1♠.
    case rebidAfterOneSpade
    /// The player opened 1♠ and partner responded 1NT.
    case rebidAfterOneNotrump

    static let all: [BiddingSituation] = [
        .response(.hearts), .response(.spades),
        .rebidAfterRaise(.hearts), .rebidAfterRaise(.spades),
        .rebidAfterOneSpade, .rebidAfterOneNotrump,
    ]

    var isResponse: Bool {
        if case .response = self { return true }
        return false
    }

    var prompt: String {
        switch self {
        case .response(.spades): return String(localized: "Partner opens 1♠. What is your response?")
        case .response: return String(localized: "Partner opens 1♥. What is your response?")
        case .rebidAfterRaise(.spades): return String(localized: "You opened 1♠ and partner raised to 2♠. What is your rebid?")
        case .rebidAfterRaise: return String(localized: "You opened 1♥ and partner raised to 2♥. What is your rebid?")
        case .rebidAfterOneSpade: return String(localized: "You opened 1♥ and partner responded 1♠. What is your rebid?")
        case .rebidAfterOneNotrump: return String(localized: "You opened 1♠ and partner responded 1NT. What is your rebid?")
        }
    }

    /// The English prompt, for authored content keyed by English text.
    var authoredPrompt: String {
        switch self {
        case .response(.spades): return "Partner opens 1♠. What is your response?"
        case .response: return "Partner opens 1♥. What is your response?"
        case .rebidAfterRaise(.spades): return "You opened 1♠ and partner raised to 2♠. What is your rebid?"
        case .rebidAfterRaise: return "You opened 1♥ and partner raised to 2♥. What is your rebid?"
        case .rebidAfterOneSpade: return "You opened 1♥ and partner responded 1♠. What is your rebid?"
        case .rebidAfterOneNotrump: return "You opened 1♠ and partner responded 1NT. What is your rebid?"
        }
    }

    /// Every call a player could sensibly pick here, in bidding order.
    var candidates: [BiddingCall] {
        switch self {
        case .response(.spades): return [.pass, .oneNotrump, .twoClubs, .twoDiamonds, .twoHearts, .twoSpades, .threeSpades]
        case .response: return [.pass, .oneSpade, .oneNotrump, .twoClubs, .twoDiamonds, .twoHearts, .threeHearts]
        case .rebidAfterRaise(let major): return [.pass, .three(major), .four(major)]
        case .rebidAfterOneSpade: return [.pass, .oneNotrump, .twoClubs, .twoDiamonds, .twoHearts, .twoSpades]
        case .rebidAfterOneNotrump: return [.pass, .twoClubs, .twoDiamonds, .twoHearts, .twoSpades]
        }
    }

    var roomOrder: Int { BiddingSituation.all.firstIndex(of: self) ?? 0 }
}

/// Responder's first call and opener's first rebid after a one-of-a-major
/// opening, uncontested, in beginner Standard American (SAYC ranges).
///
/// Like `HandGenerator`, it returns nil for anything a beginner table would
/// argue about, so a question only reaches a player when one call is right:
/// game-forcing responding hands (13+, which need conventions such as Jacoby
/// 2NT), a 10-count without support (1NT or a two-level suit), boundary point counts where two ways of counting disagree, 3-card
/// heart support beside four spades, ties between two-level suits, opener's
/// medium and strong hands outside the raise, and two-suited shapes where
/// the order of suits is a matter of style.
enum BiddingEngine {

    typealias Shape = HandGenerator.Shape

    /// High-card points plus one point for every card past four in a suit.
    static func lengthPoints(_ shape: Shape) -> Int {
        shape.highCardPoints + Suit.allCases.reduce(0) { $0 + max(0, shape.length($1) - 4) }
    }

    /// High-card points plus shortness: doubleton 1, singleton 2, void 3.
    static func shortnessPoints(_ shape: Shape) -> Int {
        shape.highCardPoints + Suit.allCases.reduce(0) { total, suit in
            switch shape.length(suit) {
            case 0: return total + 3
            case 1: return total + 2
            case 2: return total + 1
            default: return total
            }
        }
    }

    /// Dummy points for a hand that supports partner's suit: with four or more
    /// trumps a void is 5, a singleton 3, a doubleton 1; with three trumps
    /// 3, 2 and 1.
    static func dummyPoints(_ shape: Shape, trumps: Suit) -> Int {
        let long = shape.length(trumps) >= 4
        return shape.highCardPoints + Suit.allCases.filter { $0 != trumps }.reduce(0) { total, suit in
            switch shape.length(suit) {
            case 0: return total + (long ? 5 : 3)
            case 1: return total + (long ? 3 : 2)
            case 2: return total + 1
            default: return total
            }
        }
    }

    static func call(for cards: [BridgeCard], in situation: BiddingSituation) -> BiddingCall? {
        guard cards.count == 13, Set(cards).count == 13 else { return nil }
        let shape = Shape(cards)
        switch situation {
        case .response(let major): return response(shape, to: major)
        case .rebidAfterRaise(let major): return rebidAfterRaise(cards, shape, major: major)
        case .rebidAfterOneSpade: return rebidAfterOneSpade(cards, shape)
        case .rebidAfterOneNotrump: return rebidAfterOneNotrump(cards, shape)
        }
    }

    // MARK: - Responder

    private static func response(_ shape: Shape, to major: Suit) -> BiddingCall? {
        guard major.isMajor else { return nil }
        let hcp = shape.highCardPoints
        guard hcp <= 12 else { return nil }
        let support = shape.length(major)
        let longest = shape.sortedLengths[0]

        if support >= 3 {
            // Three hearts and four spades: a raise and 1♠ are both taught.
            if major == .hearts, support == 3, shape.length(.spades) >= 4 { return nil }
            let dummy = dummyPoints(shape, trumps: major)
            if (2...5).contains(hcp) && dummy <= 5 { return .pass }
            if (6...9).contains(hcp) && (6...9).contains(dummy) { return .two(major) }
            if support >= 4, (8...11).contains(hcp), dummy == 11 { return .three(major) }
            return nil
        }

        if hcp <= 5 {
            // A long suit tempts some players to respond on four or five
            // points, and a hand with no honors is a trick question.
            guard hcp >= 2, hcp < 4 || longest <= 5 else { return nil }
            // Two five-card suits make some players respond on four or five.
            guard hcp < 4 || shape.sortedLengths[1] < 5 else { return nil }
            return .pass
        }

        if major == .hearts, shape.length(.spades) >= 4 {
            if hcp <= 9 { return .oneSpade }
            let otherLongest = Suit.allCases.filter { $0 != .spades }.map(shape.length).max() ?? 0
            return shape.length(.spades) >= otherLongest ? .oneSpade : nil
        }

        if hcp <= 9 {
            // A six-card suit starts arguments about a later rebid; keep it clean.
            guard longest <= 5 else { return nil }
            return .oneNotrump
        }

        // Ten points sits on the edge of 1NT and a two-level suit; not graded.
        guard hcp >= 11 else { return nil }
        // 11 or 12 without support: a new suit at the two level, forcing.
        // Minors need four cards, hearts over 1♠ need five.
        var options: [Suit] = [.clubs, .diamonds].filter { shape.length($0) >= 4 }
        if major == .spades, shape.length(.hearts) >= 5 { options.append(.hearts) }
        guard let best = options.map(shape.length).max() else { return nil }
        // Four hearts beside a four-card minor over 1♠: some teach 2♥ on four.
        if major == .spades, shape.length(.hearts) == 4, best == 4 { return nil }
        let tied = options.filter { shape.length($0) == best }
        guard tied.count == 1, let suit = tied.first else { return nil }
        return .two(suit)
    }

    // MARK: - Opener

    /// The hand must open the right major by the app's own opening rules, so a
    /// rebid question never rests on an opening the app itself would not make.
    private static func opens(_ cards: [BridgeCard], _ major: Suit) -> Bool {
        HandGenerator.opening(for: cards) == (major == .spades ? .oneSpade : .oneHeart)
    }

    private enum Strength { case minimum, medium, maximum }

    private static func strength(_ points: Int) -> Strength {
        points <= 15 ? .minimum : points <= 18 ? .medium : .maximum
    }

    private static func rebidAfterRaise(_ cards: [BridgeCard], _ shape: Shape, major: Suit) -> BiddingCall? {
        guard opens(cards, major) else { return nil }
        // Plain high-card points and two common ways of revaluing opener's
        // hand must all agree on the range.
        let byLength = strength(lengthPoints(shape))
        guard byLength == strength(shortnessPoints(shape)),
              byLength == strength(shape.highCardPoints) else { return nil }
        // A seven-card suit, or six with a singleton, plays far above its
        // points: many would bid on with a "minimum".
        let shortest = shape.sortedLengths.last ?? 0
        if byLength == .minimum, shape.length(major) >= 7 || (shape.length(major) >= 6 && shortest <= 1) {
            return nil
        }
        switch byLength {
        case .minimum: return .pass
        case .medium: return .three(major)
        case .maximum: return .four(major)
        }
    }

    /// Only minimum openers (12 to 14 high-card points) are graded on a
    /// rebid after a new-suit or 1NT response: stronger hands have jump
    /// rebids and reverses that belong in a later lesson.
    private static func isMinimum(_ shape: Shape) -> Bool {
        shape.highCardPoints <= 14 && lengthPoints(shape) <= 15
    }

    private static func rebidAfterOneSpade(_ cards: [BridgeCard], _ shape: Shape) -> BiddingCall? {
        guard opens(cards, .hearts), isMinimum(shape) else { return nil }
        let hearts = shape.length(.hearts)
        let minors = [Suit.clubs, .diamonds].filter { shape.length($0) >= 4 }
        if shape.length(.spades) >= 4 {
            // With shortness, opener's support points can reach a jump raise.
            return dummyPoints(shape, trumps: .spades) <= 15 ? .twoSpades : nil
        }
        if hearts >= 6 { return minors.isEmpty ? .twoHearts : nil }
        if shape.isBalanced { return .oneNotrump }
        guard minors.count == 1, let minor = minors.first else { return nil }
        return .two(minor)
    }

    private static func rebidAfterOneNotrump(_ cards: [BridgeCard], _ shape: Shape) -> BiddingCall? {
        guard opens(cards, .spades), isMinimum(shape) else { return nil }
        let spades = shape.length(.spades)
        let others = [Suit.clubs, .diamonds, .hearts].filter { shape.length($0) >= 4 }
        if spades >= 6 { return others.isEmpty ? .twoSpades : nil }
        if shape.isBalanced { return .pass }
        guard others.count == 1, let suit = others.first else { return nil }
        return .two(suit)
    }

    // MARK: - Explanations

    /// The coaching line under a graded answer: the facts that decided it.
    /// Each part is a whole localized sentence.
    static func explain(_ cards: [BridgeCard], in situation: BiddingSituation, answer: BiddingCall) -> String {
        let shape = Shape(cards)
        let hcp = shape.highCardPoints
        switch situation {
        case .response(let major):
            return explainResponse(shape, major: major, answer: answer)
        case .rebidAfterRaise(let major):
            let points = lengthPoints(shape)
            let first = String(localized: "\(hcp) high-card points, \(points) counting length. Partner's raise shows about 6 to 10 points and three or more cards in your suit.")
            switch answer {
            case .pass:
                return join([first, String(localized: "With a minimum opening (about 12 to 15 points) game is out of reach, so pass and stop in a partial contract.")])
            case .fourHearts, .fourSpades:
                return join([first, String(localized: "With 19 or more points game is likely even opposite a minimum raise, so bid it: \(answer.displayName).")])
            default:
                return join([first, String(localized: "With a medium opening (about 16 to 18 points) game depends on partner's range. Raise to \(answer.displayName) to invite: partner bids game with the top of the raise.")])
            }
        case .rebidAfterOneSpade:
            let first = String(localized: "\(hcp) high-card points, a minimum opening.")
            switch answer {
            case .twoSpades:
                return join([first, String(localized: "With four spades you have found a fit: raise partner to 2♠. A raise to the two level shows a minimum opening.")])
            case .twoHearts:
                return join([first, String(localized: "No spade fit and six or more hearts, so rebid 2♥. Repeating the suit promises six cards.")])
            case .oneNotrump:
                return join([first, String(localized: "Balanced, with no spade fit and no second suit to show: rebid 1NT, which shows 12 to 14.")])
            default:
                return join([first, String(localized: "No spade fit and only five hearts. Show your minor suit at the two level: \(answer.displayName). It is a cheaper suit than hearts, so partner can still choose between them at the two level.")])
            }
        case .rebidAfterOneNotrump:
            let first = String(localized: "\(hcp) high-card points, a minimum opening. A 1NT response shows 6 to 9 points with fewer than three spades, and partner may pass it.")
            switch answer {
            case .pass:
                return join([first, String(localized: "Balanced and minimum: game is out of reach, so pass and play 1NT.")])
            case .twoSpades:
                return join([first, String(localized: "Six or more spades play better than notrump, even opposite partner's short spades: rebid 2♠.")])
            default:
                return join([first, String(localized: "Unbalanced with a second suit of four or more cards: show it at the two level, \(answer.displayName), so partner can choose between your suits.")])
            }
        }
    }

    private static func explainResponse(_ shape: Shape, major: Suit, answer: BiddingCall) -> String {
        let hcp = shape.highCardPoints
        let support = shape.length(major)
        let suitName = major == .spades ? "1♠" : "1♥"
        switch answer {
        case .pass:
            return String(localized: "\(hcp) high-card points. A response needs about 6 points, so pass partner's \(suitName).")
        case .twoHearts where major == .hearts, .twoSpades where major == .spades:
            let dummy = dummyPoints(shape, trumps: major)
            return join([
                String(localized: "\(support) cards in partner's suit and \(dummy) dummy points: high-card points plus extra for short suits."),
                String(localized: "A simple raise shows support and 6 to 10 points: \(answer.displayName). Supporting partner's major comes first."),
            ])
        case .threeHearts, .threeSpades:
            let dummy = dummyPoints(shape, trumps: major)
            return join([
                String(localized: "\(support) cards in partner's suit and \(dummy) dummy points: high-card points plus extra for short suits."),
                String(localized: "Four or more trumps and about 10 to 11 dummy points make a limit raise: \(answer.displayName). Partner bids game with more than a minimum."),
            ])
        case .oneSpade:
            return join([
                String(localized: "\(hcp) high-card points and \(shape.length(.spades)) spades, with fewer than three hearts."),
                String(localized: "A new suit at the one level needs 6 or more points, and partner must bid again: bid 1♠."),
            ])
        case .oneNotrump:
            return String(localized: "\(hcp) high-card points, fewer than three cards in partner's suit and nothing to show at the one level. 1NT shows 6 to 9, and partner may pass it.")
        default:
            return join([
                String(localized: "\(hcp) high-card points and fewer than three cards in partner's suit."),
                String(localized: "A new suit at the two level needs 10 or more points, and partner must bid again: bid your longest suit, \(answer.displayName)."),
            ])
        }
    }

    private static func join(_ parts: [String]) -> String {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        let separator = language.hasPrefix("ja") || language.hasPrefix("zh") ? "" : " "
        return parts.joined(separator: separator)
    }

    // MARK: - Generation

    struct GeneratedQuestion {
        let situation: BiddingSituation
        let cards: [BridgeCard]
        let answer: BiddingCall
        let choices: [BiddingCall]
        let explanation: String
    }

    private static let fullDeck: [BridgeCard] = Suit.allCases.flatMap { suit in
        Rank.allCases.map { BridgeCard($0, suit) }
    }

    /// Deals until the hand grades as `target` in `situation`.
    static func question<R: RandomNumberGenerator>(
        _ situation: BiddingSituation,
        answer target: BiddingCall,
        attempts: Int = 20000,
        using generator: inout R
    ) -> GeneratedQuestion? {
        for _ in 0..<attempts {
            let cards = Array(fullDeck.shuffled(using: &generator).prefix(13)).racked
            guard call(for: cards, in: situation) == target else { continue }
            return GeneratedQuestion(
                situation: situation,
                cards: cards,
                answer: target,
                choices: choices(for: situation, answer: target, using: &generator),
                explanation: explain(cards, in: situation, answer: target)
            )
        }
        return nil
    }

    /// The answer plus up to three other calls from the situation, in bidding order.
    static func choices<R: RandomNumberGenerator>(
        for situation: BiddingSituation,
        answer: BiddingCall,
        using generator: inout R
    ) -> [BiddingCall] {
        let others = situation.candidates.filter { $0 != answer }.shuffled(using: &generator).prefix(3)
        let picked = Set(others + [answer])
        return situation.candidates.filter { picked.contains($0) }
    }

    /// Each situation's possible answers, as (situation, call) pairs.
    static func targets(responses: Bool) -> [(BiddingSituation, BiddingCall)] {
        let situations = BiddingSituation.all.filter { $0.isResponse == responses }
        return situations.flatMap { situation in
            reachableAnswers(situation).map { (situation, $0) }
        }
    }

    /// The calls the engine can actually grade in a situation.
    static func reachableAnswers(_ situation: BiddingSituation) -> [BiddingCall] {
        switch situation {
        case .response(.spades): return [.pass, .oneNotrump, .twoClubs, .twoDiamonds, .twoHearts, .twoSpades, .threeSpades]
        case .response: return [.pass, .oneSpade, .oneNotrump, .twoClubs, .twoDiamonds, .twoHearts, .threeHearts]
        case .rebidAfterRaise(let major): return [.pass, .three(major), .four(major)]
        case .rebidAfterOneSpade: return [.oneNotrump, .twoClubs, .twoDiamonds, .twoHearts, .twoSpades]
        case .rebidAfterOneNotrump: return [.pass, .twoClubs, .twoDiamonds, .twoHearts, .twoSpades]
        }
    }

    /// A balanced batch: answers drawn in turn, so a rare call is drilled as
    /// often as a common one.
    static func batch<R: RandomNumberGenerator>(responses: Bool, count: Int, using generator: inout R) -> [GeneratedQuestion] {
        var targets: [(BiddingSituation, BiddingCall)] = []
        let all = self.targets(responses: responses)
        while targets.count < count { targets += all.shuffled(using: &generator) }
        return targets.prefix(count).compactMap { situation, call in
            question(situation, answer: call, using: &generator)
        }
    }
}
