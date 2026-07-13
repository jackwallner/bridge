import Foundation

/// One normalized, single-select item inside a Quick Session. Built from
/// whichever choice-gradeable content is behind it (quiz, hand-match, or a
/// flashcard with a CardChoice) so the session itself never has to know the
/// source shape, just prompt/tiles/choices/answer.
struct QuickItem: Identifiable, Sendable {
    let id: String
    let prompt: String
    let tiles: [Tile]
    let choices: [String]
    let answerIndex: Int
    let explanation: String
    /// e.g. "The Tile Room", shown as a small tag above the prompt.
    let sourceLabel: String
}

/// Builds the Quick Session: a short run of choice-only items pulled from
/// across the rooms, weighted so misses come back first and unseen material
/// beats review. Plain flip flashcards and Charleston scenarios are excluded;
/// they aren't right/wrong in one tap and don't belong in a uniform choice flow.
enum SessionBuilder {

    static let sessionDrill = Drill(
        id: "quick-session",
        title: "Quick Session",
        subtitle: "A short mix of what you need next",
        kind: .flashcards([])
    )

    static func quickSession(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        includePro: Bool
    ) -> [QuickItem] {
        let pool = choicePool(includePro: includePro)

        // Priority tiers: missed first, unseen next, review last.
        func tier(_ item: QuickItem) -> Int {
            if missed.contains(item.id) { return 0 }
            if !seen.contains(item.id) { return 1 }
            return 2
        }
        let picked = Dictionary(grouping: pool.shuffled(), by: tier)
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .prefix(count)

        // Answer-position variety: shuffle each item's choices deterministically
        // by its own id so the order is stable across re-render/undo but not
        // always the authored slot.
        return picked.map { item in
            let shuffled = ChoiceShuffle.shuffledChoices(labels: item.choices, answerIndex: item.answerIndex, seed: item.id)
            return QuickItem(
                id: item.id,
                prompt: item.prompt,
                tiles: item.tiles,
                choices: shuffled.labels,
                answerIndex: shuffled.answerIndex,
                explanation: item.explanation,
                sourceLabel: item.sourceLabel
            )
        }
    }

    /// Every choice-gradeable item a player is entitled to: the free rooms'
    /// free drills, plus (for members) the locked extra sets and the paid room.
    private static func choicePool(includePro: Bool) -> [QuickItem] {
        var pool: [QuickItem] = []
        for room in DrillLibrary.rooms where room.isFree || includePro {
            for drill in room.drills where !room.isLocked(drill, isMember: includePro) {
                switch drill.kind {
                case .quiz(let questions):
                    pool += questions.map { question in
                        QuickItem(
                            id: question.id,
                            prompt: question.prompt,
                            tiles: question.tiles,
                            choices: question.choices,
                            answerIndex: question.answerIndex,
                            explanation: question.explanation,
                            sourceLabel: room.name
                        )
                    }
                case .handMatch(let questions):
                    pool += questions.map { question in
                        let labels = question.choices.map(\.displayName)
                        let answerIndex = question.choices.firstIndex(of: question.answer) ?? 0
                        return QuickItem(
                            id: question.id,
                            prompt: "Which section is this rack chasing?",
                            tiles: question.tiles.racked,
                            choices: labels,
                            answerIndex: answerIndex,
                            explanation: question.explanation,
                            sourceLabel: room.name
                        )
                    }
                case .flashcards(let cards):
                    pool += cards.compactMap { card in
                        guard let choice = card.choice else { return nil }
                        var prompt = card.frontTitle
                        if let subtitle = card.frontSubtitle {
                            prompt += "\n\(subtitle)"
                        }
                        return QuickItem(
                            id: card.id,
                            prompt: prompt,
                            tiles: card.frontTiles,
                            choices: choice.options,
                            answerIndex: choice.answerIndex,
                            explanation: card.backBody,
                            sourceLabel: room.name
                        )
                    }
                case .charleston:
                    break // Too interaction-heavy for a quick, uniform choice flow.
                }
            }
        }
        return pool
    }
}
