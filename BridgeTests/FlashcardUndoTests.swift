import XCTest

@testable import Bridge

/// "Undo last answer" on a plain flashcard swipe used to rewind only the deck:
/// the undone grade stayed in Your Progress, so swiping left by mistake, then
/// Undo, then right counted two attempts. The deck now snapshots the item
/// before the swipe grades it and puts that back on Undo. These replay the
/// view's store calls (commit, then undo, then commit).
@MainActor
final class FlashcardUndoTests: XCTestCase {
    private func defaults(_ tag: String = #function) -> UserDefaults {
        UserDefaults(suiteName: "FlashcardUndoTests.\(tag).\(UUID().uuidString)")!
    }

    private var plainCardID: String {
        DrillLibrary.rooms.flatMap(\.drills).compactMap { drill -> String? in
            guard case .flashcards(let cards) = drill.kind else { return nil }
            return cards.first { $0.choice == nil }?.id
        }.first!
    }

    func testUndoneSwipeLeavesOnlyTheFinalAnswer() {
        let suite = defaults()
        let records = PracticeRecordStore(defaults: suite)
        let progress = ProgressStore(defaults: suite)
        let id = plainCardID

        // First swipe: "again", by mistake.
        let before = records.snapshot(itemID: id)
        let wasSeen = progress.seenItems.contains(id)
        let wasMissed = progress.missedItems.contains(id)
        progress.recordItem(id: id, correct: false)
        records.record(itemID: id, roomID: "card-room", correct: false)
        // Undo.
        progress.restoreItem(id: id, seen: wasSeen, missed: wasMissed)
        records.restore(itemID: id, to: before)
        // Second swipe: "knew it".
        progress.recordItem(id: id, correct: true)
        records.record(itemID: id, roomID: "card-room", correct: true)

        let record = records.records[id]
        XCTAssertEqual(record?.attempts, 1, "undone swipe still counted")
        XCTAssertEqual(record?.correct, 1)
        XCTAssertEqual(record?.streak, 1)
        XCTAssertFalse(progress.missedItems.contains(id), "undone miss still marks the card missed")
        XCTAssertTrue(progress.seenItems.contains(id))

        // The retraction is what a relaunch reads, not only what is in memory.
        XCTAssertEqual(PracticeRecordStore(defaults: suite).records[id]?.attempts, 1)
        XCTAssertFalse(ProgressStore(defaults: suite).missedItems.contains(id))
    }

    func testUndoKeepsEarlierHistory() {
        let records = PracticeRecordStore(defaults: defaults())
        let id = plainCardID
        records.record(itemID: id, roomID: "card-room", correct: true)
        records.record(itemID: id, roomID: "card-room", correct: true)

        let before = records.snapshot(itemID: id)
        records.record(itemID: id, roomID: "card-room", correct: false)
        records.restore(itemID: id, to: before)

        XCTAssertEqual(records.records[id]?.attempts, 2)
        XCTAssertEqual(records.records[id]?.streak, 2, "an undone miss broke the streak")
    }
}
