import Foundation

// Exports the iOS content and generator fixtures for the Android port.
// Run through scripts/sync-android-content.sh, never by hand.
//
//   content.json  every authored drill, the primer and the What's New notes,
//                 read by the app at runtime.
//   parity.json   classifier results, seeded generator output and the daily
//                 challenge, read only by the Android unit tests to prove the
//                 Kotlin engine classifies and deals exactly what iOS does.

func code(_ card: BridgeCard) -> String { "\(card.suit.rawValue.prefix(1).uppercased())\(card.rank.rawValue)" }
func codes(_ cards: [BridgeCard]) -> [String] { cards.map(code) }

func flashcard(_ card: Flashcard) -> [String: Any] {
    var json: [String: Any] = [
        "id": card.id,
        "frontTitle": card.frontTitle,
        "frontCards": codes(card.frontCards),
        "backTitle": card.backTitle,
        "backBody": card.backBody,
    ]
    if let subtitle = card.frontSubtitle { json["frontSubtitle"] = subtitle }
    if let choice = card.choice {
        json["choice"] = ["options": choice.options, "answerIndex": choice.answerIndex]
    }
    return json
}

func quiz(_ question: QuizQuestion) -> [String: Any] {
    [
        "id": question.id,
        "prompt": question.prompt,
        "cards": codes(question.cards),
        "choices": question.choices,
        "answerIndex": question.answerIndex,
        "explanation": question.explanation,
    ]
}

func handMatch(_ question: HandMatchQuestion) -> [String: Any] {
    [
        "id": question.id,
        "cards": codes(question.cards),
        "choices": question.choices.map(\.rawValue),
        "answer": question.answer.rawValue,
        "explanation": question.explanation,
    ]
}

func play(_ scenario: PlayScenario) -> [String: Any] {
    [
        "id": scenario.id,
        "situation": scenario.situation,
        "cards": codes(scenario.cards),
        "answerIndex": scenario.answerIndex,
        "reasoning": scenario.reasoning,
        "tip": scenario.tip,
    ]
}

func drill(_ drill: Drill) -> [String: Any] {
    var json: [String: Any] = [
        "id": drill.id,
        "title": drill.title,
        "subtitle": drill.subtitle,
        "isPlus": drill.isPlus,
    ]
    switch drill.kind {
    case .flashcards(let cards): json["kind"] = "flashcards"; json["items"] = cards.map(flashcard)
    case .quiz(let questions): json["kind"] = "quiz"; json["items"] = questions.map(quiz)
    case .handMatch(let questions): json["kind"] = "handMatch"; json["items"] = questions.map(handMatch)
    case .play(let scenarios): json["kind"] = "play"; json["items"] = scenarios.map(play)
    }
    return json
}

func content() -> [String: Any] {
    let rooms: [[String: Any]] = DrillLibrary.rooms.map { room in
        [
            "id": room.id,
            "name": room.name,
            "tagline": room.tagline,
            "icon": room.icon,
            "isFree": room.isFree,
            "drills": room.drills.map(drill),
        ]
    }
    let primer: [[String: Any]] = HowToPlayContent.pages.map { page in
        var json: [String: Any] = [
            "id": page.id, "icon": page.icon, "title": page.title, "body": page.body, "cards": codes(page.cards),
        ]
        if let tip = page.tip { json["tip"] = tip }
        return json
    }
    // The iPad line is Apple-only; Android has no iPad layout to announce.
    let whatsNew: [[String: Any]] = WhatsNew.releases.map { release in
        [
            "version": release.version,
            "headline": release.headline,
            "items": release.items.filter { $0.id != "ipad" }.map { item in
                ["id": item.id, "icon": item.icon, "title": item.title, "body": item.body, "isPlus": item.isPlus]
            },
        ]
    }
    return [
        "rooms": rooms,
        "primer": primer,
        "whatsNew": whatsNew,
    ]
}

// MARK: - Parity fixtures

func quickItem(_ item: QuickItem) -> [String: Any] {
    [
        "id": item.id,
        "prompt": item.prompt,
        "cards": codes(item.cards),
        "choices": item.choices,
        "answerIndex": item.answerIndex,
        "explanation": item.explanation,
        "sourceLabel": item.sourceLabel,
        "roomID": item.roomID,
        "trackingID": item.trackingID,
        "isReviewable": item.isReviewable,
    ]
}

func parity() -> [String: Any] {
    let seeds = ["alpha", "bridge-minute-2026-09-30-hands", "card-quiz-3", "", "Spades"]
    var streams: [String: [String]] = [:]
    for seed in seeds {
        var generator = StableSeededGenerator(seed: seed)
        streams[seed] = (0..<8).map { _ in String(generator.next()) }
    }
    var permutations: [String: [Int]] = [:]
    for seed in seeds {
        for count in [2, 3, 4, 6, 7, 13] {
            permutations["\(seed)|\(count)"] = ChoiceShuffle.permutation(count: count, seed: seed)
        }
    }

    var hands: [String: Any] = [:]
    for seed in ["h1", "h2", "daily-2026-10-01", "bridge-minute-2026-10-16-hands"] {
        hands[seed] = HandGenerator.batch(count: 7, seed: seed).map { hand in
            [
                "cards": codes(hand.cards),
                "answer": hand.answer.rawValue,
                "explanation": hand.explanation,
            ] as [String: Any]
        }
    }

    // Seeded random 13-card deals, classified and explained by iOS, so the
    // Kotlin classifier and coaching lines are held to the Swift ones.
    let deck: [BridgeCard] = Suit.allCases.flatMap { suit in Rank.allCases.map { BridgeCard($0, suit) } }
    var classifications: [[String: Any]] = []
    var dealer = StableSeededGenerator(seed: "classifier-parity")
    for _ in 0..<600 {
        let cards = Array(deck.shuffled(using: &dealer).prefix(13)).racked
        var row: [String: Any] = ["cards": codes(cards), "hcp": cards.highCardPoints]
        if let category = HandGenerator.opening(for: cards) {
            row["opening"] = category.rawValue
            row["explanation"] = HandGenerator.explain(cards, answer: category)
        }
        classifications.append(row)
    }
    let cardFacts: [[String: Any]] = deck.map { card in
        ["code": code(card), "short": card.shortLabel, "spoken": card.spokenName, "hcp": card.highCardPoints, "sortKey": card.sortKey]
    }

    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    var minutes: [String: Any] = [:]
    for day in ["2026-08-09", "2026-09-30", "2026-10-01", "2027-01-15", "2026-02-28", "2026-10-16"] {
        let parts = day.split(separator: "-").map { Int($0)! }
        let date = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
        let challenge = BridgeMinuteContent.challenge(for: date, calendar: utc)
        minutes[day] = [
            "shortDate": challenge.shortDate,
            "questions": challenge.questions.map { ["category": $0.category.rawValue, "item": quickItem($0.item)] },
        ]
    }

    let roomIDs = DrillLibrary.rooms.map(\.id)
    let memberPool = roomIDs.flatMap { SessionBuilder.choiceItems(in: $0, includePro: true) }
    let freePool = roomIDs.flatMap { SessionBuilder.choiceItems(in: $0, includePro: false) }

    return [
        "streams": streams,
        "permutations": permutations,
        "hands": hands,
        "classifications": classifications,
        "cardFacts": cardFacts,
        "minutes": minutes,
        "memberPool": memberPool.map { quickItem(SessionBuilder.prepared($0)) },
        "freePoolIDs": freePool.map(\.id),
        "drillCounts": Dictionary(uniqueKeysWithValues: DrillLibrary.rooms.flatMap(\.drills).map { ($0.id, $0.kind.itemCount) }),
        "lockedDrillCount": DrillLibrary.rooms.reduce(0) { $0 + $1.plusDrillCount },
    ]
}

func write(_ object: Any, to path: String) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    try data.write(to: URL(fileURLWithPath: path))
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write("usage: export <content.json> <parity.json>\n".data(using: .utf8)!)
    exit(2)
}
try write(content(), to: arguments[1])
try write(parity(), to: arguments[2])
