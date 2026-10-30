import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var streakCount: Int
    @Published private(set) var totalSessions: Int
    @Published private(set) var completions: [String: Int]
    @Published private(set) var seenItems: Set<String>
    @Published private(set) var missedItems: Set<String>

    private let defaults: UserDefaults

    private enum Keys {
        static let streakCount = "progress.streakCount"
        static let lastActiveDay = "progress.lastActiveDay"
        static let totalSessions = "progress.totalSessions"
        static let completions = "progress.completions"
        static let hasOnboarded = "progress.hasOnboarded"
        static let reviewGateShown = "progress.reviewGateShown"
        static let seenItems = "progress.seenItems"
        static let missedItems = "progress.missedItems"
        static let lastQuickSessionDay = "progress.lastQuickSessionDay"
        static let sessionsAtOnboarding = "progress.sessionsAtOnboarding"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        streakCount = defaults.integer(forKey: Keys.streakCount)
        totalSessions = defaults.integer(forKey: Keys.totalSessions)
        completions = (defaults.dictionary(forKey: Keys.completions) as? [String: Int]) ?? [:]
        seenItems = Set(defaults.stringArray(forKey: Keys.seenItems) ?? [])
        missedItems = Set(defaults.stringArray(forKey: Keys.missedItems) ?? [])
    }

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Keys.hasOnboarded) }
        set { defaults.set(newValue, forKey: Keys.hasOnboarded) }
    }

    /// Sessions finished before onboarding ended: the tour's closing
    /// practice. Players who onboarded earlier have none stored (0).
    var sessionsAtOnboarding: Int {
        get { defaults.integer(forKey: Keys.sessionsAtOnboarding) }
        set { defaults.set(newValue, forKey: Keys.sessionsAtOnboarding) }
    }

    /// True once the player has finished a practice of their own after
    /// onboarding. Home's extras (later the challenge card) wait for it, so the
    /// first Home after the tour is the plain lobby.
    var hasPracticedSinceOnboarding: Bool { totalSessions > sessionsAtOnboarding }

    func completions(for drillID: String) -> Int {
        completions[drillID] ?? 0
    }

    func roomProgress(_ room: Room) -> Double {
        guard !room.drills.isEmpty else { return 0 }
        let done = room.drills.filter { completions(for: $0.id) > 0 }.count
        return Double(done) / Double(room.drills.count)
    }

    func recordSession(drillID: String, now: Date = Date()) {
        completions[drillID, default: 0] += 1
        totalSessions += 1
        bumpStreak(now: now)
        defaults.set(completions, forKey: Keys.completions)
        defaults.set(totalSessions, forKey: Keys.totalSessions)
    }

    /// The streak as it stands right now. `streakCount` only changes when a
    /// drill is finished, so after a missed day it still held the old number
    /// and Home showed a streak the player had already lost.
    func currentStreak(now: Date = Date()) -> Int {
        guard let last = storedDay(Keys.lastActiveDay) else { return streakCount }
        return dayGap(from: last, to: now) > 1 ? 0 : streakCount
    }

    /// Streak counts consecutive calendar days with at least one finished drill.
    private func bumpStreak(now: Date) {
        if let last = storedDay(Keys.lastActiveDay) {
            let gap = dayGap(from: last, to: now)
            if gap == 1 {
                streakCount += 1
            } else if gap > 1 {
                streakCount = 1
            } else if gap < 0 {
                // The clock went backwards (travel, a manual change). Keep the
                // later day so the streak is not counted twice on the way back.
                return
            } // gap == 0: same day, streak unchanged
        } else {
            streakCount = 1
        }
        defaults.set(MasteryLedger.dayKey(now), forKey: Keys.lastActiveDay)
        defaults.set(streakCount, forKey: Keys.streakCount)
    }

    /// Days are stored as local calendar day keys, not instants: an instant
    /// saved at New York midnight is the evening before in Chicago, so a
    /// westward trip read as a missed day. Older builds stored the
    /// instant, which still reads the old way.
    private func storedDay(_ key: String) -> Date? {
        let calendar = Calendar.gregorianLocal
        if let dayKey = defaults.string(forKey: key) {
            let parts = dayKey.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        }
        return (defaults.object(forKey: key) as? Date).map(calendar.startOfDay)
    }

    private func dayGap(from day: Date, to now: Date) -> Int {
        let calendar = Calendar.gregorianLocal
        return calendar.dateComponents([.day], from: day, to: calendar.startOfDay(for: now)).day ?? 0
    }

    /// Item-level memory that feeds the Get Started mix: anything answered wrong
    /// (or self-graded "again") comes back first; unseen items come next.
    func recordItem(id: String, correct: Bool) {
        seenItems.insert(id)
        if correct {
            missedItems.remove(id)
        } else {
            missedItems.insert(id)
        }
        defaults.set(Array(seenItems), forKey: Keys.seenItems)
        defaults.set(Array(missedItems), forKey: Keys.missedItems)
    }

    // MARK: - Daily Quick Session

    /// Get Started is a once-a-day ritual: a fresh mix each day, and once
    /// today's is done the Home card rests until tomorrow rather than handing
    /// back the same questions (repeating a question you just answered teaches
    /// nothing). Missed items still return on later days as spaced repetition.
    func quickSessionCompletedToday(now: Date = Date()) -> Bool {
        guard let last = storedDay(Keys.lastQuickSessionDay) else { return false }
        return dayGap(from: last, to: now) == 0
    }

    func markQuickSessionCompleted(now: Date = Date()) {
        defaults.set(MasteryLedger.dayKey(now), forKey: Keys.lastQuickSessionDay)
    }

    /// Clears every practice stat. Leaves onboarding and purchases alone.
    func resetAll() {
        streakCount = 0
        totalSessions = 0
        completions = [:]
        seenItems = []
        missedItems = []
        defaults.removeObject(forKey: Keys.streakCount)
        defaults.removeObject(forKey: Keys.lastActiveDay)
        defaults.removeObject(forKey: Keys.totalSessions)
        defaults.removeObject(forKey: Keys.completions)
        defaults.removeObject(forKey: Keys.seenItems)
        defaults.removeObject(forKey: Keys.missedItems)
        defaults.removeObject(forKey: Keys.reviewGateShown)
        defaults.removeObject(forKey: Keys.lastQuickSessionDay)
        defaults.removeObject(forKey: Keys.sessionsAtOnboarding)
    }
}
