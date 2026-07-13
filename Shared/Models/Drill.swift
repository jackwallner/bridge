import Foundation

/// A two-option self-test on a card's front ("Keep" / "Throw"). Answering
/// flips the card and grades the pick before the explanation lands.
struct CardChoice: Sendable {
    let options: [String]
    let answerIndex: Int

    init(_ first: String, _ second: String, answerIndex: Int) {
        options = [first, second]
        self.answerIndex = answerIndex
    }
}

struct Flashcard: Identifiable, Sendable {
    let id: String
    let frontTitle: String
    let frontTiles: [Tile]
    let frontSubtitle: String?
    let backTitle: String
    let backBody: String
    let choice: CardChoice?

    init(id: String, frontTitle: String, frontTiles: [Tile] = [], frontSubtitle: String? = nil,
         backTitle: String, backBody: String, choice: CardChoice? = nil) {
        self.id = id
        self.frontTitle = frontTitle
        self.frontTiles = frontTiles
        self.frontSubtitle = frontSubtitle
        self.backTitle = backTitle
        self.backBody = backBody
        self.choice = choice
    }
}

struct QuizQuestion: Identifiable, Sendable {
    let id: String
    let prompt: String
    let tiles: [Tile]
    let choices: [String]
    let answerIndex: Int
    let explanation: String

    init(id: String, prompt: String, tiles: [Tile] = [], choices: [String], answerIndex: Int,
         explanation: String) {
        self.id = id
        self.prompt = prompt
        self.tiles = tiles
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
    }
}

struct HandMatchQuestion: Identifiable, Sendable {
    let id: String
    let tiles: [Tile]
    let choices: [HandCategory]
    let answer: HandCategory
    let explanation: String
}

struct CharlestonScenario: Identifiable, Sendable {
    let id: String
    let situation: String
    let deal: [Tile]
    let recommendedPass: [Tile]
    let reasoning: String
    let tip: String
}

enum DrillKind: Sendable {
    case flashcards([Flashcard])
    case quiz([QuizQuestion])
    case handMatch([HandMatchQuestion])
    case charleston([CharlestonScenario])

    var itemCount: Int {
        switch self {
        case .flashcards(let cards): return cards.count
        case .quiz(let questions): return questions.count
        case .handMatch(let questions): return questions.count
        case .charleston(let scenarios): return scenarios.count
        }
    }
}

struct Drill: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: DrillKind
    /// Extra practice sets inside an otherwise-free room: same mechanics, more
    /// original questions, locked behind Mahj+. Nothing that was free became
    /// paid; these are additions.
    let isPlus: Bool

    init(id: String, title: String, subtitle: String, kind: DrillKind, isPlus: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
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
