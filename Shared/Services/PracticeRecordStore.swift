import Foundation

/// One item's answering history and its next review date.
///
/// `ProgressStore` already tracks "seen" and "missed" as flat sets, which is
/// enough to sort a daily mix but not enough to schedule anything: a question
/// missed once and then answered right four times still sits in `missedItems`
/// forever. This record carries the counts and the interval, so review can be
/// spaced instead of permanent.
struct PracticeRecord: Codable, Sendable {
    var attempts: Int = 0
    var correct: Int = 0
    var streak: Int = 0
    var lastAnswered: Date = .distantPast
    var dueDate: Date = .distantPast
    var intervalDays: Double = 0
    var ease: Double = 2.5
    var roomID: String = ""

    var accuracy: Double {
        attempts == 0 ? 0 : Double(correct) / Double(attempts)
    }

    var isDue: Bool { dueDate <= Date() }

    /// True while the item still needs work: it has been missed at least once
    /// and has not yet been answered right twice running.
    var needsReview: Bool { attempts > correct && streak < 2 }
}

/// Per-item practice history, the spaced-repetition queue built on top of it,
/// and the room-level rollups the stats screen reads.
@MainActor
final class PracticeRecordStore: ObservableObject {
    static let shared = PracticeRecordStore()

    @Published private(set) var records: [String: PracticeRecord]
    /// Best timed-challenge score, kept separately because it is a high score
    /// rather than a per-item fact.
    @Published private(set) var bestChallengeScore: Int

    private let defaults: UserDefaults

    private enum Keys {
        static let records = "practice.records"
        static let bestChallenge = "practice.bestChallengeScore"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bestChallengeScore = defaults.integer(forKey: Keys.bestChallenge)
        if let data = defaults.data(forKey: Keys.records),
           let decoded = try? JSONDecoder().decode([String: PracticeRecord].self, from: data) {
            records = decoded
        } else {
            records = [:]
        }
    }

    // MARK: - Recording

    /// Grades one answer. Generated items collapse onto a single per-skill row:
    /// an endless mode mints a new id every question, and storing each one
    /// would grow this dictionary without bound and drown the real items in
    /// the review queue.
    func record(itemID: String, roomID: String, correct: Bool, now: Date = Date()) {
        let key = PracticeSkill.skill(forItemID: itemID).map(\.rawValue) ?? itemID
        let isGenerated = PracticeSkill.skill(forItemID: itemID) != nil

        var record = records[key] ?? PracticeRecord()
        record.attempts += 1
        record.roomID = roomID
        record.lastAnswered = now
        if correct {
            record.correct += 1
            record.streak += 1
        } else {
            record.streak = 0
        }
        // Generated questions never repeat, so scheduling one for review is
        // meaningless. They contribute to accuracy stats only.
        if !isGenerated {
            schedule(&record, correct: correct, now: now)
        }
        records[key] = record
        persist()
    }

    /// SM-2, trimmed to what a drill app needs: a miss resets the interval and
    /// costs ease, a hit multiplies the interval by the current ease.
    private func schedule(_ record: inout PracticeRecord, correct: Bool, now: Date) {
        if correct {
            switch record.streak {
            case 1: record.intervalDays = 1
            case 2: record.intervalDays = 3
            default: record.intervalDays = min(record.intervalDays * record.ease, 180)
            }
            record.ease = min(record.ease + 0.1, 2.8)
        } else {
            record.intervalDays = 0
            record.ease = max(record.ease - 0.2, 1.3)
        }
        record.dueDate = now.addingTimeInterval(record.intervalDays * 86_400)
    }

    func recordChallengeScore(_ score: Int) {
        guard score > bestChallengeScore else { return }
        bestChallengeScore = score
        defaults.set(score, forKey: Keys.bestChallenge)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: Keys.records)
    }

    // MARK: - Review queue

    /// Item ids that are due for another look, worst first. "Worst" is lowest
    /// accuracy, then longest overdue, so the questions a player keeps getting
    /// wrong surface before the ones they nearly have.
    func reviewQueue(limit: Int = 12) -> [String] {
        records
            .filter { $0.value.needsReview && $0.value.isDue && PracticeSkill(rawValue: $0.key) == nil }
            .sorted { lhs, rhs in
                if lhs.value.accuracy != rhs.value.accuracy { return lhs.value.accuracy < rhs.value.accuracy }
                return lhs.value.dueDate < rhs.value.dueDate
            }
            .prefix(limit)
            .map(\.key)
    }

    /// How many items are waiting, for the Home card's badge.
    var dueCount: Int {
        records.filter { $0.value.needsReview && $0.value.isDue && PracticeSkill(rawValue: $0.key) == nil }.count
    }

    // MARK: - Stats

    struct RoomStat: Identifiable {
        let id: String
        let name: String
        let attempts: Int
        let correct: Int
        var accuracy: Double { attempts == 0 ? 0 : Double(correct) / Double(attempts) }
    }

    var totalAttempts: Int { records.values.reduce(0) { $0 + $1.attempts } }
    var totalCorrect: Int { records.values.reduce(0) { $0 + $1.correct } }
    var overallAccuracy: Double {
        totalAttempts == 0 ? 0 : Double(totalCorrect) / Double(totalAttempts)
    }

    /// Accuracy per room, in library order, skipping rooms never practised.
    func roomStats() -> [RoomStat] {
        DrillLibrary.rooms.compactMap { room in
            let mine = records.values.filter { $0.roomID == room.id }
            let attempts = mine.reduce(0) { $0 + $1.attempts }
            guard attempts > 0 else { return nil }
            return RoomStat(
                id: room.id,
                name: room.name,
                attempts: attempts,
                correct: mine.reduce(0) { $0 + $1.correct }
            )
        }
    }

    /// The room a player is worst at, once there is enough data to mean it.
    func weakestRoom() -> RoomStat? {
        roomStats().filter { $0.attempts >= 5 }.min { $0.accuracy < $1.accuracy }
    }

    func resetAll() {
        records = [:]
        bestChallengeScore = 0
        defaults.removeObject(forKey: Keys.records)
        defaults.removeObject(forKey: Keys.bestChallenge)
    }
}
