import Foundation

/// The generated-practice catalogue. Each skill turns a procedural generator
/// into the same `QuickItem` shape the authored drills already produce, so the
/// session runner never has to know whether a question was written by hand or
/// dealt a second ago.
///
/// This is the answer to the finite-content problem: authored sets are a pile a
/// player finishes, generated skills are a machine that keeps going.
enum PracticeSkill: String, CaseIterable, Identifiable, Sendable {
    case openings
    case pointCount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openings: return "Name Your Opening"
        case .pointCount: return "Count the Points"
        }
    }

    var subtitle: String {
        switch self {
        case .openings: return "Freshly dealt hands, unlimited reps"
        case .pointCount: return "Add up a hand at a glance"
        }
    }

    var icon: String {
        switch self {
        case .openings: return "quote.bubble.fill"
        case .pointCount: return "number.circle.fill"
        }
    }

    /// The room this skill practises, for the stats breakdown.
    var roomID: String {
        switch self {
        case .openings, .pointCount: return "auction-room"
        }
    }

    /// Every generated item carries this prefix so `PracticeRecordStore` can
    /// roll an unbounded stream of one-off ids up into one row of stats.
    var itemPrefix: String { "gen-\(rawValue)-" }

    static func skill(forItemID id: String) -> PracticeSkill? {
        allCases.first { id.hasPrefix($0.itemPrefix) }
    }
}

enum EndlessPractice {

    /// A finished endless run is still a "drill" for the completion screen.
    static func drill(for skill: PracticeSkill) -> Drill {
        Drill(id: "endless-\(skill.rawValue)", title: skill.title, subtitle: skill.subtitle, kind: .quiz([]))
    }

    static let challengeDrill = Drill(
        id: "timed-challenge",
        title: "Timed Challenge",
        subtitle: "Beat the clock",
        kind: .quiz([])
    )

    /// A fresh batch of generated questions for one skill.
    static func items(for skill: PracticeSkill, count: Int) -> [QuickItem] {
        switch skill {
        case .openings: return openingItems(count: count)
        case .pointCount: return pointCountItems(count: count)
        }
    }

    /// A mixed batch across every skill, for the timed challenge.
    static func mixedItems(count: Int) -> [QuickItem] {
        let skills = PracticeSkill.allCases
        let perSkill = max(1, count / skills.count + 1)
        return skills.flatMap { items(for: $0, count: perSkill) }.shuffled().prefix(count).map { $0 }
    }

    // MARK: - Openings

    private static func openingItems(count: Int) -> [QuickItem] {
        HandGenerator.batch(count: count).map { hand in
            let labels = HandCategory.allCases.map(\.displayName)
            let answerIndex = HandCategory.allCases.firstIndex(of: hand.answer) ?? 0
            return QuickItem(
                id: PracticeSkill.openings.itemPrefix + UUID().uuidString,
                prompt: "What is your opening call?",
                cards: hand.cards,
                choices: labels,
                answerIndex: answerIndex,
                explanation: hand.explanation,
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.openings.roomID
            )
        }
    }

    // MARK: - Point count

    /// Deal a hand, ask for its high-card points. Distractors sit next to the
    /// true count so the player has to actually add rather than eyeball it.
    private static func pointCountItems(count: Int) -> [QuickItem] {
        let deck: [BridgeCard] = Suit.allCases.flatMap { suit in
            Rank.allCases.map { BridgeCard($0, suit) }
        }
        var items: [QuickItem] = []
        while items.count < count {
            let cards = Array(deck.shuffled().prefix(13)).racked
            let hcp = cards.highCardPoints
            // A hand with no honours at all is a trick question, not a drill.
            guard hcp >= 3 else { continue }

            let offsets = [-2, -1, 1, 2].shuffled().prefix(3)
            var values = Set([hcp])
            for offset in offsets where hcp + offset >= 0 {
                values.insert(hcp + offset)
            }
            let sorted = values.sorted()
            guard let answerIndex = sorted.firstIndex(of: hcp) else { continue }

            items.append(QuickItem(
                id: PracticeSkill.pointCount.itemPrefix + UUID().uuidString,
                prompt: "How many high-card points is this hand worth?",
                cards: cards,
                choices: sorted.map(String.init),
                answerIndex: answerIndex,
                explanation: pointExplanation(cards, total: hcp),
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.pointCount.roomID
            ))
        }
        return items
    }

    private static func pointExplanation(_ cards: [BridgeCard], total: Int) -> String {
        var parts: [String] = []
        for (rank, value) in [(Rank.ace, 4), (Rank.king, 3), (Rank.queen, 2), (Rank.jack, 1)] {
            let held = cards.filter { $0.rank == rank }.count
            guard held > 0 else { continue }
            parts.append("\(held) \(rank.spokenName.lowercased())\(held == 1 ? "" : "s") at \(value)")
        }
        let breakdown = parts.isEmpty ? "no honours" : parts.joined(separator: ", ")
        return "\(breakdown). That totals \(total) high-card points. Aces 4, kings 3, queens 2, jacks 1."
    }
}
