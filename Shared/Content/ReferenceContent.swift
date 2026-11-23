import Foundation

/// One look-up term. Kept short: it is read at the table with cards in hand,
/// not studied.
struct GlossaryTerm: Identifiable, Sendable {
    let id: String
    let term: String
    /// Other words a player might search for. Never shown, only matched, so
    /// "HCP" finds high-card points.
    let aliases: [String]
    let group: GlossaryGroup
    let definition: String

    init(id: String, term: String, aliases: [String] = [], group: GlossaryGroup, definition: String) {
        self.id = id
        self.term = term.localizedContent
        self.aliases = aliases
        self.group = group
        self.definition = definition.localizedContent
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return true }
        let haystacks = [term, definition] + aliases
        return haystacks.contains { $0.localizedStandardContains(needle) }
    }
}

enum GlossaryGroup: String, CaseIterable, Identifiable, Sendable {
    case hands
    case bidding
    case scoring
    case play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hands: return String(localized: "Cards and Hands")
        case .bidding: return String(localized: "Bidding")
        case .scoring: return String(localized: "Contracts and Scoring")
        case .play: return String(localized: "The Play")
        }
    }

    var icon: String {
        switch self {
        case .hands: return "rectangle.stack.fill"
        case .bidding: return "megaphone.fill"
        case .scoring: return "number"
        case .play: return "person.2.fill"
        }
    }
}

/// The glossary, in the beginner Standard American framework the drills
/// teach. The wording is original. `ReferenceContentTests` checks every number
/// it quotes against `BridgeRules`, `HandGenerator` and `BiddingEngine`, which
/// grade the drills, so the glossary and the drills never disagree.
enum ReferenceContent {
    static func terms(in group: GlossaryGroup, matching query: String = "") -> [GlossaryTerm] {
        glossary.filter { $0.group == group && $0.matches(query) }
    }

    static let glossary: [GlossaryTerm] = [
        // MARK: Cards and Hands
        GlossaryTerm(
            id: "g-hcp", term: "High-card points", aliases: ["HCP", "points", "strength"], group: .hands,
            definition: "A quick count of strength: ace 4, king 3, queen 2, jack 1. The deck holds 40, so an average hand has 10."
        ),
        GlossaryTerm(
            id: "g-length-points", term: "Length points", aliases: ["distribution", "shape points"], group: .hands,
            definition: "Extra points for long suits: add one for each card past four in a suit. Opener counts them on top of high-card points."
        ),
        GlossaryTerm(
            id: "g-balanced", term: "Balanced hand", aliases: ["flat", "4-3-3-3", "4-4-3-2", "5-3-3-2"], group: .hands,
            definition: "No void, no singleton and at most one doubleton: the shapes 4-3-3-3, 4-4-3-2 and 5-3-3-2."
        ),
        GlossaryTerm(
            id: "g-short", term: "Void, singleton, doubleton", aliases: ["void", "singleton", "doubleton", "shortness"], group: .hands,
            definition: "A suit with no cards, one card or two cards. Short suits help in a trump contract, because you can ruff once you run out."
        ),
        GlossaryTerm(
            id: "g-majors", term: "Majors and minors", aliases: ["major", "minor", "major suit", "minor suit"], group: .hands,
            definition: "Spades and hearts are the majors, clubs and diamonds the minors. Majors score more per trick, so game in a major needs ten tricks and game in a minor eleven."
        ),
        GlossaryTerm(
            id: "g-fit", term: "Fit", aliases: ["eight-card fit", "support"], group: .hands,
            definition: "Eight or more cards in one suit between you and partner. An eight-card fit in a major usually makes the best trump suit."
        ),

        // MARK: Bidding
        GlossaryTerm(
            id: "g-auction", term: "Auction", aliases: ["bidding", "call"], group: .bidding,
            definition: "The bidding, starting with the dealer and going clockwise. Each call is a bid, pass, double or redouble. It ends when a bid is followed by three passes in a row."
        ),
        GlossaryTerm(
            id: "g-opening", term: "Opening bid", aliases: ["open", "opener"], group: .bidding,
            definition: "The first bid of the auction. Most hands with 13 or more high-card points open, and some 12s with good shape."
        ),
        GlossaryTerm(
            id: "g-rule-of-20", term: "Rule of 20", aliases: ["rule of twenty"], group: .bidding,
            definition: "For a borderline hand: add the high-card points to the number of cards in your two longest suits. At 20 or more, open."
        ),
        GlossaryTerm(
            id: "g-five-card-majors", term: "Five-card majors", aliases: ["5-card major"], group: .bidding,
            definition: "Standard American's agreement that an opening 1♥ or 1♠ shows five or more cards in the suit. Without one, open your longer minor."
        ),
        GlossaryTerm(
            id: "g-1nt", term: "1NT opening", aliases: ["one notrump", "notrump opening"], group: .bidding,
            definition: "A balanced hand with 15 to 17 high-card points. It describes the whole hand in one bid."
        ),
        GlossaryTerm(
            id: "g-response", term: "Response", aliases: ["responder", "respond"], group: .bidding,
            definition: "Partner's first bid after an opening. Responder usually needs about 6 points to bid at all."
        ),
        GlossaryTerm(
            id: "g-raise", term: "Raise", aliases: ["support", "simple raise"], group: .bidding,
            definition: "Bidding partner's suit again at a higher level to show support. A simple raise of partner's major shows three or more cards and about 6 to 10 points."
        ),
        GlossaryTerm(
            id: "g-rebid", term: "Rebid", aliases: ["opener's rebid"], group: .bidding,
            definition: "Opener's second bid. It narrows down strength and shape, for example by repeating a six-card suit."
        ),
        GlossaryTerm(
            id: "g-forcing", term: "Forcing bid", aliases: ["forcing", "force"], group: .bidding,
            definition: "A bid partner must not pass. A new suit by an unpassed responder is forcing for one round."
        ),
        GlossaryTerm(
            id: "g-overcall", term: "Overcall", aliases: ["interference", "competitive"], group: .bidding,
            definition: "A bid in a suit or notrump after an opponent has opened."
        ),
        GlossaryTerm(
            id: "g-double", term: "Double", aliases: ["takeout double", "penalty double", "redouble"], group: .bidding,
            definition: "A call that raises the stakes of the last bid. Doubling a low opening bid usually asks partner to pick a suit, a takeout double. Agree with partner which doubles are for penalty."
        ),
        GlossaryTerm(
            id: "g-convention", term: "Convention", aliases: ["Stayman", "Blackwood", "agreement", "artificial"], group: .bidding,
            definition: "An agreed meaning for a bid that says nothing about the suit named, such as Stayman (2♣ over 1NT asks for a four-card major). Partnerships pick their own, so ask before you play."
        ),

        // MARK: Contracts and Scoring
        GlossaryTerm(
            id: "g-contract", term: "Contract", aliases: ["final bid", "level", "strain"], group: .scoring,
            definition: "The last bid of the auction: a level and a trump suit or notrump. Declarer's side must win six tricks plus the level, so 4♥ needs ten tricks."
        ),
        GlossaryTerm(
            id: "g-book", term: "Book", aliases: ["first six tricks"], group: .scoring,
            definition: "The first six tricks, which score nothing. A contract's level counts the tricks after book."
        ),
        GlossaryTerm(
            id: "g-trick-score", term: "Trick score", aliases: ["trick values", "scoring"], group: .scoring,
            definition: "Each contracted trick after book scores 20 in clubs or diamonds and 30 in hearts or spades. In notrump the first scores 40 and each one after it 30."
        ),
        GlossaryTerm(
            id: "g-game", term: "Game", aliases: ["game bonus", "3NT", "4♥", "4♠"], group: .scoring,
            definition: "A contract worth 100 or more in trick score, which earns the game bonus: 3NT, 4♥, 4♠, 5♣ or 5♦."
        ),
        GlossaryTerm(
            id: "g-part-score", term: "Part score", aliases: ["partscore", "partial"], group: .scoring,
            definition: "A contract below game, such as 2♠. Making it earns a bonus of 50."
        ),
        GlossaryTerm(
            id: "g-slam", term: "Slam", aliases: ["small slam", "grand slam"], group: .scoring,
            definition: "A small slam is a contract for twelve tricks, at the six level. A grand slam is all thirteen, at the seven level. Both earn a large extra bonus."
        ),
        GlossaryTerm(
            id: "g-vulnerable", term: "Vulnerable", aliases: ["vulnerability", "not vulnerable"], group: .scoring,
            definition: "A side that is vulnerable earns bigger bonuses and loses more for going down. The game bonus is 500 vulnerable and 300 not vulnerable."
        ),
        GlossaryTerm(
            id: "g-undertrick", term: "Undertrick", aliases: ["down", "going down", "set"], group: .scoring,
            definition: "Each trick declarer falls short of the contract. Undoubled, each one gives the defenders 50 points, or 100 if declarer is vulnerable."
        ),
        GlossaryTerm(
            id: "g-overtrick", term: "Overtrick", aliases: ["extra trick"], group: .scoring,
            definition: "Each trick declarer wins beyond the contract. Undoubled, it scores the same as a trick in the contract."
        ),

        // MARK: The Play
        GlossaryTerm(
            id: "g-trick", term: "Trick", aliases: ["win a trick"], group: .play,
            definition: "One card from each player, played clockwise. The highest card of the suit led wins, unless someone plays a trump."
        ),
        GlossaryTerm(
            id: "g-follow-suit", term: "Follow suit", aliases: ["follow", "revoke"], group: .play,
            definition: "You must play a card of the suit led if you have one. Only when you are out of it may you trump or discard."
        ),
        GlossaryTerm(
            id: "g-trump", term: "Trump", aliases: ["trumps", "trump suit"], group: .play,
            definition: "The suit named in the contract. Any trump beats every card of the other suits."
        ),
        GlossaryTerm(
            id: "g-notrump", term: "Notrump", aliases: ["NT", "no trump"], group: .play,
            definition: "A contract with no trump suit. The highest card of the suit led always wins the trick."
        ),
        GlossaryTerm(
            id: "g-declarer", term: "Declarer", aliases: ["declarer play"], group: .play,
            definition: "The player on the winning side who first bid the contract's suit or notrump. Declarer plays both their own cards and dummy's."
        ),
        GlossaryTerm(
            id: "g-dummy", term: "Dummy", aliases: ["table"], group: .play,
            definition: "Declarer's partner. After the opening lead, dummy lays their cards face up and declarer plays them."
        ),
        GlossaryTerm(
            id: "g-opening-lead", term: "Opening lead", aliases: ["lead", "defense"], group: .play,
            definition: "The first card of the play, from the defender on declarer's left, before dummy is shown."
        ),
        GlossaryTerm(
            id: "g-ruff", term: "Ruff", aliases: ["trumping", "ruffing"], group: .play,
            definition: "Playing a trump on a trick when you are out of the suit led."
        ),
        GlossaryTerm(
            id: "g-discard", term: "Discard", aliases: ["sluff", "pitch"], group: .play,
            definition: "Playing a card of another suit, not a trump, when you are out of the suit led. A discard can't win the trick."
        ),
        GlossaryTerm(
            id: "g-draw-trumps", term: "Draw trumps", aliases: ["pull trumps", "drawing trumps"], group: .play,
            definition: "Leading trumps until the opponents have none left, so they can't ruff your winners."
        ),
        GlossaryTerm(
            id: "g-finesse", term: "Finesse", aliases: ["finessing"], group: .play,
            definition: "Trying to win a trick with a card that is not the highest left, hoping the higher card sits with the opponent who plays before it. Leading toward A-Q and playing the queen is the classic case."
        ),
        GlossaryTerm(
            id: "g-entry", term: "Entry", aliases: ["transportation"], group: .play,
            definition: "A card that can win a trick in a particular hand, so you can lead from that hand next."
        ),
    ]
}
