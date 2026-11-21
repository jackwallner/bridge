import Foundation

struct BridgeMinuteResult: Codable, Identifiable, Sendable {
    let dayKey: String
    let shortDate: String
    let completedAt: Date
    let answers: [Bool]
    let correctByCategory: [String: Int]
    let totalByCategory: [String: Int]

    var id: String { dayKey }
    var score: Int { answers.filter { $0 }.count }
    var total: Int { answers.count }

    func correct(in category: BridgeMinuteCategory) -> Int {
        correctByCategory[category.rawValue, default: 0]
    }

    func total(in category: BridgeMinuteCategory) -> Int {
        totalByCategory[category.rawValue, default: 0]
    }

    var shareText: String {
        let grid = answers.map { $0 ? "🟩" : "⬜️" }.joined()
        let link = AppStoreLinks.productURL.absoluteString
        return String(localized: "Bridge Minute \(shortDate): \(score)/\(total)\n\(grid)\nCan you beat me? \(link)")
    }
}

@MainActor
final class BridgeMinuteStore: ObservableObject {
    static let shared = BridgeMinuteStore()

    @Published private(set) var results: [String: BridgeMinuteResult]

    private let defaults: UserDefaults
    private static let resultsKey = "bridgeMinute.results"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.resultsKey),
           let decoded = try? JSONDecoder().decode([String: BridgeMinuteResult].self, from: data) {
            results = decoded
        } else {
            results = [:]
        }
        adoptNonGregorianKeys()
    }

    /// Older builds keyed a day by the system calendar, so a Buddhist, Hebrew
    /// or Japanese-era phone saved "2569-11-20". A Gregorian key's year is
    /// always within one of the year the result was finished, which a
    /// non-Gregorian one never is, so those move to the Gregorian key of the
    /// day they were finished.
    private func adoptNonGregorianKeys() {
        let calendar = Calendar.gregorianLocal
        var moved = false
        for (key, result) in results {
            let year = Int(key.split(separator: "-").first ?? "") ?? 0
            let finished = calendar.component(.year, from: result.completedAt)
            guard abs(year - finished) > 1 else { continue }
            let adopted = BridgeMinuteContent.key(for: result.completedAt, calendar: calendar)
            results[key] = nil
            guard results[adopted] == nil else { moved = true; continue }
            results[adopted] = BridgeMinuteResult(
                dayKey: adopted,
                shortDate: BridgeMinuteContent.shortDate(for: result.completedAt, calendar: calendar),
                completedAt: result.completedAt,
                answers: result.answers,
                correctByCategory: result.correctByCategory,
                totalByCategory: result.totalByCategory
            )
            moved = true
        }
        if moved { persist() }
    }

    func result(for day: Date, calendar: Calendar = .gregorianLocal) -> BridgeMinuteResult? {
        results[BridgeMinuteContent.key(for: day, calendar: calendar)]
    }

    @discardableResult
    func record(
        challenge: BridgeMinuteChallenge,
        answers: [Bool],
        now: Date = Date()
    ) -> BridgeMinuteResult {
        if let existing = results[challenge.dayKey] { return existing }

        var correctByCategory: [String: Int] = [:]
        var totalByCategory: [String: Int] = [:]
        for (question, correct) in zip(challenge.questions, answers) {
            totalByCategory[question.category.rawValue, default: 0] += 1
            if correct { correctByCategory[question.category.rawValue, default: 0] += 1 }
        }
        let result = BridgeMinuteResult(
            dayKey: challenge.dayKey,
            shortDate: challenge.shortDate,
            completedAt: now,
            answers: answers,
            correctByCategory: correctByCategory,
            totalByCategory: totalByCategory
        )
        results[challenge.dayKey] = result
        persist()
        return result
    }

    func completedThisWeek(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return results.values.filter { interval.contains($0.completedAt) }.count
    }

    func archiveDates(
        before day: Date = Date(),
        count: Int = 30,
        calendar: Calendar = .current
    ) -> [Date] {
        (1...count).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: day)
        }
    }

    func resetAll() {
        results = [:]
        defaults.removeObject(forKey: Self.resultsKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        defaults.set(data, forKey: Self.resultsKey)
    }
}
