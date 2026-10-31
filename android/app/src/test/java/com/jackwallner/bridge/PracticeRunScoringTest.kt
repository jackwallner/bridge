package com.jackwallner.bridge

import com.jackwallner.bridge.content.PracticeSkill
import com.jackwallner.bridge.ui.nav.PracticeMode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Port of the iOS BR-02 tests: Close on Fix My Mistakes before answering was a finished drill. */
class PracticeRunScoringTest {
    private val modes = listOf(PracticeMode.Review, PracticeMode.Timed, PracticeMode.Endless(PracticeSkill.entries[0]))

    @Test
    fun runClosedBeforeAnyAnswerIsNotACompletedDrill() {
        modes.forEach { assertNull("$it", it.completionTotal(0)) }
    }

    @Test
    fun runClosedEarlyIsScoredOutOfWhatWasAnswered() {
        modes.forEach {
            assertEquals("$it", 3, it.completionTotal(3))
            assertEquals("$it", 8, it.completionTotal(8))
        }
    }
}
