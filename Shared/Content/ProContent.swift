import Foundation

enum ProContent {
    static let competitiveBidding: [QuizQuestion] = [
        QuizQuestion(
            id: "pro-takeout-double",
            prompt: "Left-hand opponent opens 1♥. A takeout double usually asks partner to do what?",
            choices: ["Pass", "Bid an unbid suit", "Lead a heart", "Bid notrump at any strength"],
            answerIndex: 1,
            explanation: "A takeout double shows support for the unbid suits and asks partner to choose one, unless partner has a special reason to pass."
        ),
        QuizQuestion(
            id: "pro-preempt",
            prompt: "What is the main purpose of a preemptive opening?",
            choices: ["Show a balanced hand", "Ask for aces", "Describe a long suit and consume bidding space", "Force partner to game"],
            answerIndex: 2,
            explanation: "A preempt shows a long suit and limited hand while making the opponents start their exchange at a higher level."
        ),
        QuizQuestion(
            id: "pro-stayman",
            prompt: "After partner opens 1NT, what does 2♣ Stayman ask?",
            choices: ["For aces", "For a four-card major", "For club support", "For a minimum hand"],
            answerIndex: 1,
            explanation: "Stayman asks the 1NT opener whether they hold a four-card major."
        ),
        QuizQuestion(
            id: "pro-transfer",
            prompt: "After 1NT, a Jacoby transfer primarily lets which hand become declarer?",
            choices: ["The weaker hand", "The stronger notrump hand", "Either opponent", "Dummy"],
            answerIndex: 1,
            explanation: "Transfers place the strong 1NT hand as declarer, keeping its honors concealed on opening lead."
        ),
    ]

    static let advancedPlay: [PlayScenario] = [
        PlayScenario(
            id: "pro-play-finesse",
            situation: "You lead low toward A-Q of hearts. Left-hand opponent follows low. Which card executes the finesse?",
            cards: [.h(.ace), .h(.queen)],
            answerIndex: 1,
            reasoning: "Play Q♥. It wins when the missing king is with the opponent who already played.",
            tip: "The ace remains as a later winner and entry."
        ),
        PlayScenario(
            id: "pro-play-hold-up",
            situation: "In 3NT, opponents lead a suit where you hold A-x-x and dummy has two small. Which card often breaks their communication?",
            cards: [.s(.ace), .s(.three), .s(.two)],
            answerIndex: 2,
            reasoning: "Duck a small card early. Winning the ace immediately may let defenders run the suit when they regain the lead.",
            tip: "Count the suit before holding up. Do not duck if the contract is in immediate danger elsewhere."
        ),
        PlayScenario(
            id: "pro-play-safety",
            situation: "You need four club tricks from A-K-9-8 opposite Q-7-6-5. Which honor do you cash first to guard against a 4-1 split?",
            cards: [.c(.ace), .c(.king), .c(.queen)],
            answerIndex: 2,
            reasoning: "Cash the queen from the shorter honor holding first. This preserves flexibility when one defender shows out.",
            tip: "A safety play trades the maximum result for a better chance to make the contract."
        ),
    ]

    static let duplicateQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "pro-duplicate-score",
            prompt: "At matchpoints, what matters most?",
            choices: ["Your raw score alone", "How your result compares with other pairs", "Winning every contract", "Avoiding all doubles"],
            answerIndex: 1,
            explanation: "Duplicate matchpoints compare your score on a board with every pair holding the same direction."
        ),
        QuizQuestion(
            id: "pro-game-major",
            prompt: "Which major-suit contract earns the game bonus?",
            choices: ["2♥", "3♠", "4♥", "5♠"],
            answerIndex: 2,
            explanation: "Four of a major is the standard game level. Higher contracts may also score game but take unnecessary risk."
        ),
        QuizQuestion(
            id: "pro-vulnerability",
            prompt: "Vulnerability changes which two things most directly?",
            choices: ["Card rank and turn order", "Game bonuses and undertrick penalties", "Trump order and bidding order", "Dummy and declarer"],
            answerIndex: 1,
            explanation: "Vulnerability increases the game bonus and the penalties for going down."
        ),
    ]
}
