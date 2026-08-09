import Foundation

/// One normalized, single-select item inside a Quick Session. Built from
/// whichever choice-gradeable content is behind it (quiz, hand-match, or a
/// flashcard with a CardChoice) so the session itself never has to know the
/// source shape, just prompt/cards/choices/answer.
struct QuickItem: Identifiable, Sendable {
    let id: String
    let prompt: String
    let cards: [BridgeCard]
    let choices: [String]
    let answerIndex: Int
    let explanation: String
    /// e.g. "The BridgeCard Room", shown as a small tag above the prompt.
    let sourceLabel: String
    /// The room this item came from, for per-room accuracy stats. Generated
    /// items report the room whose skill they drill.
    let roomID: String
    /// The persistence row this answer contributes to. Most authored items use
    /// their own id. Procedural daily items can share one bounded rollup row.
    let trackingID: String
    /// False for one-off generated prompts that can never be scheduled back
    /// into Fix My Mistakes.
    let isReviewable: Bool

    init(
        id: String,
        prompt: String,
        cards: [BridgeCard],
        choices: [String],
        answerIndex: Int,
        explanation: String,
        sourceLabel: String,
        roomID: String,
        trackingID: String? = nil,
        isReviewable: Bool = true
    ) {
        self.id = id
        self.prompt = prompt
        self.cards = cards
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.sourceLabel = sourceLabel
        self.roomID = roomID
        self.trackingID = trackingID ?? id
        self.isReviewable = isReviewable
    }
}

/// Builds the Quick Session: a short run of choice-only items pulled from
/// across the rooms, weighted so misses come back first and unseen material
/// beats review. Plain flip flashcards and Play scenarios are excluded;
/// they aren't right/wrong in one tap and don't belong in a uniform choice flow.
enum SessionBuilder {

    static let sessionDrill = Drill(
        id: "quick-session",
        title: "Quick Session",
        subtitle: "A short mix of what you need next",
        kind: .flashcards([])
    )

    static let reviewDrill = Drill(
        id: "review-session",
        title: "Fix My Mistakes",
        subtitle: "The questions you keep getting wrong",
        kind: .flashcards([])
    )

    static let gameNightPrepDrill = Drill(
        id: "game-night-prep",
        title: "Game Night Prep",
        subtitle: "A five-minute mix for your next table",
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

        return picked.map(prepared)
    }

    /// The Fix My Mistakes session: exactly the items the scheduler says are
    /// due, in the order it ranked them. Unlike Quick Session this never pads
    /// with fresh material - the whole point is a short run of the questions a
    /// player actually keeps getting wrong.
    static func reviewSession(ids: [String], includePro: Bool) -> [QuickItem] {
        let pool = Dictionary(choicePool(includePro: includePro).map { ($0.id, $0) }) { first, _ in first }
        return ids.compactMap { pool[$0] }.map(prepared)
    }

    /// How many due items can actually be served. An id can go stale when
    /// content is renamed between releases, so the Home card counts what the
    /// pool can still produce rather than what the store remembers.
    static func reviewSessionCount(ids: [String], includePro: Bool) -> Int {
        reviewSession(ids: ids, includePro: includePro).count
    }

    /// A member's pre-game session. Due mistakes lead, then the weakest room,
    /// then unseen material. The final tier keeps the session full for a new
    /// player who has not built enough history to personalize yet.
    static func gameNightPrep(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        dueIDs: [String],
        weakestRoomID: String?
    ) -> [QuickItem] {
        let due = Set(dueIDs)
        let pool = choicePool(includePro: true)

        func tier(_ item: QuickItem) -> Int {
            if due.contains(item.id) { return 0 }
            if missed.contains(item.id) { return 1 }
            if item.roomID == weakestRoomID { return 2 }
            if !seen.contains(item.id) { return 3 }
            return 4
        }

        return Dictionary(grouping: pool.shuffled(), by: tier)
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .prefix(count)
            .map(prepared)
    }

    /// Used by deterministic daily features to draw from a particular room
    /// without exposing locked content to callers that did not request it.
    static func choiceItems(in roomID: String, includePro: Bool) -> [QuickItem] {
        choicePool(includePro: includePro).filter { $0.roomID == roomID }
    }

    /// Answer-position variety: shuffle each item's choices deterministically
    /// by its own id so the order is stable across re-render/undo but not
    /// always the authored slot.
    static func prepared(_ item: QuickItem) -> QuickItem {
        let shuffled = ChoiceShuffle.shuffledChoices(labels: item.choices, answerIndex: item.answerIndex, seed: item.id)
        return QuickItem(
            id: item.id,
            prompt: item.prompt,
            cards: item.cards,
            choices: shuffled.labels,
            answerIndex: shuffled.answerIndex,
            explanation: item.explanation,
            sourceLabel: item.sourceLabel,
            roomID: item.roomID,
            trackingID: item.trackingID,
            isReviewable: item.isReviewable
        )
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
                            cards: question.cards,
                            choices: question.choices,
                            answerIndex: question.answerIndex,
                            explanation: question.explanation,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .handMatch(let questions):
                    pool += questions.map { question in
                        let labels = question.choices.map(\.displayName)
                        let answerIndex = question.choices.firstIndex(of: question.answer) ?? 0
                        return QuickItem(
                            id: question.id,
                            prompt: "What is the best opening call?",
                            cards: question.cards.racked,
                            choices: labels,
                            answerIndex: answerIndex,
                            explanation: question.explanation,
                            sourceLabel: room.name,
                            roomID: room.id
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
                            cards: card.frontCards,
                            choices: choice.options,
                            answerIndex: choice.answerIndex,
                            explanation: card.backBody,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .play:
                    break // Too interaction-heavy for a quick, uniform choice flow.
                }
            }
        }
        return pool
    }
}
