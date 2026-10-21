import Foundation

enum CategoryContent {
    static let openingCards: [Flashcard] = [
        Flashcard(
            id: "bid-open-or-pass",
            frontTitle: "Open or pass?",
            frontSubtitle: "Count your high-card points first",
            backTitle: "Open with 13 or more",
            backBody: "In Standard American (SAYC), open one of a suit with 13 or more points and pass with fewer. A 12 may open by the Rule of 20: add your points to the lengths of your two longest suits, and open if the total is 20 or more."
        ),
        Flashcard(
            id: "bid-one-notrump",
            frontTitle: "The 1NT opening",
            frontSubtitle: "A precise bid",
            backTitle: "15 to 17 HCP, balanced",
            backBody: "Open 1NT with 15 to 17 high-card points and a balanced hand. Balanced means no singleton or void and at most one doubleton: 4-3-3-3, 4-4-3-2 or 5-3-3-2."
        ),
        Flashcard(
            id: "bid-five-card-major",
            frontTitle: "Five-card majors",
            backTitle: "Show hearts or spades",
            backBody: "With opening strength and a five-card major, open that major. The exception is a balanced 15 to 17, which Standard American (SAYC) opens 1NT even with a five-card suit. A minor of six or more cards is longer, so you open that first."
        ),
        Flashcard(
            id: "bid-longest-suit",
            frontTitle: "No five-card major?",
            backTitle: "Open your longer minor",
            backBody: "With opening strength but no five-card major, open your longer minor. With three clubs and three diamonds, open 1♣. With four of each, open 1♦."
        ),
        Flashcard(
            id: "bid-response-ranges",
            frontTitle: "Responder is captain",
            backTitle: "Place your hand in a range",
            backBody: "After partner opens, count your points and support. In Standard American, pass with 0 to 5, respond with 6 or more, and think of 6 to 9 as minimum, 10 to 12 as an invitation to game, and 13 or more as game strength."
        ),
    ]

    static let openingHands: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "hand-pass-10",
            cards: [.s(.queen), .s(.nine), .s(.six), .h(.king), .h(.eight), .h(.four), .d(.jack), .d(.seven), .d(.three), .c(.nine), .c(.six), .c(.four), .c(.two)],
            choices: [.pass, .oneClub, .oneDiamond, .oneNotrump],
            answer: .pass,
            explanation: "This hand has 6 HCP: Q=2, K=3, and J=1. It is well below the 13 you need to open, so pass."
        ),
        HandMatchQuestion(
            id: "hand-one-spade",
            cards: [.s(.ace), .s(.king), .s(.ten), .s(.seven), .s(.three), .h(.queen), .h(.jack), .h(.four), .d(.king), .d(.six), .c(.jack), .c(.five), .c(.two)],
            choices: [.pass, .oneHeart, .oneSpade, .oneNotrump],
            answer: .oneSpade,
            explanation: "This hand has 14 HCP and five spades. Open the five-card major, 1♠."
        ),
        HandMatchQuestion(
            id: "hand-one-heart",
            cards: [.s(.king), .s(.jack), .s(.two), .h(.ace), .h(.queen), .h(.ten), .h(.six), .h(.three), .d(.king), .d(.jack), .d(.four), .c(.seven), .c(.three)],
            choices: [.pass, .oneHeart, .oneSpade, .oneNotrump],
            answer: .oneHeart,
            explanation: "With 14 HCP and five hearts, open 1♥."
        ),
        HandMatchQuestion(
            id: "hand-one-nt-16",
            cards: [.s(.ace), .s(.jack), .s(.seven), .s(.three), .h(.king), .h(.ten), .h(.five), .d(.ace), .d(.eight), .d(.four), .c(.ace), .c(.six), .c(.two)],
            choices: [.oneClub, .oneDiamond, .oneSpade, .oneNotrump],
            answer: .oneNotrump,
            explanation: "This balanced hand has 16 HCP, right in the 15 to 17 range. Open 1NT."
        ),
        HandMatchQuestion(
            id: "hand-one-diamond",
            // Shipped at 14 HCP with an explanation claiming 16, which made
            // the graded answer (1NT) wrong: a balanced 14 opens the longer
            // minor. The queen restores the hand the explanation describes.
            cards: [.s(.ace), .s(.queen), .s(.four), .h(.king), .h(.seven), .h(.three), .d(.ace), .d(.queen), .d(.nine), .d(.six), .c(.jack), .c(.five), .c(.two)],
            choices: [.oneClub, .oneDiamond, .oneHeart, .oneNotrump],
            answer: .oneNotrump,
            explanation: "This balanced hand has 16 HCP, so open the descriptive 1NT rather than a minor."
        ),
        HandMatchQuestion(
            id: "hand-long-diamonds",
            cards: [.s(.ace), .s(.nine), .h(.king), .h(.seven), .h(.four), .d(.ace), .d(.jack), .d(.ten), .d(.six), .d(.three), .c(.queen), .c(.eight), .c(.two)],
            choices: [.oneClub, .oneDiamond, .oneHeart, .oneNotrump],
            answer: .oneDiamond,
            explanation: "This hand has opening strength, five diamonds, and no five-card major. Open the longer minor, 1♦."
        ),
        HandMatchQuestion(
            id: "hand-three-three-minors",
            cards: [.s(.ace), .s(.queen), .s(.eight), .s(.four), .h(.king), .h(.queen), .h(.six), .d(.jack), .d(.seven), .d(.three), .c(.ace), .c(.six), .c(.two)],
            choices: [.oneClub, .oneDiamond, .oneSpade, .oneNotrump],
            answer: .oneNotrump,
            explanation: "This balanced hand has 16 HCP. The 1NT range takes priority over choosing between the minors."
        ),
    ]
}
