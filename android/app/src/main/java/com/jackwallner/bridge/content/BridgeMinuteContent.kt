package com.jackwallner.bridge.content

import com.jackwallner.bridge.model.ChoiceShuffle
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.HandCategory
import com.jackwallner.bridge.model.StableSeededGenerator
import java.time.LocalDate
import java.util.Locale

enum class BridgeMinuteCategory(val raw: String, val title: String, val icon: String) {
    BIDDING("bidding", "Bidding", "quote.bubble.fill"),
    DECLARER_PLAY("declarerPlay", "Declarer Play", "suit.spade.fill"),
    DEFENSE("defense", "Defense", "shield.lefthalf.filled"),
}

data class BridgeMinuteQuestion(val category: BridgeMinuteCategory, val item: QuickItem)

data class BridgeMinuteChallenge(
    val day: LocalDate,
    val dayKey: String,
    val shortDate: String,
    val questions: List<BridgeMinuteQuestion>,
) {
    val items: List<QuickItem> get() = questions.map { it.item }
}

/**
 * One shared five-question set per calendar date, identical to the iOS set for
 * the same date: two generated opening calls, one declarer decision and two
 * defensive judgments, all picked with the same seeds as iOS.
 */
object BridgeMinuteContent {
    const val QUESTION_COUNT = 5

    val drill = Drill("bridge-minute", "Bridge Minute", "Today's shared five-question challenge", DrillKind.Quiz(emptyList()), isPlus = true)

    fun key(day: LocalDate): String = String.format(Locale.US, "%04d-%02d-%02d", day.year, day.monthValue, day.dayOfMonth)

    fun challenge(day: LocalDate = LocalDate.now()): BridgeMinuteChallenge {
        val dayKey = key(day)
        val auction = auctionQuestions(dayKey)
        val declarer = listOfNotNull(declarerQuestion(dayKey))
        val defense = roomQuestions(dayKey, "defense-room", BridgeMinuteCategory.DEFENSE, 2)
        // Interleaved so the run does not feel like three separate quizzes.
        val questions = buildList {
            auction.getOrNull(0)?.let(::add)
            addAll(declarer)
            defense.getOrNull(0)?.let(::add)
            auction.getOrNull(1)?.let(::add)
            defense.getOrNull(1)?.let(::add)
        }
        val shortDate = String.format(Locale.US, "%02d/%02d", day.monthValue, day.dayOfMonth)
        return BridgeMinuteChallenge(day, dayKey, shortDate, questions)
    }

    private fun auctionQuestions(dayKey: String): List<BridgeMinuteQuestion> =
        HandGenerator.batch(2, "bridge-minute-$dayKey-hands").mapIndexed { index, hand ->
            val item = QuickItem(
                id = PracticeSkill.OPENINGS.itemPrefix + "minute-$dayKey-$index",
                prompt = "What is your opening call?",
                cards = hand.cards,
                choices = HandCategory.entries.map { it.displayName },
                answerIndex = HandCategory.entries.indexOf(hand.answer).coerceAtLeast(0),
                explanation = hand.explanation,
                sourceLabel = "Bridge Minute: Opening",
                roomID = PracticeSkill.OPENINGS.roomID,
                trackingID = PracticeSkill.OPENINGS.raw,
                isReviewable = false,
            )
            BridgeMinuteQuestion(BridgeMinuteCategory.BIDDING, SessionBuilder.prepared(item))
        }

    /**
     * Declarer play is built straight from the authored Play scenarios, never
     * through `SessionBuilder.choiceItems`: the quick-session pool leaves Play
     * drills out, so drawing from it would drop declarer play from the daily.
     */
    private fun declarerQuestion(dayKey: String): BridgeMinuteQuestion? {
        val scenarios = DrillLibrary.rooms.flatMap { room ->
            room.drills.flatMap { (it.kind as? DrillKind.Play)?.scenarios ?: emptyList() }
        }
        if (scenarios.isEmpty()) return null
        val generator = StableSeededGenerator("bridge-minute-$dayKey-declarer")
        val scenario = scenarios[(generator.next() % scenarios.size.toULong()).toInt()]
        if (scenario.answerIndex !in scenario.cards.indices) return null
        val item = QuickItem(
            id = "bridge-minute-declarer-$dayKey",
            prompt = "${scenario.situation} Which card do you play?",
            cards = scenario.cards,
            choices = scenario.cards.map { it.spokenName },
            answerIndex = scenario.answerIndex,
            explanation = scenario.reasoning,
            sourceLabel = "Bridge Minute: Declarer Play",
            roomID = "declarer-room",
            trackingID = "bridge-minute-declarer",
            isReviewable = false,
        )
        return BridgeMinuteQuestion(BridgeMinuteCategory.DECLARER_PLAY, SessionBuilder.prepared(item))
    }

    /** Authored questions from one room, picked by a permutation of the day key. */
    private fun roomQuestions(dayKey: String, roomID: String, category: BridgeMinuteCategory, count: Int): List<BridgeMinuteQuestion> {
        val pool = SessionBuilder.choiceItems(roomID, includePro = true)
        if (pool.isEmpty()) return emptyList()
        val indices = ChoiceShuffle.permutation(pool.size, "bridge-minute-$dayKey-$roomID")
        return indices.take(count).map { BridgeMinuteQuestion(category, SessionBuilder.prepared(pool[it])) }
    }
}
