import Foundation

/// Play a Hand's local state: the deal rotation, the one free hand a day, and
/// a hand in progress.
///
/// A free player gets one whole hand a calendar day, the Mahj rule: a mode
/// nobody has tried sells nothing, and a complete hand is a real use of it
/// rather than a teaser. The free hand is spent at the first call, and the
/// hand is saved after every step so a back-swipe or a closed app never
/// spends it for nothing.
@MainActor
final class HandPlayStore: ObservableObject {
    static let shared = HandPlayStore()

    @Published private(set) var handsPlayed: Int
    @Published private(set) var lastFreeDay: String
    @Published private(set) var nextDeal: Int
    @Published private(set) var inProgress: HandPlayState?

    private let defaults: UserDefaults

    private enum Keys {
        static let handsPlayed = "handplay.handsPlayed"
        static let lastFreeDay = "handplay.lastFreeDay"
        static let nextDeal = "handplay.nextDeal"
        static let inProgress = "handplay.inProgress"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        // `-handplay.reset YES` starts the gate's journeys from a fresh first hand.
        if defaults.bool(forKey: "handplay.reset") {
            for key in [Keys.handsPlayed, Keys.lastFreeDay, Keys.nextDeal, Keys.inProgress] {
                defaults.removeObject(forKey: key)
            }
        }
        #endif
        handsPlayed = defaults.integer(forKey: Keys.handsPlayed)
        lastFreeDay = defaults.string(forKey: Keys.lastFreeDay) ?? ""
        nextDeal = defaults.integer(forKey: Keys.nextDeal)
        if let data = defaults.data(forKey: Keys.inProgress),
           let state = try? JSONDecoder().decode(HandPlayState.self, from: data),
           HandPlayContent.deal(id: state.dealID) != nil {
            inProgress = state
        }
    }

    static func dayKey(for date: Date, calendar: Calendar = .gregorianLocal) -> String {
        BridgeMinuteContent.key(for: date, calendar: calendar)
    }

    /// A hand already started is always playable. Otherwise members always,
    /// free players once a calendar day.
    func canPlay(isMember: Bool, now: Date = Date(), calendar: Calendar = .gregorianLocal) -> Bool {
        inProgress != nil || isMember || lastFreeDay != Self.dayKey(for: now, calendar: calendar)
    }

    /// The saved hand, or the next deal in the rotation.
    func currentState() -> HandPlayState {
        if let inProgress { return inProgress }
        let deals = HandPlayContent.deals
        return HandPlayEngine(deal: deals[nextDeal % deals.count]).state
    }

    /// Saves the hand. The first save of a hand spends a free player's day.
    func save(_ state: HandPlayState, isMember: Bool, now: Date = Date(), calendar: Calendar = .gregorianLocal) {
        if inProgress == nil, !isMember {
            lastFreeDay = Self.dayKey(for: now, calendar: calendar)
            defaults.set(lastFreeDay, forKey: Keys.lastFreeDay)
        }
        inProgress = state
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Keys.inProgress)
        }
    }

    /// Clears the finished hand and moves the rotation on.
    func finish() {
        guard inProgress != nil else { return }
        inProgress = nil
        defaults.removeObject(forKey: Keys.inProgress)
        handsPlayed += 1
        defaults.set(handsPlayed, forKey: Keys.handsPlayed)
        nextDeal = (nextDeal + 1) % HandPlayContent.deals.count
        defaults.set(nextDeal, forKey: Keys.nextDeal)
    }
}
