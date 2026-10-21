package com.jackwallner.bridge.content

import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.HandCategory
import com.jackwallner.bridge.model.Rank
import com.jackwallner.bridge.model.highCardPoints
import com.jackwallner.bridge.model.racked
import java.util.UUID

/** Generated practice skills. Each one becomes the same QuickItem shape as authored drills. */
enum class PracticeSkill(val raw: String, val title: String, val subtitle: String, val icon: String, val roomID: String) {
    OPENINGS("openings", "Name Your Opening", "Freshly dealt hands, unlimited reps", "quote.bubble.fill", "auction-room"),
    POINT_COUNT("pointCount", "Count the Points", "Add up a hand at a glance", "number.circle.fill", "auction-room");

    /** Every generated item carries this prefix so stats roll it up into one row. */
    val itemPrefix: String get() = "gen-$raw-"

    companion object {
        fun fromRaw(raw: String): PracticeSkill? = entries.firstOrNull { it.raw == raw }

        fun skill(forItemID: String): PracticeSkill? = entries.firstOrNull { forItemID.startsWith(it.itemPrefix) }
    }
}

object EndlessPractice {
    fun drill(skill: PracticeSkill) = Drill("endless-${skill.raw}", skill.title, skill.subtitle, DrillKind.Quiz(emptyList()))

    val challengeDrill = Drill("timed-challenge", "Timed Challenge", "Beat the clock", DrillKind.Quiz(emptyList()))

    fun items(skill: PracticeSkill, count: Int): List<QuickItem> = when (skill) {
        PracticeSkill.OPENINGS -> openingItems(count)
        PracticeSkill.POINT_COUNT -> pointCountItems(count)
    }

    /** A mixed batch across every skill, for the timed challenge. */
    fun mixedItems(count: Int): List<QuickItem> {
        val skills = PracticeSkill.entries
        val perSkill = maxOf(1, count / skills.size + 1)
        return skills.flatMap { items(it, perSkill) }.shuffled().take(count)
    }

    private fun newID(skill: PracticeSkill) = skill.itemPrefix + UUID.randomUUID().toString().uppercase()

    private fun openingItems(count: Int): List<QuickItem> = HandGenerator.batch(count).map { hand ->
        QuickItem(
            id = newID(PracticeSkill.OPENINGS),
            prompt = "What is your opening call?",
            cards = hand.cards,
            choices = HandCategory.entries.map { it.displayName },
            answerIndex = HandCategory.entries.indexOf(hand.answer).coerceAtLeast(0),
            explanation = hand.explanation,
            sourceLabel = "Endless Practice",
            roomID = PracticeSkill.OPENINGS.roomID,
        )
    }

    /** Deal a hand, ask for its points. Distractors sit next to the true count. */
    private fun pointCountItems(count: Int): List<QuickItem> {
        val items = mutableListOf<QuickItem>()
        while (items.size < count) {
            val cards = BridgeCard.fullDeck.shuffled().take(13).racked
            val hcp = cards.highCardPoints
            // A hand with no honors at all is a trick question, not a drill.
            if (hcp < 3) continue
            val values = sortedSetOf(hcp)
            for (offset in listOf(-2, -1, 1, 2).shuffled().take(3)) {
                if (hcp + offset >= 0) values += hcp + offset
            }
            val sorted = values.toList()
            items += QuickItem(
                id = newID(PracticeSkill.POINT_COUNT),
                prompt = "How many high-card points is this hand worth?",
                cards = cards,
                choices = sorted.map { it.toString() },
                answerIndex = sorted.indexOf(hcp),
                explanation = pointExplanation(cards, hcp),
                sourceLabel = "Endless Practice",
                roomID = PracticeSkill.POINT_COUNT.roomID,
            )
        }
        return items
    }

    fun pointExplanation(cards: List<BridgeCard>, total: Int): String {
        val parts = listOf(Rank.ACE to 4, Rank.KING to 3, Rank.QUEEN to 2, Rank.JACK to 1).mapNotNull { (rank, value) ->
            val held = cards.count { it.rank == rank }
            if (held == 0) null else "$held ${rank.spokenName.lowercase()}${if (held == 1) "" else "s"} at $value"
        }
        val breakdown = if (parts.isEmpty()) "no honors" else parts.joinToString(", ")
        return "$breakdown. That totals $total high-card points. Aces 4, kings 3, queens 2, jacks 1."
    }
}
