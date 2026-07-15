import Foundation

enum JudgmentContent {
    static let judgmentCards: [Flashcard] = [
        Flashcard(
            id: "defense-lead-sequence",
            frontTitle: "Opening lead against notrump",
            frontCards: [.s(.king), .s(.queen), .s(.jack), .s(.six)],
            frontSubtitle: "Lead the K♠ or a low spade?",
            backTitle: "Lead the K♠",
            backBody: "From a solid sequence, lead the top card. The king tells partner you hold the touching honors below it.",
            choice: CardChoice("Lead K♠", "Lead 6♠", answerIndex: 0)
        ),
        Flashcard(
            id: "defense-longest-nt",
            frontTitle: "Against 3NT",
            frontCards: [.h(.queen), .h(.eight), .h(.six), .h(.four), .h(.two)],
            frontSubtitle: "Lead your long suit?",
            backTitle: "Usually yes",
            backBody: "Against notrump, a long suit is your best chance to establish extra tricks. Without a sequence, lead a low card.",
            choice: CardChoice("Lead low", "Avoid hearts", answerIndex: 0)
        ),
        Flashcard(
            id: "defense-ace-unsupported",
            frontTitle: "Against notrump",
            frontCards: [.d(.ace), .d(.seven), .d(.three)],
            frontSubtitle: "Cash the ace immediately?",
            backTitle: "Usually save it",
            backBody: "An unsupported ace is often more valuable as an entry or capture later. Do not automatically cash aces on opening lead.",
            choice: CardChoice("Cash it", "Save it", answerIndex: 1)
        ),
        Flashcard(
            id: "defense-third-hand",
            frontTitle: "Partner leads low",
            frontCards: [.c(.king), .c(.nine), .c(.three)],
            frontSubtitle: "Dummy plays low. Play high?",
            backTitle: "Third hand high",
            backBody: "When partner leads and dummy plays low, third hand often plays high to force out declarer's higher card or win the trick.",
            choice: CardChoice("Play K♣", "Play 3♣", answerIndex: 0)
        ),
        Flashcard(
            id: "defense-return-suit",
            frontTitle: "You win partner's opening lead",
            frontSubtitle: "Return the same suit?",
            backTitle: "Usually return it",
            backBody: "Partner chose that suit for a reason. Returning it helps establish and cash the partnership's winners.",
            choice: CardChoice("Return it", "Switch suits", answerIndex: 0)
        ),
    ]
}
