package com.jackwallner.bridge

import com.jackwallner.bridge.content.BridgeMinuteCategory
import com.jackwallner.bridge.content.BridgeMinuteContent
import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.content.EndlessPractice
import com.jackwallner.bridge.content.HandGenerator
import com.jackwallner.bridge.content.PracticeSkill
import com.jackwallner.bridge.content.QuickItem
import com.jackwallner.bridge.content.SessionBuilder
import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.model.BridgeCard.Companion.c
import com.jackwallner.bridge.model.BridgeCard.Companion.d
import com.jackwallner.bridge.model.BridgeCard.Companion.h
import com.jackwallner.bridge.model.BridgeCard.Companion.s
import com.jackwallner.bridge.model.ChoiceShuffle
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.HandCategory
import com.jackwallner.bridge.model.Rank.ACE
import com.jackwallner.bridge.model.Rank.EIGHT
import com.jackwallner.bridge.model.Rank.FIVE
import com.jackwallner.bridge.model.Rank.FOUR
import com.jackwallner.bridge.model.Rank.JACK
import com.jackwallner.bridge.model.Rank.KING
import com.jackwallner.bridge.model.Rank.NINE
import com.jackwallner.bridge.model.Rank.QUEEN
import com.jackwallner.bridge.model.Rank.SEVEN
import com.jackwallner.bridge.model.Rank.SIX
import com.jackwallner.bridge.model.Rank.TEN
import com.jackwallner.bridge.model.Rank.THREE
import com.jackwallner.bridge.model.Rank.TWO
import com.jackwallner.bridge.model.StableSeededGenerator
import com.jackwallner.bridge.model.highCardPoints
import com.jackwallner.bridge.model.racked
import com.jackwallner.bridge.model.shuffledSwift
import java.time.LocalDate
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Holds the Kotlin engine to the iOS output, plus ports of iOS
 * `HandGeneratorTests` and `BridgeMinuteContentTests`. The shared daily
 * challenge has to deal the same cards on both platforms.
 */
class GeneratorParityTest {
    private val parity = ParityFixtures.json

    private fun assertItem(label: String, expected: JSONObject, actual: QuickItem) {
        assertEquals(label, expected.getString("id"), actual.id)
        assertEquals(label, expected.getString("prompt"), actual.prompt)
        assertEquals(label, expected.getJSONArray("cards").strings(), codes(actual.cards))
        assertEquals(label, expected.getJSONArray("choices").strings(), actual.choices)
        assertEquals(label, expected.getInt("answerIndex"), actual.answerIndex)
        assertEquals(label, expected.getString("explanation"), actual.explanation)
        assertEquals(label, expected.getString("sourceLabel"), actual.sourceLabel)
        assertEquals(label, expected.getString("roomID"), actual.roomID)
        assertEquals(label, expected.getString("trackingID"), actual.trackingID)
        assertEquals(label, expected.getBoolean("isReviewable"), actual.isReviewable)
    }

    @Test
    fun seededStreamMatchesSwift() {
        val streams = parity.getJSONObject("streams")
        for (seed in streams.keys()) {
            val generator = StableSeededGenerator(seed)
            assertEquals("seed '$seed'", streams.getJSONArray(seed).strings(), (0 until 8).map { generator.next().toString() })
        }
    }

    @Test
    fun permutationsMatchSwift() {
        val permutations = parity.getJSONObject("permutations")
        for (key in permutations.keys()) {
            val (seed, count) = key.split("|")
            assertEquals(key, permutations.getJSONArray(key).ints(), ChoiceShuffle.permutation(count.toInt(), seed))
        }
    }

    @Test
    fun cardFactsMatchSwift() {
        val facts = parity.getJSONArray("cardFacts").objects()
        assertEquals(52, facts.size)
        assertEquals(facts.map { it.getString("code") }, codes(BridgeCard.fullDeck))
        for (json in facts) {
            val card = BridgeCard.fromCode(json.getString("code"))
            assertEquals(json.getString("short"), card.shortLabel)
            assertEquals(json.getString("spoken"), card.spokenName)
            assertEquals(json.getInt("hcp"), card.highCardPoints)
            assertEquals(json.getInt("sortKey"), card.sortKey)
        }
    }

    /** 600 seeded random deals: the classifier and its coaching line agree with Swift on every one. */
    @Test
    fun classifierMatchesSwift() {
        val rows = parity.getJSONArray("classifications").objects()
        assertEquals(600, rows.size)
        for (row in rows) {
            val cards = row.getJSONArray("cards").cards()
            val label = codes(cards).toString()
            assertEquals(label, row.getInt("hcp"), cards.highCardPoints)
            val opening = HandGenerator.opening(cards)
            if (row.has("opening")) {
                assertEquals(label, row.getString("opening"), opening?.raw)
                assertEquals(label, row.getString("explanation"), HandGenerator.explain(cards, opening!!))
            } else {
                assertNull(label, opening)
            }
        }
    }

    @Test
    fun seededDealerMatchesSwift() {
        // The same seeded dealer the fixture used, so the shuffle itself is pinned too.
        val dealer = StableSeededGenerator("classifier-parity")
        val rows = parity.getJSONArray("classifications").objects()
        for (row in rows.take(25)) {
            val dealt = BridgeCard.fullDeck.shuffledSwift(dealer).take(13).racked
            assertEquals(row.getJSONArray("cards").strings(), codes(dealt))
        }
    }

    @Test
    fun handBatchesMatchSwift() {
        val hands = parity.getJSONObject("hands")
        for (seed in hands.keys()) {
            val expected = hands.getJSONArray(seed).objects()
            val actual = HandGenerator.batch(7, seed)
            assertEquals(seed, expected.size, actual.size)
            expected.zip(actual).forEachIndexed { index, (json, hand) ->
                val label = "$seed #$index"
                assertEquals(label, json.getJSONArray("cards").strings(), codes(hand.cards))
                assertEquals(label, json.getString("answer"), hand.answer.raw)
                assertEquals(label, json.getString("explanation"), hand.explanation)
            }
        }
    }

    @Test
    fun bridgeMinuteMatchesSwift() {
        val minutes = parity.getJSONObject("minutes")
        for (day in minutes.keys()) {
            val expected = minutes.getJSONObject(day)
            val challenge = BridgeMinuteContent.challenge(LocalDate.parse(day))
            assertEquals(day, expected.getString("shortDate"), challenge.shortDate)
            val questions = expected.getJSONArray("questions").objects()
            assertEquals(day, questions.size, challenge.questions.size)
            questions.zip(challenge.questions).forEachIndexed { index, (json, question) ->
                assertEquals("$day #$index", json.getString("category"), question.category.raw)
                assertItem("$day #$index", json.getJSONObject("item"), question.item)
            }
        }
    }

    @Test
    fun preparedChoicePoolMatchesSwift() {
        val expected = parity.getJSONArray("memberPool").objects()
        val actual = DrillLibrary.rooms.flatMap { SessionBuilder.choiceItems(it.id, includePro = true) }.map(SessionBuilder::prepared)
        assertEquals(expected.size, actual.size)
        expected.zip(actual).forEach { (json, item) -> assertItem(item.id, json, item) }
    }

    // MARK: - iOS HandGeneratorTests: classifier

    @Test
    fun passesWeakHand() {
        val cards = listOf(s(QUEEN), s(SEVEN), s(FOUR), h(JACK), h(NINE), h(SIX), h(THREE), d(KING), d(EIGHT), d(FIVE), c(TEN), c(FOUR), c(TWO))
        assertEquals(6, cards.highCardPoints)
        assertEquals(HandCategory.PASS, HandGenerator.opening(cards))
    }

    @Test
    fun opensNotrumpOnBalancedFifteen() {
        val cards = listOf(s(ACE), s(QUEEN), s(SIX), h(KING), h(NINE), h(FOUR), d(QUEEN), d(JACK), d(SEVEN), d(TWO), c(KING), c(EIGHT), c(THREE))
        assertEquals(15, cards.highCardPoints)
        assertEquals(HandCategory.ONE_NOTRUMP, HandGenerator.opening(cards))
    }

    @Test
    fun opensLongerMinorWhenTooWeakForNotrump() {
        val cards = listOf(s(KING), s(NINE), s(FOUR), h(QUEEN), h(EIGHT), h(THREE), d(ACE), d(JACK), d(SEVEN), d(FIVE), c(KING), c(SIX), c(TWO))
        assertEquals(13, cards.highCardPoints)
        assertEquals(HandCategory.ONE_DIAMOND, HandGenerator.opening(cards))
    }

    @Test
    fun opensSixCardMajor() {
        val cards = listOf(s(QUEEN), s(FIVE), h(ACE), h(KING), h(JACK), h(NINE), h(SIX), h(THREE), d(KING), d(SEVEN), d(FOUR), c(EIGHT), c(TWO))
        assertEquals(HandCategory.ONE_HEART, HandGenerator.opening(cards))
    }

    /** 5-5 in the majors opens the higher ranking suit. */
    @Test
    fun prefersSpadesWithBothMajors() {
        val cards = listOf(s(ACE), s(KING), s(EIGHT), s(FIVE), s(TWO), h(QUEEN), h(JACK), h(NINE), h(SIX), h(THREE), d(KING), d(FOUR), c(SEVEN))
        assertEquals(HandCategory.ONE_SPADE, HandGenerator.opening(cards))
    }

    /** Strong hands belong to 2♣ and 2NT, so they must never reach a player. */
    @Test
    fun rejectsStrongHands() {
        val cards = listOf(s(ACE), s(KING), s(QUEEN), s(FOUR), h(ACE), h(KING), h(THREE), d(ACE), d(QUEEN), d(SIX), c(KING), c(FIVE), c(TWO))
        assertTrue(cards.highCardPoints >= 20)
        assertNull(HandGenerator.opening(cards))
    }

    @Test
    fun rejectsWrongCardCount() {
        assertNull(HandGenerator.opening(listOf(s(ACE), s(KING))))
    }

    // MARK: - iOS HandGeneratorTests: generation

    @Test
    fun generatedHandsAreSelfConsistent() {
        for (target in HandCategory.entries) {
            val hand = HandGenerator.hand(target)
            assertNotNull("Could not generate a hand for ${target.displayName}", hand)
            hand!!
            assertEquals(13, hand.cards.size)
            assertEquals(13, hand.cards.toSet().size)
            assertEquals(target, HandGenerator.opening(hand.cards))
            assertTrue(hand.explanation.isNotEmpty())
            assertFalse("No em dashes in copy", "\u2014" in hand.explanation)
        }
    }

    @Test
    fun batchCoversEveryAnswer() {
        val hands = HandGenerator.batch(60)
        assertTrue("Rejection sampling should still fill most of a batch", hands.size > 40)
        assertEquals(HandCategory.entries.toSet(), hands.map { it.answer }.toSet())
    }

    @Test
    fun endlessItemsAreWellFormed() {
        for (skill in PracticeSkill.entries) {
            val items = EndlessPractice.items(skill, 12)
            assertEquals("${skill.raw} came up short", 12, items.size)
            for (item in items) {
                assertTrue(item.id.startsWith(skill.itemPrefix))
                assertEquals(skill, PracticeSkill.skill(item.id))
                assertTrue(item.choices.size >= 2)
                assertTrue(item.answerIndex in item.choices.indices)
                assertEquals("Duplicate answer labels", item.choices.size, item.choices.toSet().size)
                assertTrue(item.explanation.isNotEmpty())
                assertTrue(item.roomID.isNotEmpty())
                assertNotNull(DrillLibrary.room(item.roomID))
            }
        }
    }

    @Test
    fun pointCountItemsGradeTheTrueCount() {
        for (item in EndlessPractice.items(PracticeSkill.POINT_COUNT, 40)) {
            assertEquals(13, item.cards.size)
            assertEquals(item.cards.highCardPoints.toString(), item.choices[item.answerIndex])
            assertTrue(item.cards.highCardPoints >= 3)
        }
    }

    @Test
    fun mixedItemsDrawFromEverySkill() {
        val items = EndlessPractice.mixedItems(40)
        assertEquals(40, items.size)
        assertEquals(PracticeSkill.entries.toSet(), items.mapNotNull { PracticeSkill.skill(it.id) }.toSet())
    }

    /**
     * iOS `testAuthoredHandsMatchTheClassifier`: the hand-written opening drills
     * must agree with the engine that grades Endless Practice.
     */
    @Test
    fun authoredHandsMatchTheClassifier() {
        val authored = DrillLibrary.rooms.flatMap { it.drills }.flatMap { (it.kind as? DrillKind.HandMatch)?.questions ?: emptyList() }
        assertTrue(authored.isNotEmpty())
        for (question in authored) {
            assertEquals("${question.id} is not a 13-card hand", 13, question.cards.size)
            assertEquals("${question.id} repeats a card", 13, question.cards.toSet().size)
            assertTrue("${question.id} cannot be answered", question.answer in question.choices)
            val classified = HandGenerator.opening(question.cards) ?: continue
            assertEquals("${question.id} disagrees with the classifier", question.answer, classified)
        }
    }

    // MARK: - iOS BridgeMinuteContentTests

    @Test
    fun challengeIsStableAndHasTheFiveQuestionMix() {
        val day = LocalDate.of(2026, 8, 9)
        val first = BridgeMinuteContent.challenge(day)
        val second = BridgeMinuteContent.challenge(day)
        assertEquals("2026-08-09", first.dayKey)
        assertEquals(first.items, second.items)
        val counts = first.questions.groupingBy { it.category }.eachCount()
        assertEquals(BridgeMinuteContent.QUESTION_COUNT, first.questions.size)
        assertEquals(2, counts[BridgeMinuteCategory.BIDDING])
        assertEquals(1, counts[BridgeMinuteCategory.DECLARER_PLAY])
        assertEquals(2, counts[BridgeMinuteCategory.DEFENSE])
        for (question in first.questions) {
            val item = question.item
            if (question.category == BridgeMinuteCategory.BIDDING) assertEquals(13, item.cards.size)
            assertTrue(item.choices.size >= 2)
            assertTrue(item.answerIndex in item.choices.indices)
            assertTrue(item.explanation.isNotEmpty() && "\u2014" !in item.explanation)
        }
        for (question in first.questions.filter { it.category == BridgeMinuteCategory.BIDDING }) {
            assertFalse(question.item.isReviewable)
            assertEquals(PracticeSkill.OPENINGS.raw, question.item.trackingID)
        }
    }

    /**
     * The daily declarer question comes from the authored Play scenarios, which
     * the quick-session pool leaves out, so every day still has declarer play.
     */
    @Test
    fun declarerQuestionComesFromPlayScenarios() {
        val scenarioIDs = DrillLibrary.rooms.flatMap { it.drills }
            .flatMap { (it.kind as? DrillKind.Play)?.scenarios ?: emptyList() }
            .map { it.situation }
        val pool = DrillLibrary.rooms.flatMap { SessionBuilder.choiceItems(it.id, includePro = true) }
        assertTrue(pool.none { it.roomID == "declarer-room" && it.cards.size in 2..4 && it.prompt.endsWith("Which card do you play?") })
        var day = LocalDate.of(2026, 10, 1)
        repeat(60) {
            val declarer = BridgeMinuteContent.challenge(day).questions.single { it.category == BridgeMinuteCategory.DECLARER_PLAY }.item
            assertTrue(declarer.prompt.endsWith(" Which card do you play?"))
            assertTrue(declarer.prompt.removeSuffix(" Which card do you play?") in scenarioIDs)
            assertEquals(declarer.cards.map { it.spokenName }.toSet(), declarer.choices.toSet())
            assertFalse(declarer.isReviewable)
            day = day.plusDays(1)
        }
    }

    /** A day that fails to deal fails for every player at once, so sweep five years of day keys. */
    @Test
    fun everyDaySeedDealsTheFullQuestionSet() {
        var day = LocalDate.of(2026, 1, 1)
        var checked = 0
        while (day.isBefore(LocalDate.of(2031, 1, 1))) {
            val key = BridgeMinuteContent.key(day)
            assertEquals(key, 2, HandGenerator.batch(2, "bridge-minute-$key-hands").size)
            checked += 1
            day = day.plusDays(1)
        }
        assertTrue(checked > 1800)
    }
}
