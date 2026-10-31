package com.jackwallner.bridge

import com.jackwallner.bridge.ui.screens.shouldHintSwipe
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of the iOS Reduce Motion fix for the flashcard swipe hint. */
class SwipeHintReduceMotionTest {
    @Test
    fun swipeHintIsSkippedWhenAnimationsAreOff() {
        assertTrue(shouldHintSwipe(reduceMotion = false, hasSwipedDeck = false, didHint = false, queueSize = 2))
        assertFalse(shouldHintSwipe(reduceMotion = true, hasSwipedDeck = false, didHint = false, queueSize = 2))
    }

    @Test
    fun swipeHintKeepsItsOtherGates() {
        assertFalse(shouldHintSwipe(false, hasSwipedDeck = true, didHint = false, queueSize = 2))
        assertFalse(shouldHintSwipe(false, hasSwipedDeck = false, didHint = true, queueSize = 2))
        assertFalse(shouldHintSwipe(false, hasSwipedDeck = false, didHint = false, queueSize = 1))
    }
}
