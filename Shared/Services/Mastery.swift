import Foundation

/// How well a room is actually known, as opposed to how much of it has been
/// opened.
///
/// The room ring used to count drills the player had started, which rewards
/// tapping rather than learning: finish every drill once, badly, and the room
/// reads as done forever. Mastery is coverage times durability instead. An
/// item counts as known only after two correct answers in a row, and it stops
/// counting when its spaced-repetition interval has lapsed far enough that the
/// player would probably miss it today.
enum MasteryLevel: Int, Comparable, Sendable {
    case untouched
    case learning
    case solid
    case sharp

    static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .untouched: return "Not started"
        case .learning: return "Learning"
        case .solid: return "Solid"
        case .sharp: return "Sharp"
        }
    }

    var icon: String {
        switch self {
        case .untouched: return "circle.dotted"
        case .learning: return "book.fill"
        case .solid: return "checkmark.seal.fill"
        case .sharp: return "star.fill"
        }
    }

    /// What earns the next level, phrased as the thing to go do.
    var nextStep: String {
        switch self {
        case .untouched: return "Answer a few questions here to start tracking."
        case .learning: return "Get each question right twice running to lock it in."
        case .solid: return "Keep going. Sharp means nearly everything here is holding."
        case .sharp: return "Come back now and then so it stays sharp."
        }
    }
}

/// One room's mastery, ready to render.
struct RoomMastery: Identifiable, Sendable {
    let roomID: String
    let known: Int
    let total: Int
    let level: MasteryLevel

    var id: String { roomID }

    var fraction: Double {
        total == 0 ? 0 : Double(known) / Double(total)
    }
}

extension MasteryLevel {
    /// Thresholds are on coverage, not raw accuracy: a player who has answered
    /// three questions perfectly does not know the room.
    /// `attempted` is how many items have been answered at all. A room
    /// practised but not yet locked in is Learning, not "New": quiz drills show
    /// each question once a run, so a player could ace a whole room and still
    /// see it read as untouched.
    static func level(known: Int, total: Int, attempted: Int = 0) -> MasteryLevel {
        guard total > 0 else { return .untouched }
        guard known > 0 else { return attempted > 0 ? .learning : .untouched }
        let fraction = Double(known) / Double(total)
        switch fraction {
        case 0.85...: return .sharp
        case 0.4..<0.85: return .solid
        default: return .learning
        }
    }
}

extension PracticeRecord {
    /// Known means answered right twice in a row and not yet gone stale.
    ///
    /// Staleness is generous on purpose. The review scheduler wants an item
    /// back the moment it is due; mastery should not evaporate the same day,
    /// or a player who practises weekly watches their rooms un-learn
    /// themselves. An item only stops counting once it is a full interval
    /// past due.
    func isKnown(now: Date = Date()) -> Bool {
        guard streak >= 2 else { return false }
        guard intervalDays > 0 else { return true }
        let lapse = dueDate.addingTimeInterval(intervalDays * 86_400)
        return now < lapse
    }
}

extension PracticeRecordStore {

    /// Mastery for one room, measured against the items this player can
    /// actually reach. Locked Bridge+ sets are excluded for a free player, the
    /// same way the old completion ring excluded them: a denominator nobody
    /// can close is a nag, not a goal.
    func mastery(for room: Room, isMember: Bool, now: Date = Date()) -> RoomMastery {
        let ids = Set(Self.trackableItemIDs(in: room, isMember: isMember))
        guard !ids.isEmpty else {
            return RoomMastery(roomID: room.id, known: 0, total: 0, level: .untouched)
        }
        let known = ids.filter { records[$0]?.isKnown(now: now) == true }.count
        let attempted = ids.filter { records[$0] != nil }.count
        return RoomMastery(
            roomID: room.id,
            known: known,
            total: ids.count,
            level: MasteryLevel.level(known: known, total: ids.count, attempted: attempted)
        )
    }

    func masteryByRoom(isMember: Bool, now: Date = Date()) -> [RoomMastery] {
        DrillLibrary.rooms.map { mastery(for: $0, isMember: isMember, now: now) }
    }

    /// The room worth working on next: the least-mastered room that has been
    /// started at all. A room the player has never opened is not a weakness,
    /// it is just new, and pointing them at it teaches nothing about where
    /// they are actually shaky.
    func roomToWorkOn(isMember: Bool, now: Date = Date()) -> RoomMastery? {
        masteryByRoom(isMember: isMember, now: now)
            .filter { $0.level != .untouched && $0.level != .sharp }
            .min { $0.fraction < $1.fraction }
    }

    /// Every gradeable item id in a room, counting the ones this player can
    /// open. Declarer play scenarios are included: they are graded and
    /// recorded like anything else.
    static func trackableItemIDs(in room: Room, isMember: Bool) -> [String] {
        var ids: [String] = []
        for drill in room.drills where !room.isLocked(drill, isMember: isMember) {
            switch drill.kind {
            case .quiz(let questions): ids += questions.map(\.id)
            case .handMatch(let questions): ids += questions.map(\.id)
            case .play(let scenarios): ids += scenarios.map(\.id)
            case .flashcards(let cards): ids += cards.compactMap { $0.choice == nil ? nil : $0.id }
            }
        }
        return ids
    }
}
