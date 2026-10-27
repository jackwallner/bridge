import Foundation

/// Deals random 13-card hands and names the beginner Standard American opening
/// call for them. This is what makes Endless Practice possible: the opening bid
/// is a deterministic function of points and shape, so the app can author an
/// unlimited supply of "name your opening" questions with a defensible answer
/// and a real explanation, instead of shipping a finite pile of hand-written
/// deals a player exhausts in two sittings.
///
/// It uses SAYC suit choices and the balanced 15 to 17 notrump range. For
/// borderline openings, this trainer uses the Rule of 20 as a conservative
/// selection guideline, not an additional SAYC agreement. With equal length the
/// higher ranking one (4-4 in the minors opens 1♦, 3-3 opens 1♣).
///
/// The classifier deliberately returns nil for anything a beginner Standard
/// American table would argue about (strong 2-club hands, 20-21 balanced,
/// 11-counts, a 12-count outside the Rule of 20, 15-17 balanced holding a
/// five-card major, 4-4-4-1 shapes). Generation is rejection sampling on top
/// of it, so a hand only ever reaches a player if exactly one of the six
/// `HandCategory` answers is right. A drill that grades a judgment call as
/// "wrong" teaches the player to distrust the app.
enum HandGenerator {

    // MARK: - Shape

    /// Suit lengths and the derived facts every rule below asks about.
    struct Shape {
        let lengths: [Suit: Int]
        let highCardPoints: Int

        init(_ cards: [BridgeCard]) {
            var lengths: [Suit: Int] = [:]
            for suit in Suit.allCases {
                lengths[suit] = cards.filter { $0.suit == suit }.count
            }
            self.lengths = lengths
            highCardPoints = cards.highCardPoints
        }

        func length(_ suit: Suit) -> Int { lengths[suit] ?? 0 }

        var sortedLengths: [Int] { lengths.values.sorted(by: >) }

        /// No void, no singleton, at most one doubleton: 4333, 4432, 5332.
        var isBalanced: Bool {
            let doubletons = lengths.values.filter { $0 == 2 }.count
            let short = lengths.values.filter { $0 < 2 }.count
            return short == 0 && doubletons <= 1
        }

        var longestMajor: Suit? {
            let majors = Suit.allCases.filter(\.isMajor)
            guard let best = majors.map({ length($0) }).max(), best >= 5 else { return nil }
            // 5-5 and 6-6 in the majors: open the higher ranking one.
            return length(.spades) == best ? .spades : .hearts
        }

        var hasFiveCardMajor: Bool { longestMajor != nil }

        /// The length of the longer minor, in cards.
        var longestMinorLength: Int { max(length(.clubs), length(.diamonds)) }

        /// 4-4-4-1 has no single longest suit, and SAYC does not say which to open.
        var isFourFourFourOne: Bool { sortedLengths == [4, 4, 4, 1] }

        /// The minor to open when no major is long enough. Equal lengths go
        /// to diamonds except the 3-3 case, which is the classic "short club".
        var longerMinor: Suit {
            let clubs = length(.clubs)
            let diamonds = length(.diamonds)
            if diamonds > clubs { return .diamonds }
            if clubs > diamonds { return .clubs }
            return clubs == 3 ? .clubs : .diamonds
        }

        /// Points plus the two longest suits, a hand-evaluation guideline.
        var ruleOfTwenty: Int {
            let twoLongest = sortedLengths.prefix(2).reduce(0, +)
            return highCardPoints + twoLongest
        }

        /// "5-3-3-2" for the explanation line.
        var pattern: String {
            sortedLengths.map(String.init).joined(separator: "-")
        }
    }

    // MARK: - Classification

    /// The opening call, or nil when the hand is outside the six answers this
    /// app teaches or is a genuine judgment call.
    static func opening(for cards: [BridgeCard]) -> HandCategory? {
        guard cards.count == 13, Set(cards).count == 13 else { return nil }
        let shape = Shape(cards)
        let hcp = shape.highCardPoints

        // Strong hands open 2♣ or 2NT. Neither is an answer here.
        guard hcp < 20 else { return nil }

        if hcp < 12 {
            // Omit long-suit weak hands: SAYC permits a rare weak two with a
            // very good five-card suit. Pass questions have no five-card suit.
            guard hcp <= 10, shape.ruleOfTwenty < 20, shape.sortedLengths[0] <= 4 else { return nil }
            return .pass
        }

        // Conservative training selection, rather than a universal SAYC minimum.
        // A 12 short of the Rule of 20 is not graded.
        guard hcp >= 13 || shape.ruleOfTwenty >= 20 else { return nil }
        guard !shape.isFourFourFourOne else { return nil }

        if (15...17).contains(hcp) && shape.isBalanced {
            // A balanced 15-17 with a five-card major splits the room. Skip it.
            guard !shape.hasFiveCardMajor else { return nil }
            return .oneNotrump
        }

        // The longest suit goes first. A five-card major only gives way to a
        // minor of six or more cards; at equal length the major ranks higher.
        if let major = shape.longestMajor, shape.length(major) >= shape.longestMinorLength {
            return major == .spades ? .oneSpade : .oneHeart
        }

        return shape.longerMinor == .diamonds ? .oneDiamond : .oneClub
    }

    // MARK: - Generation

    /// A dealt hand with its graded answer and a written explanation.
    struct GeneratedHand {
        let cards: [BridgeCard]
        let answer: HandCategory
        let explanation: String
    }

    private static let fullDeck: [BridgeCard] = Suit.allCases.flatMap { suit in
        Rank.allCases.map { BridgeCard($0, suit) }
    }

    /// Deals until the hand classifies as `target`. Targeting the answer first
    /// is what keeps practice balanced: a purely random deal is a Pass more
    /// than half the time, and drilling Pass fifty times teaches nothing.
    static func hand(for target: HandCategory, attempts: Int = 400) -> GeneratedHand? {
        var generator = SystemRandomNumberGenerator()
        return hand(for: target, attempts: attempts, using: &generator)
    }

    static func hand<R: RandomNumberGenerator>(
        for target: HandCategory,
        attempts: Int = 400,
        using generator: inout R
    ) -> GeneratedHand? {
        for _ in 0..<attempts {
            let cards = Array(fullDeck.shuffled(using: &generator).prefix(13)).racked
            guard opening(for: cards) == target else { continue }
            return GeneratedHand(cards: cards, answer: target, explanation: explain(cards, answer: target))
        }
        return nil
    }

    /// A batch of hands spread across the six answers, shuffled. Pass appears
    /// once per cycle like everything else rather than at its natural frequency.
    static func batch(count: Int) -> [GeneratedHand] {
        var generator = SystemRandomNumberGenerator()
        return batch(count: count, using: &generator)
    }

    /// A reproducible batch for a dated shared challenge. The same app build
    /// and seed deal the same original hands on every device, which is what
    /// lets every member answer the same Bridge Minute without a server.
    static func batch(count: Int, seed: String) -> [GeneratedHand] {
        var generator = StableSeededGenerator(seed: seed)
        return batch(count: count, using: &generator)
    }

    private static func batch<R: RandomNumberGenerator>(
        count: Int,
        using generator: inout R
    ) -> [GeneratedHand] {
        var hands: [GeneratedHand] = []
        var targets: [HandCategory] = []
        while targets.count < count {
            targets += HandCategory.allCases.shuffled(using: &generator)
        }
        for target in targets.prefix(count) {
            if let hand = hand(for: target, using: &generator) {
                hands.append(hand)
            }
        }
        return hands.shuffled(using: &generator)
    }

    // MARK: - Explanation

    /// The coaching line under a graded answer. Every branch names the two
    /// facts that decided the call, because "1♠ is correct" on its own is a
    /// score, not a lesson.
    static func explain(_ cards: [BridgeCard], answer: HandCategory) -> String {
        let shape = Shape(cards)
        let hcp = shape.highCardPoints
        let pattern = shape.pattern

        switch answer {
        case .pass:
            return hcp == 1
                ? String(localized: "1 high-card point, \(pattern). With 13 or more points an ordinary one-level opening is routine. Borderline hands need judgment, and this hand has neither the strength nor a long suit for an opening. Pass.")
                : String(localized: "\(hcp) high-card points, \(pattern). With 13 or more points an ordinary one-level opening is routine. Borderline hands need judgment, and this hand has neither the strength nor a long suit for an opening. Pass.")
        case .oneNotrump:
            return String(localized: "\(hcp) high-card points and a balanced \(pattern) with no five-card major. That is the 15 to 17 notrump range, so open 1NT and describe the whole hand in one call.")
        case .oneHeart, .oneSpade:
            return sentences(explainMajor(shape, answer: answer))
        case .oneClub, .oneDiamond:
            return sentences(explainMinor(shape, answer: answer))
        }
    }

    /// Each part is a whole localized sentence. Japanese and Chinese run
    /// sentences together without a space.
    private static func sentences(_ parts: [String]) -> String {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        let separator = language.hasPrefix("ja") || language.hasPrefix("zh") ? "" : " "
        return parts.joined(separator: separator)
    }

    /// Only a 12 needs the Rule of 20 spelled out; 13 or more is plain strength.
    private static func strengthNote(_ shape: Shape) -> [String] {
        guard shape.highCardPoints == 12 else { return [] }
        return [String(localized: "Twelve points with this shape meet the Rule of 20 guideline: points plus your two longest suits make \(shape.ruleOfTwenty).")]
    }

    private static func explainMajor(_ shape: Shape, answer: HandCategory) -> [String] {
        let hcp = shape.highCardPoints
        let suit: Suit = answer == .oneSpade ? .spades : .hearts
        let length = shape.length(suit)
        var lines = [suit == .spades
            ? String(localized: "\(hcp) high-card points with \(length) spades.")
            : String(localized: "\(hcp) high-card points with \(length) hearts.")]
        lines += strengthNote(shape)
        lines.append(String(localized: "Open your longest suit, a five-card major: \(answer.displayName)."))
        let spades = shape.length(.spades)
        let hearts = shape.length(.hearts)
        if spades >= 5 && hearts >= 5 {
            lines.append(spades == hearts
                ? String(localized: "Holding the same length in both majors, start with the higher ranking suit.")
                : String(localized: "Holding both majors, start with the longer one."))
        } else if shape.longestMinorLength == length {
            lines.append(String(localized: "With a minor of the same length, start with the higher ranking suit."))
        }
        return lines
    }

    private static func explainMinor(_ shape: Shape, answer: HandCategory) -> [String] {
        let hcp = shape.highCardPoints
        let pattern = shape.pattern
        if shape.hasFiveCardMajor {
            return [String(localized: "\(hcp) high-card points, \(pattern). Your minor is longer than your five-card major, and Standard American opens the longest suit first, so open \(answer.displayName).")]
                + strengthNote(shape)
                + [String(localized: "Show the major on your next bid.")]
        }
        var lines = [shape.isBalanced && (15...17).contains(hcp) == false
            ? String(localized: "\(hcp) high-card points, \(pattern), no five-card major and outside the 15 to 17 notrump range.")
            : String(localized: "\(hcp) high-card points, \(pattern), no five-card major.")]
        lines += strengthNote(shape)
        lines.append(String(localized: "Open your longer minor: \(answer.displayName)."))
        if shape.length(.clubs) == shape.length(.diamonds) {
            lines.append(shape.length(.clubs) == 3
                ? String(localized: "With three of each minor the convention is the short club.")
                : String(localized: "With equal length in the minors, open the higher ranking one."))
        }
        return lines
    }
}
