import Foundation

/// Seats clockwise from North, matching `BridgeRules.auction`'s player index.
enum Seat: Int, Codable, CaseIterable, Sendable {
    case north, east, south, west

    var next: Seat { Seat(rawValue: (rawValue + 1) % 4)! }
    var partner: Seat { Seat(rawValue: (rawValue + 2) % 4)! }
    var isDeclarerSide: Bool { self == .north || self == .south }

    var initial: String {
        switch self {
        case .north: return String(localized: "N", comment: "North seat")
        case .east: return String(localized: "E", comment: "East seat")
        case .south: return String(localized: "S", comment: "South seat")
        case .west: return String(localized: "W", comment: "West seat")
        }
    }
}

/// One of South's calls that the bidding engines can grade.
enum CoachedCall: Sendable {
    case opening
    case rebid(BiddingSituation)
}

/// A card decision for declarer or dummy. `reason` says why the coach's card
/// is right; the notes answer "Why not X?" for a picked card or suit.
struct PlayDecision: Sendable {
    let trick: Int
    let seat: Seat
    let reason: String
    let cardNotes: [BridgeCard: String]
    let suitNotes: [Suit: String]
    /// Plays that work as well as the coach's. They grade right, and the
    /// coach's card is then played so the authored line stays true.
    let alsoFine: Set<BridgeCard>

    init(trick: Int, seat: Seat = .south, reason: String, cardNotes: [String: String] = [:],
         suitNotes: [Suit: String] = [:], alsoFine: [String] = []) {
        self.trick = trick
        self.seat = seat
        self.reason = reason.localizedContent
        self.cardNotes = Dictionary(uniqueKeysWithValues: cardNotes.map { (HandPlayDeal.card($0.key), $0.value.localizedContent) })
        self.suitNotes = suitNotes.mapValues(\.localizedContent)
        self.alsoFine = Set(alsoFine.map(HandPlayDeal.card))
    }

    func note(for card: BridgeCard) -> String? {
        cardNotes[card] ?? suitNotes[card.suit]
    }
}

/// A complete authored deal: four hands, the auction, and all thirteen tricks
/// of the coach's line, each trick listed from its leader clockwise.
struct HandPlayDeal: Identifiable, Sendable {
    let id: String
    let title: String
    let hands: [Seat: [BridgeCard]]
    let dealer: Seat
    let calls: [String]
    /// South's coached calls, by index into `calls`.
    let coachedCalls: [Int: CoachedCall]
    let tricks: [[BridgeCard]]
    let decisions: [PlayDecision]

    init(id: String, title: String, north: String, east: String, south: String, west: String,
         dealer: Seat = .south, calls: [String], coachedCalls: [Int: CoachedCall],
         tricks: [String], decisions: [PlayDecision]) {
        self.id = id
        self.title = title.localizedContent
        hands = [.north: Self.hand(north), .east: Self.hand(east), .south: Self.hand(south), .west: Self.hand(west)]
        self.dealer = dealer
        self.calls = calls
        self.coachedCalls = coachedCalls
        self.tricks = tricks.map { $0.split(separator: " ").map { Self.card(String($0)) } }
        self.decisions = decisions
    }

    var auction: BridgeRules.Auction? { BridgeRules.auction(calls, dealer: dealer.rawValue) }

    /// The trump suit, nil in notrump.
    var trump: Suit? {
        guard let strain = auction?.strain, strain < 4 else { return nil }
        return [Suit.clubs, .diamonds, .hearts, .spades][strain]
    }

    var contractLabel: String {
        guard let auction, auction.level > 0 else { return "" }
        let strain = ["♣", "♦", "♥", "♠", "NT"][auction.strain]
        return "\(auction.level)\(strain)"
    }

    var tricksNeeded: Int { (auction?.level ?? 0) + 6 }

    /// The seat on lead to trick one: declarer's left-hand opponent.
    var openingLeader: Seat {
        Seat(rawValue: ((auction?.declarer ?? Seat.south.rawValue) + 1) % 4)!
    }

    func decision(trick: Int, seat: Seat) -> PlayDecision? {
        decisions.first { $0.trick == trick && $0.seat == seat }
    }

    // MARK: - Parsing

    /// "♠K", "♥10", "♦T": a suit symbol and a rank.
    static func card(_ text: String) -> BridgeCard {
        let suit = suit(text.first!)
        return BridgeCard(rank(String(text.dropFirst())), suit)
    }

    /// "♠AKT64 ♥KQ3 ♦A52 ♣J2", with T for the ten and "-" for a void.
    static func hand(_ text: String) -> [BridgeCard] {
        text.split(separator: " ").flatMap { group -> [BridgeCard] in
            let suit = suit(group.first!)
            return group.dropFirst().filter { $0 != "-" }.map { BridgeCard(rank(String($0)), suit) }
        }
    }

    private static func suit(_ symbol: Character) -> Suit {
        switch symbol {
        case "♠": return .spades
        case "♥": return .hearts
        case "♦": return .diamonds
        default: return .clubs
        }
    }

    private static func rank(_ text: String) -> Rank {
        text == "T" ? .ten : Rank(rawValue: text)!
    }
}

/// How a coached call or card was graded.
enum CoachVerdict: String, Codable, Sendable {
    case right
    case alsoFine
    case miss
}

/// What the coach says after a decision. Strings are already localized.
struct CoachNote: Codable, Equatable, Sendable {
    var verdict: CoachVerdict
    /// The player's call or card, for "Why not X?".
    var pickedLabel: String
    /// The coach's call or card, for the heading.
    var coachLabel: String
    /// "Why not X?": what the player's pick needs or risks, when known.
    var whyNot: String?
    var reason: String
}

/// The state of one hand, Codable so a hand survives the app closing.
struct HandPlayState: Codable, Equatable, Sendable {
    var dealID: String
    var callsMade = 0
    /// The authored line, rewritten when the player picks an equivalent card.
    var line: [[BridgeCard]]
    var cardsPlayed = 0
    var right = 0
    var decided = 0
    /// Set while a graded decision waits for Continue.
    var pending: CoachNote?
}

/// Runs an authored deal: the auction, then thirteen tricks, pausing at each
/// coached decision. Pure value logic so the whole hand is testable.
struct HandPlayEngine: Sendable {
    let deal: HandPlayDeal
    private(set) var state: HandPlayState

    init(deal: HandPlayDeal) {
        self.deal = deal
        state = HandPlayState(dealID: deal.id, line: deal.tricks)
    }

    init?(state: HandPlayState) {
        guard let deal = HandPlayContent.deal(id: state.dealID) else { return nil }
        self.deal = deal
        self.state = state
    }

    enum Phase: Equatable {
        case auction
        case play
        case finished
    }

    var phase: Phase {
        if state.callsMade < deal.calls.count { return .auction }
        return state.cardsPlayed < 52 ? .play : .finished
    }

    // MARK: - Auction

    var callsSoFar: [String] { Array(deal.calls.prefix(state.callsMade)) }

    var nextCaller: Seat { Seat(rawValue: (deal.dealer.rawValue + state.callsMade) % 4)! }

    /// The coached call waiting for the player, if the next call is one.
    var pendingCoachedCall: CoachedCall? {
        guard phase == .auction, state.pending == nil else { return nil }
        return deal.coachedCalls[state.callsMade]
    }

    /// The calls offered at a coached point, as authored labels.
    static func choices(for call: CoachedCall) -> [String] {
        switch call {
        case .opening: return HandCategory.allCases.map(\.auctionCall)
        case .rebid(let situation): return situation.candidates.map(\.auctionCall)
        }
    }

    /// Plays the table's next call. Coached calls wait for `submitCall`.
    mutating func advanceCall() {
        guard phase == .auction, state.pending == nil, deal.coachedCalls[state.callsMade] == nil else { return }
        state.callsMade += 1
    }

    mutating func submitCall(_ call: String) -> CoachNote? {
        guard let coached = pendingCoachedCall else { return nil }
        let answer = deal.calls[state.callsMade]
        let south = deal.hands[.south] ?? []
        let note: CoachNote
        switch coached {
        case .opening:
            guard let answerCategory = HandCategory(auctionCall: answer) else { return nil }
            let picked = HandCategory(auctionCall: call)
            note = CoachNote(
                verdict: call == answer ? .right : .miss,
                pickedLabel: AuctionCallLabel.label(call),
                coachLabel: answerCategory.displayName,
                whyNot: picked.flatMap { HandGenerator.missNote(picked: $0, answer: answerCategory) },
                reason: HandGenerator.explain(south, answer: answerCategory)
            )
        case .rebid(let situation):
            guard let answerCall = BiddingCall(auctionCall: answer) else { return nil }
            let picked = BiddingCall(auctionCall: call)
            note = CoachNote(
                verdict: call == answer ? .right : .miss,
                pickedLabel: AuctionCallLabel.label(call),
                coachLabel: answerCall.displayName,
                whyNot: picked.flatMap { BiddingEngine.missNote(picked: $0, answer: answerCall, in: situation) },
                reason: BiddingEngine.explain(south, in: situation, answer: answerCall)
            )
        }
        grade(note)
        state.callsMade += 1
        return note
    }

    // MARK: - Play

    var trickIndex: Int { state.cardsPlayed / 4 }

    /// The cards on the table in the current trick, from its leader.
    var currentTrick: [BridgeCard] {
        guard phase != .auction else { return [] }
        let start = trickIndex * 4
        let count = state.cardsPlayed - start
        return Array(state.line[min(trickIndex, 12)].prefix(count))
    }

    /// The last finished trick, shown while the next one has no cards yet.
    var lastTrick: [BridgeCard]? {
        guard trickIndex > 0, state.cardsPlayed % 4 == 0 else { return nil }
        return state.line[trickIndex - 1]
    }

    func leader(ofTrick trick: Int) -> Seat {
        trick == 0 ? deal.openingLeader : winner(ofTrick: trick - 1, in: state.line)
    }

    var seatToPlay: Seat {
        let leader = leader(ofTrick: min(trickIndex, 12))
        return Seat(rawValue: (leader.rawValue + state.cardsPlayed % 4) % 4)!
    }

    /// The seat that played each card of `trick`, in order.
    func seats(ofTrick trick: Int) -> [Seat] {
        let leader = leader(ofTrick: trick)
        return (0..<4).map { Seat(rawValue: (leader.rawValue + $0) % 4)! }
    }

    func winner(ofTrick trick: Int, in line: [[BridgeCard]]) -> Seat {
        let leader = trick == 0 ? deal.openingLeader : winner(ofTrick: trick - 1, in: line)
        let index = BridgeRules.winner(line[trick], trump: deal.trump) ?? 0
        return Seat(rawValue: (leader.rawValue + index) % 4)!
    }

    /// Every trick's winner along `line`.
    func winners(_ line: [[BridgeCard]]) -> [Seat] {
        var leader = deal.openingLeader
        return line.map { trick in
            let index = BridgeRules.winner(trick, trump: deal.trump) ?? 0
            leader = Seat(rawValue: (leader.rawValue + index) % 4)!
            return leader
        }
    }

    var declarerTricks: Int {
        winners(state.line).prefix(state.cardsPlayed / 4).filter(\.isDeclarerSide).count
    }

    var defenderTricks: Int { state.cardsPlayed / 4 - declarerTricks }

    /// The cards `seat` still holds.
    func remaining(_ seat: Seat) -> [BridgeCard] {
        let played = Set(playedCards)
        return (deal.hands[seat] ?? []).filter { !played.contains($0) }.racked
    }

    private var playedCards: [BridgeCard] {
        (0..<state.cardsPlayed).map { state.line[$0 / 4][$0 % 4] }
    }

    var legalCards: [BridgeCard] {
        BridgeRules.legal(remaining(seatToPlay), led: currentTrick.first?.suit)
    }

    /// The card the line plays next.
    var coachCard: BridgeCard { state.line[trickIndex][state.cardsPlayed % 4] }

    /// The decision waiting for the player's tap, if the next card is one.
    var pendingDecision: PlayDecision? {
        guard phase == .play, state.pending == nil else { return nil }
        return deal.decision(trick: trickIndex, seat: seatToPlay)
    }

    /// Plays the line's next card. Decisions wait for `submitPlay`.
    mutating func advancePlay() {
        guard phase == .play, state.pending == nil, pendingDecision == nil else { return }
        state.cardsPlayed += 1
    }

    /// True when `card` can replace the coach's card: same hand and suit, and
    /// swapping it with the coach's card leaves every later trick won by the
    /// same seat.
    ///
    /// The authored defenders cannot react to a different card, so a swap
    /// that only works because a defender then fails to beat a card they
    /// could beat is not equivalent: the ♥A in place of a finesse "wins"
    /// both hearts only if East never covers the queen.
    func isLineEquivalent(_ card: BridgeCard) -> Bool {
        guard let swapped = swappedLine(card), winners(swapped) == winners(state.line) else { return false }
        return (trickIndex..<13).allSatisfy { trick in
            !defenderPassesUpWinner(trick: trick, in: swapped) || defenderPassesUpWinner(trick: trick, in: state.line)
        }
    }

    /// True when a defender lets declarer's side win `trick` while holding a
    /// legal card that would have won it.
    func defenderPassesUpWinner(trick: Int, in line: [[BridgeCard]]) -> Bool {
        let earlier = Set(line.prefix(trick).flatMap { $0 })
        let cards = line[trick]
        let seats = seatsOfTrick(trick, in: line)
        for position in 1..<4 where !seats[position].isDeclarerSide {
            let before = Array(cards.prefix(position))
            guard let best = BridgeRules.winner(before, trump: deal.trump), seats[best].isDeclarerSide else { continue }
            let held = (deal.hands[seats[position]] ?? []).filter { !earlier.contains($0) }
            let legal = BridgeRules.legal(held, led: cards[0].suit)
            let couldWin = legal.contains { BridgeRules.winner(before + [$0], trump: deal.trump) == position }
            let didWin = BridgeRules.winner(before + [cards[position]], trump: deal.trump) == position
            if couldWin && !didWin { return true }
        }
        return false
    }

    private func seatsOfTrick(_ trick: Int, in line: [[BridgeCard]]) -> [Seat] {
        let leader = trick == 0 ? deal.openingLeader : winner(ofTrick: trick - 1, in: line)
        return (0..<4).map { Seat(rawValue: (leader.rawValue + $0) % 4)! }
    }

    private func swappedLine(_ card: BridgeCard) -> [[BridgeCard]]? {
        let coach = coachCard
        guard card != coach, card.suit == coach.suit, remaining(seatToPlay).contains(card) else { return nil }
        var line = state.line
        let flat = state.cardsPlayed
        for position in flat..<52 where line[position / 4][position % 4] == card {
            line[position / 4][position % 4] = coach
            line[flat / 4][flat % 4] = card
            return line
        }
        return nil
    }

    mutating func submitPlay(_ card: BridgeCard) -> CoachNote? {
        guard let decision = pendingDecision, legalCards.contains(card) else { return nil }
        let coach = coachCard
        let verdict: CoachVerdict
        if card == coach {
            verdict = .right
        } else if isLineEquivalent(card), let line = swappedLine(card) {
            state.line = line
            verdict = .right
        } else {
            verdict = decision.alsoFine.contains(card) ? .alsoFine : .miss
        }
        let note = CoachNote(
            verdict: verdict,
            pickedLabel: card.shortLabel,
            coachLabel: coach.shortLabel,
            whyNot: verdict == .miss ? decision.note(for: card) : nil,
            reason: decision.reason
        )
        grade(note)
        state.cardsPlayed += 1
        return note
    }

    /// Clears the coach card so the hand moves on.
    mutating func dismissNote() {
        state.pending = nil
    }

    private mutating func grade(_ note: CoachNote) {
        state.decided += 1
        if note.verdict != .miss { state.right += 1 }
        state.pending = note
    }

    /// Declarer's score, not vulnerable.
    var score: Int {
        guard let auction = deal.auction else { return 0 }
        return BridgeRules.score(level: auction.level, strain: auction.strain, tricks: declarerTricks, vulnerable: false)
    }
}

extension HandCategory {
    /// The auction string `BridgeRules.auction` reads.
    var auctionCall: String {
        switch self {
        case .pass: return "P"
        case .oneClub: return "1C"
        case .oneDiamond: return "1D"
        case .oneHeart: return "1H"
        case .oneSpade: return "1S"
        case .oneNotrump: return "1NT"
        }
    }

    init?(auctionCall: String) {
        guard let match = HandCategory.allCases.first(where: { $0.auctionCall == auctionCall }) else { return nil }
        self = match
    }
}

extension BiddingCall {
    var auctionCall: String {
        switch self {
        case .pass: return "P"
        case .oneSpade: return "1S"
        case .oneNotrump: return "1NT"
        case .twoClubs: return "2C"
        case .twoDiamonds: return "2D"
        case .twoHearts: return "2H"
        case .twoSpades: return "2S"
        case .threeHearts: return "3H"
        case .threeSpades: return "3S"
        case .fourHearts: return "4H"
        case .fourSpades: return "4S"
        }
    }

    init?(auctionCall: String) {
        guard let match = BiddingCall.allCases.first(where: { $0.auctionCall == auctionCall }) else { return nil }
        self = match
    }
}

/// Display for an auction string: "1♠", "3NT", "Pass".
enum AuctionCallLabel {
    static func label(_ call: String) -> String {
        switch call {
        case "P": return String(localized: "Pass")
        case "X": return "X"
        case "XX": return "XX"
        default:
            let strain = call.dropFirst()
            let symbol = ["C": "♣", "D": "♦", "H": "♥", "S": "♠", "NT": "NT"][String(strain)] ?? String(strain)
            return "\(call.prefix(1))\(symbol)"
        }
    }
}
