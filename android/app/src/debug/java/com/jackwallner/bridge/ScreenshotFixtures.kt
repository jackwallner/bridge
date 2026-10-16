package com.jackwallner.bridge

import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.model.DrillKind

/** A believable week of practice for screenshots: real items, real grading paths. */
object ScreenshotFixtures {
    fun seed(graph: AppGraph) {
        DrillLibrary.rooms.filter { it.isFree }.take(3).forEachIndexed { roomIndex, room ->
            val ids = room.drills.filter { !it.isPlus }.flatMap { it.kind.itemIDs }
            // Each room lands at a different accuracy, so the stats read like a real player.
            ids.forEachIndexed { index, id ->
                val correct = (index + roomIndex) % (roomIndex + 3) != 0
                graph.progress.recordItem(id, correct)
                graph.records.record(id, room.id, correct)
            }
            room.drills.first().let { graph.progress.recordSession(it.id) }
        }
        graph.records.recordChallengeScore(14)
    }

    private val DrillKind.itemIDs: List<String>
        get() = when (this) {
            is DrillKind.Flashcards -> cards.map { it.id }
            is DrillKind.Quiz -> questions.map { it.id }
            is DrillKind.HandMatch -> questions.map { it.id }
            is DrillKind.Play -> scenarios.map { it.id }
        }
}
