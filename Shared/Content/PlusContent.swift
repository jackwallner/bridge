import Foundation

enum PlusContent {
    static let cardExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "plus-card-book",
            prompt: "What does bridge players' word “book” mean?",
            choices: ["The first six tricks", "The auction record", "A convention card", "A score bonus"],
            answerIndex: 0,
            explanation: "Book is the first six tricks. Contract levels name the number of tricks required beyond book."
        ),
        QuizQuestion(
            id: "plus-card-game",
            prompt: "Which is a game contract?",
            choices: ["2♠", "3♦", "3NT", "4♣"],
            answerIndex: 2,
            explanation: "3NT is game. The other common game levels are 4♥, 4♠, 5♣, and 5♦."
        ),
        QuizQuestion(
            id: "plus-card-slam",
            prompt: "How many tricks does a small slam require?",
            choices: ["10", "11", "12", "13"],
            answerIndex: 2,
            explanation: "A level-six contract requires 6 + 6 = 12 tricks. Level seven is a grand slam requiring all 13."
        ),
        QuizQuestion(
            id: "plus-card-dummy",
            prompt: "Who physically plays cards from dummy?",
            choices: ["Dummy alone", "Declarer calls the card", "Either defender", "The director"],
            answerIndex: 1,
            explanation: "Dummy lays the hand face up and plays only the card declarer calls."
        ),
    ]

    static let extraOpeningHands: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "plus-open-spade-six",
            cards: [.s(.ace), .s(.king), .s(.jack), .s(.eight), .s(.five), .s(.two), .h(.queen), .h(.six), .d(.king), .d(.seven), .d(.three), .c(.eight), .c(.four)],
            choices: [.pass, .oneHeart, .oneSpade, .oneNotrump],
            answer: .oneSpade,
            explanation: "Six spades and 14 HCP make 1♠ the clear opening."
        ),
        HandMatchQuestion(
            id: "plus-open-club",
            cards: [.s(.ace), .s(.nine), .s(.four), .h(.king), .h(.seven), .h(.three), .d(.queen), .d(.six), .c(.ace), .c(.jack), .c(.eight), .c(.five), .c(.two)],
            choices: [.oneClub, .oneDiamond, .oneHeart, .oneNotrump],
            answer: .oneClub,
            explanation: "This hand has opening strength, five clubs, and no five-card major. It is not balanced enough for 1NT, so open 1♣."
        ),
        HandMatchQuestion(
            id: "plus-open-heart",
            cards: [.s(.king), .s(.eight), .h(.ace), .h(.king), .h(.ten), .h(.six), .h(.four), .d(.queen), .d(.nine), .d(.five), .c(.jack), .c(.seven), .c(.two)],
            choices: [.oneClub, .oneHeart, .oneSpade, .oneNotrump],
            answer: .oneHeart,
            explanation: "The five-card heart suit and opening strength point to 1♥."
        ),
    ]

    static let extraPlays: [PlayScenario] = [
        PlayScenario(
            id: "plus-play-cover",
            situation: "Declarer leads Q♦ toward dummy. You hold K♦ and play second. Which card follows the guideline “cover an honor with an honor”?",
            cards: [.d(.king), .d(.seven), .d(.two)],
            answerIndex: 0,
            reasoning: "Play K♦. Covering may promote partner's jack or ten into a winner.",
            tip: "The guideline is strongest when partner may hold the next lower honor."
        ),
        PlayScenario(
            id: "plus-play-low-second",
            situation: "Declarer leads 4♣ from hand. You play second with these clubs and dummy has A-J behind you. What is the usual play?",
            cards: [.c(.king), .c(.eight), .c(.two)],
            answerIndex: 2,
            reasoning: "Play low. If you rise with the king, dummy's ace wins and the jack may become good.",
            tip: "Second hand low protects honors that sit in front of dummy."
        ),
        PlayScenario(
            id: "plus-play-unblock",
            situation: "Partner leads A♠ from A-K. You hold a singleton queen. Which card must you play?",
            cards: [.s(.queen)],
            answerIndex: 0,
            reasoning: "Play Q♠ because it is your only spade. It also unblocks the suit so partner can continue cleanly.",
            tip: "Following suit comes before every defensive signal."
        ),
    ]

    static let extraDefense: [Flashcard] = [
        Flashcard(
            id: "plus-defense-top-sequence",
            frontTitle: "Lead from Q-J-10-5",
            frontCards: [.d(.queen), .d(.jack), .d(.ten), .d(.five)],
            backTitle: "Lead the queen",
            backBody: "Lead the top of a touching honor sequence. It describes the holding and avoids giving away a cheap trick.",
            choice: CardChoice("Lead Q♦", "Lead 5♦", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-defense-trump-lead",
            frontTitle: "Declarer plans crossruffs",
            frontSubtitle: "Lead a trump?",
            backTitle: "Yes",
            backBody: "A trump lead can remove dummy's ruffing power and cut down declarer's crossruff.",
            choice: CardChoice("Lead trump", "Avoid trump", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-defense-shortness",
            frontTitle: "Against a suit contract",
            frontSubtitle: "Lead a singleton side suit?",
            backTitle: "Often worth considering",
            backBody: "A singleton can create a ruff when partner gets the lead and returns the suit.",
            choice: CardChoice("Consider it", "Never", answerIndex: 0)
        ),
    ]
}
