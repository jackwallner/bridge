import Foundation

enum RuleQuestions {
    static let duplicate: [QuizQuestion] = [
        QuizQuestion(id: "rules-passed-out", prompt: "All four players pass before any bid. What is the duplicate board score?",
                     choices: ["0", "50 to the dealer", "Play 1NT"], answerIndex: 0,
                     explanation: "Four opening passes end the auction with no contract. The passed-out board scores zero. After a bid, double, or redouble, three consecutive passes end the auction."),
        QuizQuestion(id: "rules-doubled-game", prompt: "You make 2♥ doubled, exactly, not vulnerable. What is your duplicate score?",
                     choices: ["470", "170", "240"], answerIndex: 0,
                     explanation: "Contract tricks score 2 × 30 × 2 = 120, enough for the 300 game bonus. Add 50 for making a doubled contract: 470. Overtricks do not decide whether the contract earns game."),
        QuizQuestion(id: "rules-down-four", prompt: "You go down four doubled, not vulnerable. What is your duplicate score?",
                     choices: ["-800", "-700", "-400"], answerIndex: 0,
                     explanation: "The first undertrick costs 100, the next two 200 each, and the fourth 300: -800. Vulnerable doubled penalties are 200 for the first and 300 for each later undertrick.")
    ]
}
