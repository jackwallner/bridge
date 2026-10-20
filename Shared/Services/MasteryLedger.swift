import Foundation

/// A daily record of how many questions were holding, per room, so the app
/// can say "up 14 since last week" instead of only showing a ring that moves
/// too slowly to notice.
///
/// Rings and bars show a level. A level does not tell a player in their first
/// week whether the practice is working, and the first week is when most of
/// them decide. The delta does.
@MainActor
final class MasteryLedger: ObservableObject {
    static let shared = MasteryLedger()

    /// day key ("2026-10-11") → room id → questions known that day.
    @Published private(set) var days: [String: [String: Int]]

    private let defaults: UserDefaults
    private static let key = "mastery.ledger"
    private static let retentionDays = 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            days = decoded
        } else {
            days = [:]
        }
    }

    /// Writes today's totals. Idempotent within a day: the latest call wins,
    /// so the record always reflects the end of the day's practice.
    func record(_ mastery: [RoomMastery], now: Date = Date()) {
        var byRoom: [String: Int] = [:]
        for room in mastery { byRoom[room.roomID] = room.known }
        let key = Self.dayKey(now)
        if days[key] == byRoom { return }
        days[key] = byRoom
        prune(now: now)
        persist()
    }

    /// Questions locked in over the last `window` days, or nil when there is
    /// no earlier day to measure from. Negative deltas (items gone stale) are
    /// reported as nil: the chip is a nudge, not a scold.
    func weeklyGain(window: Int = 7, now: Date = Date()) -> Int? {
        guard let baseline = baselineDay(window: window, now: now) else { return nil }
        let today = days[Self.dayKey(now)] ?? latestEntry(now: now) ?? [:]
        let gain = total(today) - total(baseline.value)
        return gain > 0 ? gain : nil
    }

    /// The room that gained the most over the window, for a sentence like
    /// "mostly in the Card Room".
    func strongestRoom(window: Int = 7, now: Date = Date()) -> (roomID: String, gain: Int)? {
        guard let baseline = baselineDay(window: window, now: now) else { return nil }
        let today = days[Self.dayKey(now)] ?? latestEntry(now: now) ?? [:]
        var best: (String, Int)?
        for (room, known) in today {
            let gain = known - (baseline.value[room] ?? 0)
            if gain > 0, gain > (best?.1 ?? 0) { best = (room, gain) }
        }
        return best.map { (roomID: $0.0, gain: $0.1) }
    }

    func resetAll() {
        days = [:]
        defaults.removeObject(forKey: Self.key)
    }

    // MARK: - Internals

    /// The oldest entry inside the window that is not today. "Inside the
    /// window" means a baseline from last Monday, not from the day the app
    /// was installed in July.
    private func baselineDay(window: Int, now: Date) -> (key: String, value: [String: Int])? {
        let todayKey = Self.dayKey(now)
        let earliest = Self.dayKey(now.addingTimeInterval(-TimeInterval(window) * 86_400))
        return days
            .filter { $0.key >= earliest && $0.key < todayKey }
            .min { $0.key < $1.key }
            .map { (key: $0.key, value: $0.value) }
    }

    private func latestEntry(now: Date) -> [String: Int]? {
        days.max { $0.key < $1.key }?.value
    }

    private func total(_ byRoom: [String: Int]) -> Int {
        byRoom.values.reduce(0, +)
    }

    private func prune(now: Date) {
        let cutoff = Self.dayKey(now.addingTimeInterval(-TimeInterval(Self.retentionDays) * 86_400))
        days = days.filter { $0.key >= cutoff }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(days) else { return }
        defaults.set(data, forKey: Self.key)
    }

    nonisolated static func dayKey(_ date: Date) -> String {
        let parts = Calendar.gregorianLocal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
