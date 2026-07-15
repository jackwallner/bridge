import Foundation

enum PlayContent {
    static let strategyCards: [Flashcard] = [
        Flashcard(
            id: "play-count-winners",
            frontTitle: "Plan before trick one",
            backTitle: "Count sure winners",
            backBody: "In notrump, count tricks you can take without giving up the lead. Then identify the suit that can produce the extra tricks you need."
        ),
        Flashcard(
            id: "play-draw-trump",
            frontTitle: "When should declarer draw trump?",
            backTitle: "When opponents' trumps are the danger",
            backBody: "If your plan does not depend on ruffing losers in the short-trump hand, draw opponents' trumps so they cannot ruff your winners."
        ),
        Flashcard(
            id: "play-established-suit",
            frontTitle: "Lose one to win three",
            frontCards: [.s(.king), .s(.queen), .s(.jack), .s(.ten)],
            backTitle: "Establish a long suit",
            backBody: "The ace may take the first round, but your remaining honors can become winners. Giving up one trick can create several later."
        ),
        Flashcard(
            id: "play-finesse",
            frontTitle: "What is a finesse?",
            frontCards: [.h(.ace), .h(.queen)],
            backTitle: "Play for a missing honor to be well placed",
            backBody: "Lead toward the A-Q and play the queen when the lower hand follows low. It wins when the missing king is before the A-Q hand."
        ),
        Flashcard(
            id: "play-second-hand-low",
            frontTitle: "Defender: second hand low",
            backTitle: "Make declarer guess later",
            backBody: "Playing low in second seat often preserves your honor to capture a later card. It is a guideline, not a rule, but a strong default."
        ),
    ]

    static let scenarios: [PlayScenario] = [
        PlayScenario(
            id: "play-follow-heart",
            situation: "West leads the 7♥. You hold these four cards. Which card is legal?",
            cards: [.s(.ace), .h(.two), .d(.king), .c(.queen)],
            answerIndex: 1,
            reasoning: "You hold a heart, so you must follow suit with the 2♥.",
            tip: "Following suit is mandatory. Winning the trick is not."
        ),
        PlayScenario(
            id: "play-win-cheaply",
            situation: "In notrump, partner leads 4♣. Dummy plays 6♣ and declarer plays 9♣. Which card wins most cheaply?",
            cards: [.c(.ten), .c(.king), .c(.ace)],
            answerIndex: 0,
            reasoning: "The 10♣ beats the 9♣. Save the king and ace for later tricks.",
            tip: "Win with the lowest card that does the job."
        ),
        PlayScenario(
            id: "play-ruff",
            situation: "Hearts are trump. A spade is led and you have no spades. Which card can win the trick?",
            cards: [.h(.two), .d(.ace), .c(.ace), .d(.two)],
            answerIndex: 0,
            reasoning: "Because you are void in spades, you may play a trump. Even the 2♥ beats every non-trump card in the trick.",
            tip: "A low trump outranks a high card in the suit led."
        ),
        PlayScenario(
            id: "play-cash-ace",
            situation: "No trump is in play. You are last to a trick of 10♦, 3♦, K♦. Which card wins?",
            cards: [.d(.ace), .d(.queen), .d(.two)],
            answerIndex: 0,
            reasoning: "The ace is the only card here that beats the king. Play A♦ to win the trick.",
            tip: "Compare only cards in the suit led when there is no trump."
        ),
        PlayScenario(
            id: "play-discard",
            situation: "Clubs are led in notrump and you have no clubs. Which card are you allowed to play?",
            cards: [.s(.two), .h(.four), .d(.six)],
            answerIndex: 0,
            reasoning: "Any card is legal when you cannot follow suit. The 2♠ is a sensible low discard.",
            tip: "A discard cannot win unless it is trump, and notrump has no trump suit."
        ),
    ]
}
