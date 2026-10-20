#if DEBUG
import SwiftUI

/// Unattended iPhone Duo capture (gh-sim launch --device 'iPhone Duo').
/// DEBUG only, so none of it ships.
///
/// `-DuoSeed` fills the real stores with a believable week of practice (no
/// network, no RevenueCat). `-DuoTour` then walks Home through `-DuoRoutes a,b`
/// on a timer, because `simctl openurl` raises a confirmation sheet and the
/// capture job cannot tap. `-DuoTourStep <s>` is the dwell per route and
/// `-DuoTourFirst <s>` the delay before the first; `-DuoTourStepRegular <s>`
/// overrides the dwell at regular width (the inner display). The tour restarts when the
/// size class changes, so folded and unfolded each get the full walk.
///
/// Routes: home, quick, room-<id>, drill-<id>, stats, endless, minute, prep,
/// timed, howto, settings, paywall.
enum DuoScreenshotMode {
    private static let arguments = ProcessInfo.processInfo.arguments

    static var isSeeded: Bool { arguments.contains("-DuoSeed") }
    static var wantsTour: Bool { arguments.contains("-DuoTour") }

    static func value(_ key: String) -> String? {
        guard let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    /// A week of practice, spread over the rooms so the rings and the
    /// Your Progress cards each have something to say.
    @MainActor
    static func seedIfNeeded() {
        guard isSeeded else { return }
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "progress.hasOnboarded")
        defaults.set(true, forKey: "bridge.hasReadPrimer")
        defaults.set("some", forKey: "bridge.skillLevel")
        defaults.set(true, forKey: "subscription.localProOverride")

        let progress = ProgressStore.shared
        let records = PracticeRecordStore.shared
        let day: TimeInterval = 86_400
        let now = Date()

        let finished = ["meet-cards", "card-check", "opening-playbook", "opening-bid", "play-plan", "choose-card", "defense-calls"]
        for (offset, drillID) in finished.enumerated() {
            progress.recordSession(drillID: drillID, now: now.addingTimeInterval(-Double(finished.count - 1 - offset) * day))
        }

        // How much of each room is locked in; the last room is left untouched.
        let known: [String: Double] = [
            "card-room": 0.9, "auction-room": 0.6, "declarer-room": 0.35, "defense-room": 0.15,
        ]
        for room in DrillLibrary.rooms {
            let ids = PracticeRecordStore.trackableItemIDs(in: room, isMember: true)
            let locked = Int(Double(ids.count) * (known[room.id] ?? 0))
            for (n, id) in ids.enumerated() {
                let when = now.addingTimeInterval(-day)
                if n < locked {
                    records.record(itemID: id, roomID: room.id, correct: true, now: when)
                    records.record(itemID: id, roomID: room.id, correct: true, now: when)
                } else if n < locked + 3, known[room.id] != nil {
                    records.record(itemID: id, roomID: room.id, correct: false, now: when)
                }
                progress.recordItem(id: id, correct: n < locked)
            }
        }
        records.recordChallengeScore(14)
    }

    enum Route: Hashable {
        case quick
        case room(String)
        case drill(String)
        case stats, endless, minute, prep, timed, howto
    }

    @MainActor @ViewBuilder
    static func destination(_ route: Route, progress: ProgressStore, subscriptions: SubscriptionService) -> some View {
        switch route {
        case .quick:
            QuickSessionView(items: SessionBuilder.quickSession(
                seen: progress.seenItems, missed: progress.missedItems, includePro: subscriptions.isPro))
        case .room(let id):
            if let room = DrillLibrary.room(id: id) { RoomView(room: room) }
        case .drill(let id):
            drillView(id)
        case .stats: StatsView()
        case .endless: EndlessPickerView()
        case .minute: BridgeMinuteView()
        case .prep: GameNightPrepView()
        case .timed: PracticeRunView(mode: .timed)
        case .howto: HowToPlayView()
        }
    }

    @MainActor @ViewBuilder
    private static func drillView(_ id: String) -> some View {
        if let room = DrillLibrary.rooms.first(where: { $0.drills.contains { $0.id == id } }),
           let drill = room.drills.first(where: { $0.id == id }) {
            switch drill.kind {
            case .flashcards(let cards): FlashcardDrillView(drill: drill, cards: cards, accent: room.accent)
            case .quiz(let questions): QuizDrillView(drill: drill, questions: questions)
            case .handMatch(let questions): HandMatchDrillView(drill: drill, questions: questions)
            case .play(let scenarios): PlayDrillView(drill: drill, scenarios: scenarios)
            }
        }
    }
}

extension HomeView {
    /// Walks `-DuoRoutes` (default: the whole app). Sheets close first and the
    /// previous push pops, so every route is shown from a clean Home.
    @MainActor
    func runDuoTour() async {
        guard DuoScreenshotMode.wantsTour else { return }
        // The inner display's screenshots are slower, so it may want a longer dwell.
        let stepKey = horizontalSizeClass == .regular ? "-DuoTourStepRegular" : "-DuoTourStep"
        let step = Double(DuoScreenshotMode.value(stepKey) ?? DuoScreenshotMode.value("-DuoTourStep") ?? "") ?? 10
        let first = Double(DuoScreenshotMode.value("-DuoTourFirst") ?? "") ?? 2
        let routes = (DuoScreenshotMode.value("-DuoRoutes") ?? Self.defaultDuoRoutes)
            .split(separator: ",").map(String.init)
        try? await Task.sleep(nanoseconds: UInt64(first * 1_000_000_000))
        for route in routes {
            if Task.isCancelled { return }
            NSLog("DUOTOUR %@ route=%@", horizontalSizeClass == .regular ? "inner" : "outer", route)
            await openDuoRoute(route)
            try? await Task.sleep(nanoseconds: UInt64(step * 1_000_000_000))
        }
    }

    static let defaultDuoRoutes =
        "home,quick,room-auction-room,drill-opening-bid,drill-choose-card,stats,endless,minute,prep,howto,settings,paywall"

    @MainActor
    private func openDuoRoute(_ route: String) async {
        setDuoSheets(settings: false, paywall: false)
        duoRoute = nil
        try? await Task.sleep(nanoseconds: 700_000_000)
        switch route {
        case "settings": setDuoSheets(settings: true, paywall: false)
        case "paywall": setDuoSheets(settings: false, paywall: true)
        case "quick": duoRoute = .quick
        case "stats": duoRoute = .stats
        case "endless": duoRoute = .endless
        case "minute": duoRoute = .minute
        case "prep": duoRoute = .prep
        case "timed": duoRoute = .timed
        case "howto": duoRoute = .howto
        case _ where route.hasPrefix("room-"): duoRoute = .room(String(route.dropFirst(5)))
        case _ where route.hasPrefix("drill-"): duoRoute = .drill(String(route.dropFirst(6)))
        default: break
        }
    }
}
#endif
