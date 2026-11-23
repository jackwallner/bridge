import Foundation

/// An authored "what do you bid next?" question. It keeps the auction and the
/// graded call as data so `BiddingEngineTests` can check every answer against
/// the same engine that grades Endless Practice.
struct BiddingQuestion: Sendable {
    let id: String
    let situation: BiddingSituation
    let cards: [BridgeCard]
    let choices: [BiddingCall]
    let answer: BiddingCall
    let explanation: String

    var quiz: QuizQuestion {
        QuizQuestion(
            id: id,
            prompt: situation.authoredPrompt,
            cards: cards.racked,
            choices: choices.map(\.authoredLabel),
            answerIndex: choices.firstIndex(of: answer) ?? 0,
            explanation: explanation,
            choiceNotes: BiddingEngine.missNotes(choices: choices, answer: answer, in: situation)
        )
    }
}

/// Responding to partner's opening and opener's rebid, the next two steps
/// after the opening bid. Every hand is original; ranges are beginner SAYC.
enum BiddingContent {
    static let responses: [BiddingQuestion] = [
        BiddingQuestion(
            id: "respond-pass-five",
            situation: .response(.hearts),
            cards: [.s(.queen), .s(.eight), .s(.seven), .s(.three), .h(.nine), .h(.two), .d(.jack), .d(.eight), .d(.six), .d(.five), .c(.queen), .c(.seven), .c(.four)],
            choices: [.pass, .oneSpade, .oneNotrump, .twoHearts],
            answer: .pass,
            explanation: "5 high-card points and only two hearts. A response needs about 6 points, so pass."
        ),
        BiddingQuestion(
            id: "respond-simple-raise",
            situation: .response(.hearts),
            cards: [.s(.king), .s(.eight), .s(.four), .h(.queen), .h(.nine), .h(.six), .h(.three), .d(.jack), .d(.seven), .d(.two), .c(.eight), .c(.five), .c(.three)],
            choices: [.pass, .oneSpade, .oneNotrump, .twoHearts],
            answer: .twoHearts,
            explanation: "6 high-card points and four hearts. With support for partner's major, raise first: a simple raise to 2♥ shows 6 to 10 points."
        ),
        BiddingQuestion(
            id: "respond-one-spade",
            situation: .response(.hearts),
            cards: [.s(.king), .s(.jack), .s(.seven), .s(.five), .s(.two), .h(.eight), .h(.four), .d(.queen), .d(.six), .d(.three), .c(.ten), .c(.seven), .c(.four)],
            choices: [.pass, .oneSpade, .oneNotrump, .twoHearts],
            answer: .oneSpade,
            explanation: "6 high-card points, five spades and only two hearts. A new suit at the one level needs just 6 points, and partner must bid again, so bid 1♠."
        ),
        BiddingQuestion(
            id: "respond-spade-over-clubs",
            situation: .response(.hearts),
            cards: [.s(.queen), .s(.ten), .s(.six), .s(.three), .h(.seven), .d(.queen), .d(.eight), .d(.two), .c(.king), .c(.nine), .c(.six), .c(.four), .c(.three)],
            choices: [.pass, .oneSpade, .oneNotrump, .twoClubs],
            answer: .oneSpade,
            explanation: "7 high-card points. The clubs are longer, but 2♣ needs 10 or more points. 1♠ shows your four spades at the one level for just 6."
        ),
        BiddingQuestion(
            id: "respond-two-clubs",
            situation: .response(.hearts),
            cards: [.s(.king), .s(.five), .h(.jack), .h(.four), .d(.ace), .d(.eight), .d(.three), .c(.king), .c(.jack), .c(.nine), .c(.seven), .c(.five), .c(.two)],
            choices: [.oneSpade, .oneNotrump, .twoClubs, .twoHearts],
            answer: .twoClubs,
            explanation: "12 high-card points, six clubs, and only two hearts. With 10 or more you can bid a new suit at the two level: 2♣. Partner must bid again."
        ),
        BiddingQuestion(
            id: "respond-one-notrump",
            situation: .response(.spades),
            cards: [.s(.seven), .s(.three), .h(.king), .h(.jack), .h(.six), .h(.four), .d(.queen), .d(.eight), .d(.five), .d(.two), .c(.king), .c(.nine), .c(.three)],
            choices: [.pass, .oneNotrump, .twoHearts, .twoSpades],
            answer: .oneNotrump,
            explanation: "9 high-card points and only two spades. 2♥ would need 10 or more points, so respond 1NT: 6 to 9 points, and partner may pass it."
        ),
        BiddingQuestion(
            id: "respond-raise-shortness",
            situation: .response(.spades),
            cards: [.s(.jack), .s(.eight), .s(.five), .s(.two), .h(.seven), .d(.king), .d(.nine), .d(.six), .d(.four), .d(.three), .c(.queen), .c(.eight), .c(.two)],
            choices: [.pass, .oneNotrump, .twoSpades, .threeSpades],
            answer: .twoSpades,
            explanation: "6 high-card points and four spades. With a fit, count dummy points, which add extra for short suits: the singleton heart adds 3, making 9. Raise to 2♠."
        ),
        BiddingQuestion(
            id: "respond-limit-raise",
            situation: .response(.spades),
            cards: [.s(.queen), .s(.nine), .s(.six), .s(.four), .h(.ace), .h(.seven), .h(.three), .d(.king), .d(.ten), .d(.eight), .d(.two), .c(.jack), .c(.five)],
            choices: [.oneNotrump, .twoSpades, .threeSpades, .fourSpades],
            answer: .threeSpades,
            explanation: "10 high-card points and four spades. The doubleton club adds 1 dummy point for a total of 11: a limit raise to 3♠. Partner bids game with more than a minimum."
        ),
        BiddingQuestion(
            id: "respond-two-diamonds",
            situation: .response(.spades),
            cards: [.s(.eight), .s(.two), .h(.ace), .h(.six), .d(.king), .d(.queen), .d(.nine), .d(.seven), .d(.four), .c(.king), .c(.eight), .c(.five), .c(.three)],
            choices: [.oneNotrump, .twoClubs, .twoDiamonds, .twoSpades],
            answer: .twoDiamonds,
            explanation: "12 high-card points, five diamonds and four clubs, only two spades. With 10 or more, bid your longest new suit at the two level: 2♦."
        ),
    ]

    static let rebids: [BiddingQuestion] = [
        BiddingQuestion(
            id: "rebid-pass-raise",
            situation: .rebidAfterRaise(.hearts),
            cards: [.s(.king), .s(.seven), .s(.three), .h(.ace), .h(.queen), .h(.nine), .h(.six), .h(.four), .d(.queen), .d(.eight), .d(.five), .c(.queen), .c(.two)],
            choices: [.pass, .threeHearts, .fourHearts],
            answer: .pass,
            explanation: "13 high-card points, a minimum opening. Partner's raise shows 6 to 10, so the two hands hold at most about 24 points. Game needs about 25: pass."
        ),
        BiddingQuestion(
            id: "rebid-invite",
            situation: .rebidAfterRaise(.spades),
            cards: [.s(.ace), .s(.king), .s(.jack), .s(.seven), .s(.five), .h(.king), .h(.four), .d(.ace), .d(.jack), .d(.eight), .d(.three), .c(.five), .c(.two)],
            choices: [.pass, .threeSpades, .fourSpades],
            answer: .threeSpades,
            explanation: "16 high-card points: a medium opening. Game depends on partner's range, so invite with 3♠. Partner bids 4♠ with the top of the raise and passes with less."
        ),
        BiddingQuestion(
            id: "rebid-game",
            situation: .rebidAfterRaise(.hearts),
            cards: [.s(.ace), .s(.five), .h(.ace), .h(.king), .h(.jack), .h(.eight), .h(.four), .d(.king), .d(.queen), .d(.six), .c(.queen), .c(.seven), .c(.three)],
            choices: [.pass, .threeHearts, .fourHearts],
            answer: .fourHearts,
            explanation: "19 high-card points. Even opposite a minimum raise of 6 the hands hold about 25, enough for game, so bid 4♥."
        ),
        BiddingQuestion(
            id: "rebid-raise-spades",
            situation: .rebidAfterOneSpade,
            cards: [.s(.king), .s(.jack), .s(.eight), .s(.four), .h(.ace), .h(.queen), .h(.ten), .h(.six), .h(.three), .d(.king), .d(.five), .c(.seven), .c(.two)],
            choices: [.oneNotrump, .twoClubs, .twoHearts, .twoSpades],
            answer: .twoSpades,
            explanation: "13 high-card points and four spades. Partner's 1♠ promises four, so you have a fit: raise to 2♠. Finding a major fit comes first."
        ),
        BiddingQuestion(
            id: "rebid-one-notrump",
            situation: .rebidAfterOneSpade,
            cards: [.s(.queen), .s(.four), .h(.ace), .h(.jack), .h(.eight), .h(.six), .h(.three), .d(.king), .d(.seven), .d(.two), .c(.king), .c(.jack), .c(.five)],
            choices: [.oneNotrump, .twoClubs, .twoHearts, .twoSpades],
            answer: .oneNotrump,
            explanation: "14 high-card points and a balanced 5-3-3-2 with only two spades. Rebid 1NT to show a balanced minimum of 12 to 14. 2♥ would promise six hearts."
        ),
        BiddingQuestion(
            id: "rebid-six-hearts",
            situation: .rebidAfterOneSpade,
            cards: [.s(.jack), .s(.three), .h(.ace), .h(.king), .h(.jack), .h(.nine), .h(.seven), .h(.four), .d(.queen), .d(.six), .d(.two), .c(.queen), .c(.five)],
            choices: [.oneNotrump, .twoClubs, .twoHearts, .twoSpades],
            answer: .twoHearts,
            explanation: "13 high-card points, six hearts and two spades. No fit for partner and no second suit, so rebid the six-card suit: 2♥."
        ),
        BiddingQuestion(
            id: "rebid-new-minor",
            situation: .rebidAfterOneSpade,
            cards: [.s(.seven), .h(.king), .h(.queen), .h(.eight), .h(.five), .h(.two), .d(.ace), .d(.jack), .d(.six), .c(.king), .c(.jack), .c(.four), .c(.three)],
            choices: [.oneNotrump, .twoClubs, .twoHearts, .twoSpades],
            answer: .twoClubs,
            explanation: "14 high-card points, five hearts, four clubs and a singleton spade. The hand is not balanced, so show the second suit: 2♣. Clubs are cheaper than hearts, so partner can still choose between your suits at the two level."
        ),
        BiddingQuestion(
            id: "rebid-pass-notrump",
            situation: .rebidAfterOneNotrump,
            cards: [.s(.ace), .s(.queen), .s(.eight), .s(.six), .s(.three), .h(.king), .h(.seven), .h(.two), .d(.queen), .d(.nine), .d(.four), .c(.queen), .c(.five)],
            choices: [.pass, .twoClubs, .twoHearts, .twoSpades],
            answer: .pass,
            explanation: "13 high-card points and a balanced 5-3-3-2. Partner's 1NT shows 6 to 9 and does not ask you to bid again. Game is out of reach and the hand suits notrump, so pass."
        ),
        BiddingQuestion(
            id: "rebid-show-hearts",
            situation: .rebidAfterOneNotrump,
            cards: [.s(.king), .s(.queen), .s(.nine), .s(.seven), .s(.four), .h(.ace), .h(.jack), .h(.six), .h(.two), .d(.king), .d(.five), .c(.eight), .c(.three)],
            choices: [.pass, .twoClubs, .twoHearts, .twoSpades],
            answer: .twoHearts,
            explanation: "13 high-card points, five spades and four hearts. Show the hearts with 2♥: partner, who has fewer than three spades, may well hold four hearts."
        ),
        BiddingQuestion(
            id: "rebid-six-spades",
            situation: .rebidAfterOneNotrump,
            cards: [.s(.ace), .s(.queen), .s(.jack), .s(.eight), .s(.five), .s(.two), .h(.king), .h(.four), .d(.nine), .d(.six), .d(.three), .c(.queen), .c(.seven)],
            choices: [.pass, .twoClubs, .twoHearts, .twoSpades],
            answer: .twoSpades,
            explanation: "12 high-card points and six spades. Even opposite partner's short spades, a six-card suit makes a fine trump suit, so rebid 2♠."
        ),
    ]
}
