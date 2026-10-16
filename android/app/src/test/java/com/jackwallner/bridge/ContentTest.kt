package com.jackwallner.bridge

import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.content.HowToPlayContent
import com.jackwallner.bridge.content.SessionBuilder
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.Flashcard
import com.jackwallner.bridge.model.HandMatchQuestion
import com.jackwallner.bridge.model.PlayScenario
import com.jackwallner.bridge.model.QuizQuestion
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of iOS `ContentValidityTests`, run against the exported content the app ships. */
class ContentTest {
    private val drills = DrillLibrary.rooms.flatMap { it.drills }
    private val handMatch: List<HandMatchQuestion> = drills.flatMap { (it.kind as? DrillKind.HandMatch)?.questions.orEmpty() }
    private val quiz: List<QuizQuestion> = drills.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }
    private val plays: List<PlayScenario> = drills.flatMap { (it.kind as? DrillKind.Play)?.scenarios.orEmpty() }
    private val flashcards: List<Flashcard> = drills.flatMap { (it.kind as? DrillKind.Flashcards)?.cards.orEmpty() }

    @Test
    fun countsMatchIos() {
        val expected = ParityFixtures.json.getJSONObject("drillCounts")
        assertEquals(expected.length(), drills.size)
        for (drill in drills) assertEquals(drill.id, expected.getInt(drill.id), drill.kind.itemCount)
        assertEquals(listOf("card-room", "auction-room", "declarer-room", "defense-room", "master-tables"), DrillLibrary.rooms.map { it.id })
        assertEquals(ParityFixtures.json.getInt("lockedDrillCount"), DrillLibrary.rooms.sumOf { it.plusDrillCount })
        assertEquals(6, HowToPlayContent.pages.size)
    }

    /** iOS `testOpeningHandsAreLegalThirteenCardHands`. */
    @Test
    fun openingHandsAreLegalThirteenCardHands() {
        for (question in handMatch) {
            assertEquals(question.id, 13, question.cards.size)
            assertEquals("${question.id} contains a duplicate physical card", 13, question.cards.toSet().size)
            assertTrue("${question.id} answer missing from choices", question.answer in question.choices)
            assertEquals("${question.id} has duplicate choices", question.choices.size, question.choices.toSet().size)
        }
    }

    @Test
    fun playScenariosAreAnswerable() {
        assertTrue(plays.isNotEmpty())
        for (scenario in plays) {
            assertTrue("${scenario.id} needs playable cards", scenario.cards.isNotEmpty())
            assertTrue("${scenario.id} answer is out of range", scenario.answerIndex in scenario.cards.indices)
            assertEquals("${scenario.id} contains duplicate choices", scenario.cards.size, scenario.cards.toSet().size)
        }
    }

    @Test
    fun quizAndCardChoicesAreValid() {
        for (question in quiz) {
            assertTrue(question.id, question.answerIndex in question.choices.indices)
            assertTrue(question.id, question.choices.size >= 2)
            assertEquals(question.id, question.choices.size, question.choices.toSet().size)
        }
        for (card in flashcards) {
            val choice = card.choice ?: continue
            assertEquals(card.id, 2, choice.options.size)
            assertTrue(card.id, choice.answerIndex in choice.options.indices)
            assertEquals(card.id, 2, choice.options.toSet().size)
        }
    }

    @Test
    fun allContentIDsAreUnique() {
        val ids = DrillLibrary.rooms.flatMap { room ->
            listOf(room.id) + room.drills.flatMap { drill ->
                listOf(drill.id) + when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.map { it.id }
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.HandMatch -> kind.questions.map { it.id }
                    is DrillKind.Play -> kind.scenarios.map { it.id }
                }
            }
        }
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test
    fun freeBeginnerModelIsIntact() {
        assertTrue(DrillLibrary.rooms.first().isFree)
        for (room in DrillLibrary.rooms) {
            assertTrue(room.id, room.drills.isNotEmpty())
            for (drill in room.drills) assertTrue(drill.id, drill.kind.itemCount > 0)
            if (room.id == "master-tables") {
                assertFalse(room.isFree)
            } else {
                assertTrue(room.isFree)
                assertEquals(room.id, 1, room.drills.count { it.isPlus })
            }
            for (drill in room.drills) {
                assertFalse(room.isLocked(drill, isMember = true))
                assertEquals(!room.isFree || drill.isPlus, room.isLocked(drill, isMember = false))
            }
        }
    }

    @Test
    fun noEmDashesOrStaleTileCopy() {
        val copy = mutableListOf<String>()
        for (room in DrillLibrary.rooms) {
            copy += listOf(room.name, room.tagline)
            for (drill in room.drills) {
                copy += listOf(drill.title, drill.subtitle)
                when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.forEach {
                        copy += listOf(it.frontTitle, it.frontSubtitle.orEmpty(), it.backTitle, it.backBody) + it.choice?.options.orEmpty()
                    }
                    is DrillKind.Quiz -> kind.questions.forEach { copy += listOf(it.prompt, it.explanation) + it.choices }
                    is DrillKind.HandMatch -> kind.questions.forEach { copy += it.explanation }
                    is DrillKind.Play -> kind.scenarios.forEach { copy += listOf(it.situation, it.reasoning, it.tip) }
                }
            }
        }
        HowToPlayContent.pages.forEach { copy += listOf(it.title, it.body, it.tip.orEmpty()) }
        for (text in copy) {
            assertFalse("Em dash: $text", "\u2014" in text)
            assertFalse("Stale tile copy: $text", text.contains("tile", ignoreCase = true))
            assertFalse("Stale mahjong copy: $text", text.contains("mahj", ignoreCase = true))
            assertFalse("Implied affiliation: $text", text.contains("ACBL", ignoreCase = true))
        }
    }

    @Test
    fun primerPagesHaveUniqueIDsAndDistinctCards() {
        val pages = HowToPlayContent.pages
        assertEquals(pages.size, pages.map { it.id }.toSet().size)
        for (page in pages) assertEquals(page.id, page.cards.size, page.cards.toSet().size)
        assertEquals("card-room", HowToPlayContent.recommendedRoom("new").id)
        assertEquals("auction-room", HowToPlayContent.recommendedRoom("basics").id)
        assertEquals("declarer-room", HowToPlayContent.recommendedRoom("played").id)
    }

    private val lockedItemIDs: Set<String> by lazy {
        DrillLibrary.rooms.flatMap { room ->
            room.drills.filter { room.isLocked(it, isMember = false) }.flatMap { drill ->
                when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.map { it.id }
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.HandMatch -> kind.questions.map { it.id }
                    is DrillKind.Play -> kind.scenarios.map { it.id }
                }
            }
        }.toSet()
    }

    @Test
    fun quickSessionPullsTenAndPrioritizesMisses() {
        val mix = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = false)
        assertEquals(10, mix.size)
        assertEquals(10, mix.map { it.id }.toSet().size)
        val missed = mix[0].id
        assertTrue(SessionBuilder.quickSession(seen = setOf(missed), missed = setOf(missed), includePro = false).any { it.id == missed })
    }

    @Test
    fun quickSessionRespectsThePaidBoundary() {
        assertTrue(lockedItemIDs.isNotEmpty())
        val free = SessionBuilder.quickSession(200, emptySet(), emptySet(), includePro = false)
        for (item in free) assertFalse("${item.id} leaked", item.id in lockedItemIDs)
        val member = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        assertTrue(member.any { it.id in lockedItemIDs })
        val freeIDs = ParityFixtures.json.getJSONArray("freePoolIDs").strings().toSet()
        assertEquals(freeIDs, free.map { it.id }.toSet())
    }

    @Test
    fun quickSessionItemsAreChoiceOnly() {
        val plainCards = flashcards.filter { it.choice == null }.map { it.id }.toSet()
        val playIDs = plays.map { it.id }.toSet()
        for (item in SessionBuilder.quickSession(200, emptySet(), emptySet(), includePro = true)) {
            assertTrue(item.choices.size >= 2)
            assertTrue(item.answerIndex in item.choices.indices)
            assertFalse(item.id in plainCards)
            assertFalse(item.id in playIDs)
        }
    }

    @Test
    fun gameNightPrepLeadsWithDueThenWeakestRoom() {
        val pool = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        val due = pool.first { it.roomID == "master-tables" }.id
        val prep = SessionBuilder.gameNightPrep(seen = emptySet(), missed = emptySet(), dueIDs = listOf(due), weakestRoomID = "defense-room")
        assertEquals(10, prep.size)
        assertEquals(due, prep.first().id)
        assertTrue(prep.drop(1).take(9).all { it.roomID == "defense-room" })
    }

    @Test
    fun reviewSessionKeepsSchedulerOrderAndDropsLockedItems() {
        val member = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        val locked = member.first { it.id in lockedItemIDs }.id
        val free = member.first { it.id !in lockedItemIDs }.id
        assertEquals(listOf(locked, free), SessionBuilder.reviewSession(listOf(locked, free), includePro = true).map { it.id })
        assertEquals(listOf(free), SessionBuilder.reviewSession(listOf(locked, free), includePro = false).map { it.id })
    }
}
