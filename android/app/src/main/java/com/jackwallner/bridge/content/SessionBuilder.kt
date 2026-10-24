package com.jackwallner.bridge.content

import com.jackwallner.bridge.model.ChoiceShuffle
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.model.racked

/**
 * One normalized, single-select item inside a session, built from whichever
 * choice-gradeable content is behind it.
 */
data class QuickItem(
    val id: String,
    val prompt: String,
    val cards: List<BridgeCard>,
    val choices: List<String>,
    val answerIndex: Int,
    val explanation: String,
    /** e.g. "The Card Room", shown as a small tag above the prompt. */
    val sourceLabel: String,
    val roomID: String,
    /** The persistence row this answer contributes to. */
    val trackingID: String = id,
    /** False for one-off generated prompts that can never come back in review. */
    val isReviewable: Boolean = true,
)

/**
 * Builds the choice sessions: missed items first, unseen next, review last.
 * Plain flip cards and Play scenarios stay out; they are not right or
 * wrong in one tap.
 */
object SessionBuilder {
    /** Only these authored items can be replayed by the review runner. */
    val reviewableItemIDs: Set<String> by lazy { choicePool(true).map { it.id }.toSet() }

    val sessionDrill = Drill("quick-session", "Quick Session", "A short mix of what you need next", DrillKind.Flashcards(emptyList()))
    val reviewDrill = Drill("review-session", "Fix My Mistakes", "The questions you keep getting wrong", DrillKind.Flashcards(emptyList()))
    val gameNightPrepDrill = Drill("game-night-prep", "Game Night Prep", "A five-minute mix for your next table", DrillKind.Flashcards(emptyList()))

    fun quickSession(count: Int = 10, seen: Set<String>, missed: Set<String>, includePro: Boolean): List<QuickItem> {
        fun tier(item: QuickItem) = when {
            item.id in missed -> 0
            item.id !in seen -> 1
            else -> 2
        }
        return choicePool(includePro).shuffled().sortedBy(::tier).take(count).map(::prepared)
    }

    /** Exactly the items the scheduler says are due, in its order. Never padded. */
    fun reviewSession(ids: List<String>, includePro: Boolean): List<QuickItem> {
        val pool = choicePool(includePro).associateBy { it.id }
        return ids.mapNotNull { pool[it] }.map(::prepared)
    }

    /** Due mistakes lead, then misses, then the weakest room, then unseen material. */
    fun gameNightPrep(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        dueIDs: List<String>,
        weakestRoomID: String?,
    ): List<QuickItem> {
        val due = dueIDs.toSet()
        fun tier(item: QuickItem) = when {
            item.id in due -> 0
            item.id in missed -> 1
            item.roomID == weakestRoomID -> 2
            item.id !in seen -> 3
            else -> 4
        }
        return choicePool(true).shuffled().sortedBy(::tier).take(count).map(::prepared)
    }

    /** How many due items can still be served; ids go stale when content is renamed. */
    fun reviewSessionCount(ids: List<String>, includePro: Boolean): Int = reviewSession(ids, includePro).size

    fun choiceItems(roomID: String, includePro: Boolean): List<QuickItem> =
        choicePool(includePro).filter { it.roomID == roomID }

    /** Answer-position variety, stable per item id. */
    fun prepared(item: QuickItem): QuickItem {
        val permutation = ChoiceShuffle.permutation(item.choices.size, item.id)
        val labels = permutation.map { item.choices[it] }
        val answer = permutation.indexOf(item.answerIndex).takeIf { it >= 0 } ?: item.answerIndex
        return item.copy(choices = labels, answerIndex = answer)
    }

    private fun choicePool(includePro: Boolean): List<QuickItem> {
        val pool = mutableListOf<QuickItem>()
        for (room in DrillLibrary.rooms) {
            if (!room.isFree && !includePro) continue
            for (drill in room.drills) {
                if (room.isLocked(drill, includePro)) continue
                when (val kind = drill.kind) {
                    is DrillKind.Quiz -> pool += kind.questions.map { question ->
                        QuickItem(
                            id = question.id,
                            prompt = question.prompt,
                            cards = question.cards,
                            choices = question.choices,
                            answerIndex = question.answerIndex,
                            explanation = question.explanation,
                            sourceLabel = room.name,
                            roomID = room.id,
                        )
                    }
                    is DrillKind.HandMatch -> pool += kind.questions.map { question ->
                        QuickItem(
                            id = question.id,
                            prompt = "What is the best opening call?",
                            cards = question.cards.racked,
                            choices = question.choices.map { it.displayName },
                            answerIndex = question.choices.indexOf(question.answer).coerceAtLeast(0),
                            explanation = question.explanation,
                            sourceLabel = room.name,
                            roomID = room.id,
                        )
                    }
                    is DrillKind.Flashcards -> pool += kind.cards.mapNotNull { card ->
                        val choice = card.choice ?: return@mapNotNull null
                        QuickItem(
                            id = card.id,
                            prompt = card.frontSubtitle?.let { "${card.frontTitle}\n$it" } ?: card.frontTitle,
                            cards = card.frontCards,
                            choices = choice.options,
                            answerIndex = choice.answerIndex,
                            explanation = card.backBody,
                            sourceLabel = room.name,
                            roomID = room.id,
                        )
                    }
                    // Too interaction-heavy for a quick, uniform choice flow.
                    is DrillKind.Play -> Unit
                }
            }
        }
        return pool
    }
}
