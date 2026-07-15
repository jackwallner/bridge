import Foundation

enum CardBasicsContent {
    static let meetTheCards: [Flashcard] = [
        Flashcard(
            id: "basics-four-suits",
            frontTitle: "Four suits",
            frontCards: [.s(.ace), .h(.ace), .d(.ace), .c(.ace)],
            backTitle: "Two majors, two minors",
            backBody: "Spades and hearts are the major suits. Diamonds and clubs are the minor suits. A standard bridge deck has 13 cards in each suit."
        ),
        Flashcard(
            id: "basics-rank-order",
            frontTitle: "Which card is highest?",
            frontCards: [.s(.ace), .s(.king), .s(.queen), .s(.jack)],
            backTitle: "Ace is high",
            backBody: "Within a suit, cards rank A, K, Q, J, 10 down to 2. The ace is normally the highest card."
        ),
        Flashcard(
            id: "basics-hcp",
            frontTitle: "High-card points",
            frontCards: [.h(.ace), .h(.king), .h(.queen), .h(.jack)],
            backTitle: "4, 3, 2, 1",
            backBody: "Ace = 4 points, king = 3, queen = 2, jack = 1. Add those values across your 13 cards to estimate your hand's strength."
        ),
        Flashcard(
            id: "basics-trick",
            frontTitle: "What is a trick?",
            backTitle: "One card from each player",
            backBody: "Each player contributes one card. The highest card of the suit led wins unless a trump is played. The trick winner leads next."
        ),
        Flashcard(
            id: "basics-follow-suit",
            frontTitle: "Must you follow suit?",
            backTitle: "Yes, when you can",
            backBody: "If you hold a card in the suit led, you must play one. Only when you are void in that suit may you discard or play a trump."
        ),
        Flashcard(
            id: "basics-contract",
            frontTitle: "What does 4♠ promise?",
            backTitle: "Ten tricks with spades as trump",
            backBody: "A contract level counts tricks above the first six. Four means 6 + 4 = 10 tricks. The denomination names trump, or NT when there is no trump."
        ),
        Flashcard(
            id: "basics-roles",
            frontTitle: "Declarer and dummy",
            backTitle: "One player controls two hands",
            backBody: "Declarer plays the contract. Declarer's partner becomes dummy after the opening lead, lays all 13 cards face up, and plays the cards declarer calls."
        ),
    ]

    static let cardQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "quiz-hcp-ace",
            prompt: "How many high-card points is an ace worth?",
            choices: ["1", "2", "3", "4"],
            answerIndex: 3,
            explanation: "An ace is worth 4 HCP. Kings are 3, queens 2, and jacks 1."
        ),
        QuizQuestion(
            id: "quiz-major-suits",
            prompt: "Which pair are the major suits?",
            choices: ["Clubs and diamonds", "Hearts and spades", "Spades and clubs", "Hearts and diamonds"],
            answerIndex: 1,
            explanation: "Hearts and spades are the majors. They score 30 points per contracted trick."
        ),
        QuizQuestion(
            id: "quiz-cards-hand",
            prompt: "How many cards does each player receive?",
            choices: ["10", "12", "13", "14"],
            answerIndex: 2,
            explanation: "The 52-card deck is dealt equally, so each of four players receives 13 cards."
        ),
        QuizQuestion(
            id: "quiz-contract-tricks",
            prompt: "How many tricks must declarer take in 3NT?",
            choices: ["3", "6", "9", "10"],
            answerIndex: 2,
            explanation: "Contract levels count above six. 3NT therefore requires 6 + 3 = 9 tricks."
        ),
        QuizQuestion(
            id: "quiz-auction-end",
            prompt: "After a bid, what ends the auction?",
            choices: ["One pass", "Two passes", "Three consecutive passes", "The opening lead"],
            answerIndex: 2,
            explanation: "The auction ends after three consecutive passes. The preceding bid becomes the final contract."
        ),
        QuizQuestion(
            id: "quiz-follow-suit",
            prompt: "A heart is led and you hold a heart. What must you do?",
            choices: ["Play a heart", "Play a trump", "Play your highest card", "Pass"],
            answerIndex: 0,
            explanation: "You must follow the suit led whenever you can. The card need not be high."
        ),
        QuizQuestion(
            id: "quiz-trick-lead",
            prompt: "Who leads to the next trick?",
            choices: ["Declarer", "Dummy", "The dealer", "The previous trick winner"],
            answerIndex: 3,
            explanation: "Whoever wins a trick leads the first card to the next trick."
        ),
        QuizQuestion(
            id: "quiz-bid-order",
            prompt: "Which bid outranks 1♠?",
            choices: ["1♥", "1♦", "1NT", "1♣"],
            answerIndex: 2,
            explanation: "At the same level, bids rank clubs, diamonds, hearts, spades, then notrump."
        ),
    ]
}
