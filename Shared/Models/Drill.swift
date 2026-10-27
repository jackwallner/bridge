import Foundation

extension String {
    /// Authored teaching copy, looked up in the string catalog by its English
    /// text. The content files stay plain English; each model localizes its
    /// copy once, at init, so every screen that shows it gets the translation.
    var localizedContent: String {
        Bundle.main.localizedString(forKey: self, value: self, table: nil)
    }
}

/// A two-option self-test on a card's front ("Keep" / "Throw"). Answering
/// flips the card and grades the pick before the explanation lands.
struct CardChoice: Sendable {
    let options: [String]
    let answerIndex: Int

    init(_ first: String, _ second: String, answerIndex: Int) {
        options = [first.localizedContent, second.localizedContent]
        self.answerIndex = answerIndex
    }
}

struct Flashcard: Identifiable, Sendable {
    let id: String
    let frontTitle: String
    let frontCards: [BridgeCard]
    let frontSubtitle: String?
    let backTitle: String
    let backBody: String
    let choice: CardChoice?

    init(id: String, frontTitle: String, frontCards: [BridgeCard] = [], frontSubtitle: String? = nil,
         backTitle: String, backBody: String, choice: CardChoice? = nil) {
        self.id = id
        self.frontTitle = frontTitle.localizedContent
        self.frontCards = frontCards
        self.frontSubtitle = frontSubtitle?.localizedContent
        self.backTitle = backTitle.localizedContent
        self.backBody = backBody.localizedContent
        self.choice = choice
    }
}

struct QuizQuestion: Identifiable, Sendable {
    let id: String
    let prompt: String
    let cards: [BridgeCard]
    let choices: [String]
    let answerIndex: Int
    let explanation: String

    init(id: String, prompt: String, cards: [BridgeCard] = [], choices: [String], answerIndex: Int,
         explanation: String) {
        self.id = id
        self.prompt = prompt.localizedContent
        self.cards = cards
        self.choices = choices.map(\.localizedContent)
        self.answerIndex = answerIndex
        self.explanation = explanation.localizedContent
    }
}

struct HandMatchQuestion: Identifiable, Sendable {
    let id: String
    let cards: [BridgeCard]
    let choices: [HandCategory]
    let answer: HandCategory
    let explanation: String

    init(id: String, cards: [BridgeCard], choices: [HandCategory], answer: HandCategory, explanation: String) {
        self.id = id
        self.cards = cards
        self.choices = choices
        self.answer = answer
        self.explanation = explanation.localizedContent
    }
}

struct PlayScenario: Identifiable, Sendable {
    let id: String
    let situation: String
    let cards: [BridgeCard]
    let answerIndex: Int
    let reasoning: String
    let tip: String

    init(id: String, situation: String, cards: [BridgeCard], answerIndex: Int, reasoning: String, tip: String) {
        self.id = id
        self.situation = situation.localizedContent
        self.cards = cards
        self.answerIndex = answerIndex
        self.reasoning = reasoning.localizedContent
        self.tip = tip.localizedContent
    }
}

enum DrillKind: Sendable {
    case flashcards([Flashcard])
    case quiz([QuizQuestion])
    case handMatch([HandMatchQuestion])
    case play([PlayScenario])

    var itemCount: Int {
        switch self {
        case .flashcards(let cards): return cards.count
        case .quiz(let questions): return questions.count
        case .handMatch(let questions): return questions.count
        case .play(let scenarios): return scenarios.count
        }
    }
}

struct Drill: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: DrillKind
    /// Extra practice sets inside an otherwise-free room: same mechanics, more
    /// original questions, locked behind Bridge+. Nothing that was free became
    /// paid; these are additions.
    let isPlus: Bool

    init(id: String, title: String, subtitle: String, kind: DrillKind, isPlus: Bool = false) {
        self.id = id
        self.title = title.localizedContent
        self.subtitle = subtitle.localizedContent
        self.kind = kind
        self.isPlus = isPlus
    }
}

struct Room: Identifiable, Sendable {
    let id: String
    let name: String
    let tagline: String
    let icon: String
    /// A free room still opens for everyone; individual `isPlus` drills inside
    /// it are the locked extras. A non-free room is locked whole.
    let isFree: Bool
    let drills: [Drill]

    init(id: String, name: String, tagline: String, icon: String, isFree: Bool, drills: [Drill]) {
        self.id = id
        self.name = name.localizedContent
        self.tagline = tagline.localizedContent
        self.icon = icon
        self.isFree = isFree
        self.drills = drills
    }

    /// Drills a member unlocks here: the whole room if it's paid, otherwise
    /// just the extra sets.
    var plusDrillCount: Int {
        isFree ? drills.filter(\.isPlus).count : drills.count
    }

    func isLocked(_ drill: Drill, isMember: Bool) -> Bool {
        guard !isMember else { return false }
        return !isFree || drill.isPlus
    }
}
