import Foundation

/// Content added in 1.1. Kept in its own file rather than appended inline so
/// it stays obvious which questions shipped when, and so the 1.0 sets can be
/// read as they were authored.
///
/// Everything here is original teaching material for a beginner Standard
/// American framework. Where a call is a partnership agreement rather than a
/// rule, the explanation says so.
enum MoreContent {

    // MARK: - The Card Room (Bridge+ extras)

    static let cardExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "more-card-trump",
            prompt: "In a suit contract, when may you play a trump instead of following suit?",
            choices: [
                "Whenever you want to win the trick",
                "Only when you are void in the suit led",
                "Only when you are declarer",
                "Only on the first trick"
            ],
            answerIndex: 1,
            explanation: "Following suit comes first. You may ruff only when you hold no cards in the suit led."
        ),
        QuizQuestion(
            id: "more-card-honors",
            prompt: "Which cards are the honors in a suit?",
            choices: ["Ace through jack", "Ace through ten", "Ace, king, queen", "Face cards only"],
            answerIndex: 1,
            explanation: "The five honors are ace, king, queen, jack, and ten. Only the top four carry high-card points."
        ),
        QuizQuestion(
            id: "more-card-opening-lead",
            prompt: "Who makes the opening lead?",
            choices: [
                "Declarer",
                "The player to declarer's left",
                "Dummy's partner",
                "Whoever bid last"
            ],
            answerIndex: 1,
            explanation: "The defender on declarer's left leads to the first trick, before dummy comes down."
        ),
        QuizQuestion(
            id: "more-card-notrump-tricks",
            prompt: "How many tricks does 3NT require?",
            choices: ["Three", "Six", "Nine", "Ten"],
            answerIndex: 2,
            explanation: "Contract level plus book: 3 + 6 = 9 tricks, with no trump suit in play."
        ),
        QuizQuestion(
            id: "more-card-follow-suit",
            prompt: "You hold two hearts and a heart is led. What must you do?",
            choices: [
                "Play a heart",
                "Play your highest card",
                "Discard if you cannot win",
                "Anything you like"
            ],
            answerIndex: 0,
            explanation: "You must follow suit whenever you hold the suit led. Which heart you choose is up to you."
        ),
    ]

    // MARK: - The Auction Room (Bridge+ extras)

    static let openingHands: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "more-open-pass",
            cards: [.s(.queen), .s(.seven), .s(.four),
                    .h(.jack), .h(.nine), .h(.six), .h(.three),
                    .d(.king), .d(.eight), .d(.five),
                    .c(.ten), .c(.four), .c(.two)],
            choices: [.pass, .oneClub, .oneDiamond, .oneHeart],
            answer: .pass,
            explanation: "Six high-card points and no long suit. You need about 12 to open at the one level, so pass."
        ),
        HandMatchQuestion(
            id: "more-open-notrump",
            cards: [.s(.ace), .s(.queen), .s(.six),
                    .h(.king), .h(.nine), .h(.four),
                    .d(.queen), .d(.jack), .d(.seven), .d(.two),
                    .c(.king), .c(.eight), .c(.three)],
            choices: [.oneClub, .oneDiamond, .oneNotrump, .oneSpade],
            answer: .oneNotrump,
            explanation: "Fifteen points, balanced 4-3-3-3, and no five-card major. That is the 1NT range exactly."
        ),
        HandMatchQuestion(
            id: "more-open-diamond",
            cards: [.s(.king), .s(.nine), .s(.four),
                    .h(.queen), .h(.eight), .h(.three),
                    .d(.ace), .d(.jack), .d(.seven), .d(.five),
                    .c(.king), .c(.six), .c(.two)],
            choices: [.oneClub, .oneDiamond, .oneNotrump, .pass],
            answer: .oneDiamond,
            explanation: "Thirteen points and no five-card major, but too weak for 1NT. Open your longer minor, 1♦."
        ),
        HandMatchQuestion(
            id: "more-open-heart-six",
            cards: [.s(.queen), .s(.five),
                    .h(.ace), .h(.king), .h(.jack), .h(.nine), .h(.six), .h(.three),
                    .d(.king), .d(.seven), .d(.four),
                    .c(.eight), .c(.two)],
            choices: [.oneClub, .oneDiamond, .oneHeart, .oneSpade],
            answer: .oneHeart,
            explanation: "Thirteen points with a six-card heart suit. Open the major and tell partner about the length straight away."
        ),
    ]

    // MARK: - The Declarer Room (Bridge+ extras)

    static let plays: [PlayScenario] = [
        PlayScenario(
            id: "more-play-draw-trumps",
            situation: "You are in 4♠ with no side-suit shortness and plenty of trumps. What is usually the first job?",
            cards: [.s(.ace), .s(.king), .s(.queen)],
            answerIndex: 0,
            reasoning: "Start drawing trumps with the ace. Leaving trumps outstanding invites a defender to ruff one of your winners.",
            tip: "Delay drawing trumps only when you need dummy's trumps for ruffing first."
        ),
        PlayScenario(
            id: "more-play-count-winners",
            situation: "In a notrump contract, what should you do before playing to trick one?",
            cards: [.h(.ace), .h(.king), .d(.ace)],
            answerIndex: 0,
            reasoning: "Count your sure winners first, then work out where the extra tricks will come from. The ace here is a winner you can already count.",
            tip: "In notrump count winners. In a suit contract count losers."
        ),
        PlayScenario(
            id: "more-play-entry",
            situation: "Dummy holds a long solid club suit but only one outside entry. Which card do you protect?",
            cards: [.s(.ace), .c(.king), .c(.queen)],
            answerIndex: 0,
            reasoning: "Protect the outside ace. Without an entry the established clubs are unreachable and the whole plan collapses.",
            tip: "A long suit is worth nothing if you cannot get to it."
        ),
        PlayScenario(
            id: "more-play-ruff-in-dummy",
            situation: "You are in 4♥ holding three small diamonds while dummy has a singleton diamond and three trumps. Where do the extra tricks come from?",
            cards: [.d(.six), .h(.four), .h(.three)],
            answerIndex: 1,
            reasoning: "Ruff diamonds in dummy with the small trumps. Dummy's shortness is what turns losers into winners.",
            tip: "Ruff in the hand with the fewer trumps, so you keep enough to draw the opponents'."
        ),
    ]

    // MARK: - The Defense Room

    /// Free. The Defense Room shipped with a single drill, which made it the
    /// thinnest door on Home; a free quiz alongside the judgment cards gives
    /// it the same shape as every other room.
    static let defenseQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "more-defense-fourth-best",
            prompt: "Against notrump you lead your longest suit. From K-9-7-4-2, which card is the standard lead?",
            choices: ["K♠", "9♠", "4♠", "2♠"],
            answerIndex: 2,
            explanation: "Without a strong sequence, lead fourth best from the top: the four. It tells partner about your length as well as your suit."
        ),
        QuizQuestion(
            id: "more-defense-partner-suit",
            prompt: "Partner overcalled hearts during the auction. What is a reasonable opening lead?",
            choices: [
                "A trump",
                "Your own longest suit",
                "A heart",
                "A singleton in any suit"
            ],
            answerIndex: 2,
            explanation: "Partner told you where their strength is. Leading their suit is usually the friendliest start, unless you have a strong reason of your own."
        ),
        QuizQuestion(
            id: "more-defense-third-hand",
            prompt: "Partner leads a small card and dummy plays low. As third hand, what is the general rule?",
            choices: ["Play low", "Play high", "Play your second highest", "Always play an ace"],
            answerIndex: 1,
            explanation: "Third hand high. You are trying to win the trick or force out a high card, since dummy has already passed on it."
        ),
        QuizQuestion(
            id: "more-defense-ace-lead",
            prompt: "Why is leading an unsupported ace against a suit contract usually a poor choice?",
            choices: [
                "It is against the rules",
                "It can crash partner's king",
                "It gives up control and may set up declarer's king",
                "Aces cannot be led at trick one"
            ],
            answerIndex: 2,
            explanation: "Leading an ace with no king behind it gives away a trick and hands declarer a free winner. Save it to capture something."
        ),
        QuizQuestion(
            id: "more-defense-count",
            prompt: "What does it mean to give partner count?",
            choices: [
                "Announcing your points aloud",
                "Playing cards in an order that shows how many you hold",
                "Counting declarer's tricks",
                "Doubling for penalty"
            ],
            answerIndex: 1,
            explanation: "Playing high then low usually shows an even number of cards, low then high an odd number. Partnerships agree on this in advance."
        ),
    ]

    /// Bridge+ extras for the Defense Room.
    static let defenseExtras: [Flashcard] = [
        Flashcard(
            id: "more-defense-interior",
            frontTitle: "Lead from K-J-10-6",
            frontCards: [.h(.king), .h(.jack), .h(.ten), .h(.six)],
            backTitle: "Lead the jack",
            backBody: "This is an interior sequence. The jack is safe, describes the holding to partner, and keeps the king guarding the suit.",
            choice: CardChoice("Lead J♥", "Lead K♥", answerIndex: 0)
        ),
        Flashcard(
            id: "more-defense-doubleton",
            frontTitle: "Lead from 8-3",
            frontCards: [.c(.eight), .c(.three)],
            backTitle: "Lead the eight",
            backBody: "Top of a doubleton. Following with the three next time shows partner the suit was two cards long and may set up a ruff.",
            choice: CardChoice("Lead 8♣", "Lead 3♣", answerIndex: 0)
        ),
        Flashcard(
            id: "more-defense-through-strength",
            frontTitle: "Dummy's strength sits on your left",
            frontSubtitle: "Lead through it?",
            backTitle: "Yes, lead through strength",
            backBody: "Leading through dummy's honors means declarer has to commit before partner plays. The old phrase is lead through strength, up to weakness.",
            choice: CardChoice("Lead through", "Lead around", answerIndex: 0)
        ),
        Flashcard(
            id: "more-defense-passive",
            frontTitle: "Declarer bid confidently to a thin game",
            frontSubtitle: "Attack, or lead passively?",
            backTitle: "Lead passively",
            backBody: "When declarer sounds stretched, the tricks are often already there for you. A quiet lead avoids handing over the one trick they were missing.",
            choice: CardChoice("Lead passively", "Attack hard", answerIndex: 0)
        ),
        Flashcard(
            id: "more-defense-signal-discard",
            frontTitle: "You must discard and want a diamond back",
            frontSubtitle: "Which diamond do you throw?",
            backTitle: "Throw a high diamond",
            backBody: "A high spot card is the standard encouraging signal. Partnerships vary, so agree your discard method before you sit down.",
            choice: CardChoice("A high one", "A low one", answerIndex: 0)
        ),
    ]

    // MARK: - The Master Tables

    static let defensiveSignals: [QuizQuestion] = [
        QuizQuestion(
            id: "more-pro-attitude",
            prompt: "Partner leads the ace and you hold Q-8-4. Playing standard signals, which card encourages a continuation?",
            choices: ["Q", "8", "4", "Any of them"],
            answerIndex: 1,
            explanation: "The eight is your highest spare card and reads as encouraging. The queen is too valuable to throw and the four discourages."
        ),
        QuizQuestion(
            id: "more-pro-suit-preference",
            prompt: "You are giving partner a ruff and want them to return the higher of the two remaining side suits. What do you lead for the ruff?",
            choices: [
                "Your highest card in the ruffed suit",
                "Your lowest card in the ruffed suit",
                "A trump",
                "It cannot be shown"
            ],
            answerIndex: 0,
            explanation: "Suit preference: a high card asks for the higher-ranking side suit, a low card for the lower. It is one of the most useful agreements in defense."
        ),
        QuizQuestion(
            id: "more-pro-uppercut",
            prompt: "What is an uppercut in defense?",
            choices: [
                "Doubling a slam",
                "Ruffing high to force declarer to overruff with an honor",
                "Leading a trump at trick one",
                "Discarding a winner"
            ],
            answerIndex: 1,
            explanation: "Ruffing with a card declarer must beat can promote a trump trick for partner. Losing your ruff to gain a bigger trick is the whole idea."
        ),
        QuizQuestion(
            id: "more-pro-count-declarer",
            prompt: "Declarer has shown five spades and four hearts and follows to two rounds of clubs. How many diamonds do they hold?",
            choices: ["One", "Two", "Three", "Cannot be known"],
            answerIndex: 1,
            explanation: "Thirteen cards total: 5 + 4 + 2 clubs leaves 2 diamonds. Counting the hand out is what separates good defenders from lucky ones."
        ),
        QuizQuestion(
            id: "more-pro-second-hand-high",
            prompt: "When is second hand high right rather than second hand low?",
            choices: [
                "Never, the rule is absolute",
                "When playing low would let a singleton or doubleton honor in dummy win",
                "Only at notrump",
                "Only when holding an ace"
            ],
            answerIndex: 1,
            explanation: "Rules of thumb bend to the layout. If ducking hands declarer a trick they could not otherwise take, rise instead."
        ),
    ]
}
