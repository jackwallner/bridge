package com.jackwallner.bridge

import com.jackwallner.bridge.content.EndlessPractice
import com.jackwallner.bridge.content.PracticeSkill
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of the iOS point count test: the answer's place among the sorted choices must not give it away. */
class PointCountChoicesTest {
    @Test
    fun answerCanSitAnywhereInTheChoices() {
        val items = EndlessPractice.items(PracticeSkill.POINT_COUNT, 400)
        val positions = IntArray(4)
        items.forEach {
            assertEquals(4, it.choices.size)
            positions[it.answerIndex] += 1
        }
        positions.forEach { assertTrue(positions.joinToString(), it > items.size / 8) }
    }
}
