package com.jackwallner.bridge

import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.content.HandGenerator
import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.model.BridgeRules
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.Rank
import com.jackwallner.bridge.model.Suit
import com.jackwallner.bridge.model.highCardPoints
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RulesAuditTest {
    private fun reference() = JSONObject(javaClass.getResourceAsStream("/rules-reference.json")!!.bufferedReader().readText())
    @Test fun duplicateScoringTable() {
        val quizzes = DrillLibrary.rooms.flatMap { it.drills }.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }
        for (r in reference().getJSONArray("scores").objects()) {
            assertEquals(r.toString(), r.getInt("score"),
                BridgeRules.score(r.getInt("level"), r.getInt("strain"), r.getInt("multiplier"), r.getInt("tricks"), r.getBoolean("vulnerable")))
            if (r.has("lessonId")) {
                val question = quizzes.first { it.id == r.getString("lessonId") }
                assertEquals(question.id, r.getInt("score"), question.choices[question.answerIndex].toInt())
            }
        }
    }
    @Test fun legalAuctionsAndPassedOutHands() {
        for (r in reference().getJSONArray("auctions").objects()) {
            val actual = BridgeRules.auction(r.getJSONArray("calls").strings())!!
            assertEquals(r.toString(), r.getBoolean("ended"), actual.ended)
            assertEquals(if (r.isNull("declarer")) null else r.getInt("declarer"), actual.declarer)
            assertEquals(r.getInt("level"), actual.level)
            assertEquals(r.getInt("multiplier"), actual.multiplier)
        }
        for (text in reference().getJSONArray("invalidAuctions").strings()) assertNull(text, BridgeRules.auction(text.split(" ")))
    }
    @Test fun followingAndTrickWinners() {
        for (r in reference().getJSONArray("legal").objects()) {
            val hand = r.getJSONArray("hand").strings().map(BridgeCard::fromCode)
            val expected = r.getJSONArray("expected").strings().map(BridgeCard::fromCode)
            assertEquals(expected, BridgeRules.legal(hand, Suit.entries.first { it.raw == r.getString("led") }))
        }
        for (r in reference().getJSONArray("tricks").objects()) {
            val trump = if (r.isNull("trump")) null else Suit.entries.first { it.raw == r.getString("trump") }
            assertEquals(r.getInt("winner"), BridgeRules.winner(r.getJSONArray("cards").strings().map(BridgeCard::fromCode), trump))
        }
    }
    @Test fun saycOpeningsAndTeachingCounts() {
        val hands = DrillLibrary.rooms.flatMap { it.drills }.flatMap { (it.kind as? DrillKind.HandMatch)?.questions.orEmpty() }
        val counts = mapOf("hand-one-spade" to 14, "hand-one-heart" to 14, "hand-one-nt-16" to 16,
            "hand-one-diamond" to 16, "plus-open-spade-six" to 13, "plus-open-club" to 14)
        for ((id, hcp) in counts) {
            val hand = hands.first { it.id == id }
            assertEquals(id, hcp, hand.cards.highCardPoints)
            assertTrue(id, hand.explanation.contains(hcp.toString()))
            assertEquals(id, hand.answer, HandGenerator.opening(hand.cards))
        }
        for ((lengths, balanced) in listOf(listOf(4, 3, 3, 3) to true, listOf(4, 4, 3, 2) to true, listOf(5, 3, 3, 2) to true,
            listOf(5, 4, 2, 2) to false, listOf(6, 3, 2, 2) to false, listOf(4, 4, 4, 1) to false)) {
            val cards = Suit.entries.zip(lengths).flatMap { (suit, count) -> Rank.entries.take(count).map { BridgeCard(it, suit) } }
            assertEquals(balanced, HandGenerator.Shape(cards).isBalanced)
        }
        for ((count, suit) in listOf(3 to Suit.CLUBS, 4 to Suit.DIAMONDS, 5 to Suit.DIAMONDS)) {
            val cards = listOf(Suit.CLUBS, Suit.DIAMONDS).flatMap { s -> Rank.entries.take(count).map { BridgeCard(it, s) } }
            assertEquals(suit, HandGenerator.Shape(cards).longerMinor)
        }
        for (row in reference().getJSONArray("openings").objects()) {
            val expected = if (row.isNull("answer")) null else row.getString("answer")
            assertEquals(expected, HandGenerator.opening(row.getJSONArray("cards").strings().map(BridgeCard::fromCode))?.raw)
        }
        assertNull(HandGenerator.opening(List(13) { BridgeCard.s(Rank.ACE) }))
    }
    @Test fun gradedAdviceMatchesTheDisplayedPosition() {
        val drills = DrillLibrary.rooms.flatMap { it.drills }
        val scenarios = drills.flatMap { (it.kind as? DrillKind.Play)?.scenarios.orEmpty() }
        for ((id, previous) in listOf("pro-play-safety" to listOf("C2", "C10", "CJ"), "play-win-cheaply" to listOf("C4", "C6", "C9"))) {
            val scenario = scenarios.first { it.id == id }
            val winners = scenario.cards.indices.filter { BridgeRules.winner(previous.map(BridgeCard::fromCode) + scenario.cards[it], null) == 3 }
            assertEquals(scenario.answerIndex, winners.minBy { scenario.cards[it].rank.sortOrder })
            assertTrue(scenario.situation.contains("fourth"))
        }
        val quiz = drills.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }
        val game = quiz.first { it.id == "pro-game-major" }
        assertTrue(game.prompt.contains("lowest"))
        assertEquals("4♥", game.choices[game.answerIndex])
        val cards = drills.flatMap { (it.kind as? DrillKind.Flashcards)?.cards.orEmpty() }
        val hands = drills.flatMap { (it.kind as? DrillKind.HandMatch)?.questions.orEmpty() }
        for (row in reference().getJSONArray("teaching").objects()) {
            val id = row.getString("id")
            val copy = cards.firstOrNull { it.id == id }?.backBody ?: hands.first { it.id == id }.explanation
            for (text in row.getJSONArray("includes").strings()) assertTrue("$id: $text", copy.contains(text))
            for (text in row.getJSONArray("excludes").strings()) assertFalse("$id: $text", copy.contains(text))
        }
    }
}
