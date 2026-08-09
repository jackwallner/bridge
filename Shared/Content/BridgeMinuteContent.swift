import Foundation

enum BridgeMinuteCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case bidding
    case declarerPlay
    case defense

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bidding: return "Bidding"
        case .declarerPlay: return "Declarer Play"
        case .defense: return "Defense"
        }
    }

    var icon: String {
        switch self {
        case .bidding: return "quote.bubble.fill"
        case .declarerPlay: return "suit.spade.fill"
        case .defense: return "shield.lefthalf.filled"
        }
    }
}

struct BridgeMinuteQuestion: Sendable {
    let category: BridgeMinuteCategory
    let item: QuickItem
}

struct BridgeMinuteChallenge: Identifiable, Sendable {
    let day: Date
    let dayKey: String
    let shortDate: String
    let questions: [BridgeMinuteQuestion]

    var id: String { dayKey }
    var items: [QuickItem] { questions.map(\.item) }
}

/// One shared five-question set per calendar date. Its hands are dealt
/// procedurally from the same classifier that grades Endless Practice, while
/// the declarer and defense calls come from the app's authored teaching
/// content. Every member gets the same five questions on the same day with no
/// account, no server, and no leaderboard: the day key is the whole protocol.
enum BridgeMinuteContent {
    static let questionCount = 5

    static let drill = Drill(
        id: "bridge-minute",
        title: "Bridge Minute",
        subtitle: "Today's shared five-question challenge",
        kind: .quiz([]),
        isPlus: true
    )

    static func challenge(for day: Date = Date(), calendar: Calendar = .current) -> BridgeMinuteChallenge {
        let dayKey = key(for: day, calendar: calendar)
        let auction = auctionQuestions(dayKey: dayKey)
        let declarer = declarerQuestion(dayKey: dayKey).map { [$0] } ?? []
        let defense = roomQuestions(dayKey: dayKey, roomID: "defense-room", category: .defense, count: 2)

        // Interleaved so the run does not feel like three separate quizzes.
        var questions: [BridgeMinuteQuestion] = []
        if let first = auction.first { questions.append(first) }
        questions += declarer
        if let firstDefense = defense.first { questions.append(firstDefense) }
        if auction.count > 1 { questions.append(auction[1]) }
        if defense.count > 1 { questions.append(defense[1]) }

        let parts = calendar.dateComponents([.month, .day], from: day)
        let shortDate = String(format: "%02d/%02d", parts.month ?? 1, parts.day ?? 1)
        return BridgeMinuteChallenge(day: day, dayKey: dayKey, shortDate: shortDate, questions: questions)
    }

    static func key(for day: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 1970,
            parts.month ?? 1,
            parts.day ?? 1
        )
    }

    private static func auctionQuestions(dayKey: String) -> [BridgeMinuteQuestion] {
        let hands = HandGenerator.batch(count: 2, seed: "bridge-minute-\(dayKey)-hands")
        return hands.enumerated().map { index, hand in
            let labels = HandCategory.allCases.map(\.displayName)
            let answerIndex = HandCategory.allCases.firstIndex(of: hand.answer) ?? 0
            let item = QuickItem(
                id: PracticeSkill.openings.itemPrefix + "minute-\(dayKey)-\(index)",
                prompt: "What is your opening call?",
                cards: hand.cards,
                choices: labels,
                answerIndex: answerIndex,
                explanation: hand.explanation,
                sourceLabel: "Bridge Minute: Opening",
                roomID: PracticeSkill.openings.roomID,
                trackingID: PracticeSkill.openings.rawValue,
                isReviewable: false
            )
            return BridgeMinuteQuestion(category: .bidding, item: SessionBuilder.prepared(item))
        }
    }

    /// Declarer play is built straight from the authored Play scenarios rather
    /// than through `SessionBuilder.choiceItems`. The quick-session pool
    /// deliberately excludes Play drills because tapping a card in a layout is
    /// not a uniform choice flow, but the same scenario reads perfectly well as
    /// "which of these cards do you play", which is what the daily needs.
    private static func declarerQuestion(dayKey: String) -> BridgeMinuteQuestion? {
        let scenarios = DrillLibrary.rooms.flatMap { room in
            room.drills.flatMap { drill -> [PlayScenario] in
                if case .play(let values) = drill.kind { return values }
                return []
            }
        }
        guard !scenarios.isEmpty else { return nil }

        var generator = StableSeededGenerator(seed: "bridge-minute-\(dayKey)-declarer")
        let scenario = scenarios[Int(generator.next() % UInt64(scenarios.count))]
        guard scenario.cards.indices.contains(scenario.answerIndex) else { return nil }

        let labels = scenario.cards.map(\.spokenName)
        let item = QuickItem(
            id: "bridge-minute-declarer-\(dayKey)",
            prompt: "\(scenario.situation) Which card do you play?",
            cards: scenario.cards,
            choices: labels,
            answerIndex: scenario.answerIndex,
            explanation: scenario.reasoning,
            sourceLabel: "Bridge Minute: Declarer Play",
            roomID: "declarer-room",
            trackingID: "bridge-minute-declarer",
            isReviewable: false
        )
        return BridgeMinuteQuestion(category: .declarerPlay, item: SessionBuilder.prepared(item))
    }

    /// Authored questions drawn from one room, picked by a permutation of the
    /// day key so the same date always yields the same questions.
    private static func roomQuestions(
        dayKey: String,
        roomID: String,
        category: BridgeMinuteCategory,
        count: Int
    ) -> [BridgeMinuteQuestion] {
        let pool = SessionBuilder.choiceItems(in: roomID, includePro: true)
        guard !pool.isEmpty else { return [] }
        let indices = ChoiceShuffle.permutation(count: pool.count, seed: "bridge-minute-\(dayKey)-\(roomID)")
        return indices.prefix(count).map { index in
            BridgeMinuteQuestion(category: category, item: SessionBuilder.prepared(pool[index]))
        }
    }
}
