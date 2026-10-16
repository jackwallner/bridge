package com.jackwallner.bridge.content

import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.model.HandCategory
import com.jackwallner.bridge.model.RandomSource
import com.jackwallner.bridge.model.StableSeededGenerator
import com.jackwallner.bridge.model.Suit
import com.jackwallner.bridge.model.SystemRandomSource
import com.jackwallner.bridge.model.highCardPoints
import com.jackwallner.bridge.model.racked
import com.jackwallner.bridge.model.shuffledSwift

/**
 * Port of iOS `HandGenerator`: deals random 13-card hands and names the
 * beginner Standard American opening call for them. The classifier returns
 * null for anything a beginner table would argue about, and generation is
 * rejection sampling on top, so a hand only reaches a player when exactly one
 * of the six `HandCategory` answers is right. Every draw comes from the
 * RandomSource in the same order as the Swift original, so a seeded batch
 * deals the same cards as iOS (`GeneratorParityTest`).
 */
object HandGenerator {

    /** Suit lengths and the derived facts every rule below asks about. */
    class Shape(cards: List<BridgeCard>) {
        private val lengths: Map<Suit, Int> = Suit.entries.associateWith { suit -> cards.count { it.suit == suit } }
        val highCardPoints: Int = cards.highCardPoints

        fun length(suit: Suit): Int = lengths[suit] ?: 0

        val sortedLengths: List<Int> get() = lengths.values.sortedDescending()

        /** No void, no singleton, at most one doubleton: 4333, 4432, 5332. */
        val isBalanced: Boolean
            get() = lengths.values.count { it < 2 } == 0 && lengths.values.count { it == 2 } <= 1

        val longestMajor: Suit?
            get() {
                val best = maxOf(length(Suit.HEARTS), length(Suit.SPADES))
                if (best < 5) return null
                // 5-5 and 6-6 in the majors: open the higher ranking one.
                return if (length(Suit.SPADES) == best) Suit.SPADES else Suit.HEARTS
            }

        val hasFiveCardMajor: Boolean get() = longestMajor != null

        /** Equal minors go to diamonds except 3-3, the classic short club. */
        val longerMinor: Suit
            get() {
                val clubs = length(Suit.CLUBS)
                val diamonds = length(Suit.DIAMONDS)
                return when {
                    diamonds > clubs -> Suit.DIAMONDS
                    clubs > diamonds -> Suit.CLUBS
                    clubs == 3 -> Suit.CLUBS
                    else -> Suit.DIAMONDS
                }
            }

        /** Points plus the two longest suits. */
        val ruleOfTwenty: Int get() = highCardPoints + sortedLengths.take(2).sum()

        /** "5-3-3-2" for the explanation line. */
        val pattern: String get() = sortedLengths.joinToString("-")
    }

    /** The opening call, or null when the hand is outside the six answers or a judgment call. */
    fun opening(cards: List<BridgeCard>): HandCategory? {
        if (cards.size != 13) return null
        val shape = Shape(cards)
        val hcp = shape.highCardPoints
        // Strong hands open 2♣ or 2NT. Neither is an answer here.
        if (hcp >= 20) return null
        if (hcp < 12) {
            // Only the hands nobody opens are safe to grade as Pass.
            if (hcp > 10 || shape.ruleOfTwenty >= 20 || shape.sortedLengths[0] > 5) return null
            return HandCategory.PASS
        }
        if (hcp in 15..17 && shape.isBalanced) {
            // A balanced 15-17 with a five-card major splits the room. Skip it.
            return if (shape.hasFiveCardMajor) null else HandCategory.ONE_NOTRUMP
        }
        shape.longestMajor?.let { return if (it == Suit.SPADES) HandCategory.ONE_SPADE else HandCategory.ONE_HEART }
        return if (shape.longerMinor == Suit.DIAMONDS) HandCategory.ONE_DIAMOND else HandCategory.ONE_CLUB
    }

    data class GeneratedHand(val cards: List<BridgeCard>, val answer: HandCategory, val explanation: String)

    /** Deals until the hand classifies as `target`. */
    fun hand(target: HandCategory, attempts: Int = 400, source: RandomSource = SystemRandomSource): GeneratedHand? {
        repeat(attempts) {
            val cards = BridgeCard.fullDeck.shuffledSwift(source).take(13).racked
            if (opening(cards) == target) return GeneratedHand(cards, target, explain(cards, target))
        }
        return null
    }

    /** A batch spread across the six answers, shuffled. */
    fun batch(count: Int): List<GeneratedHand> = batch(count, SystemRandomSource)

    /** A reproducible batch: the same seed deals the same hands as iOS on every device. */
    fun batch(count: Int, seed: String): List<GeneratedHand> = batch(count, StableSeededGenerator(seed))

    private fun batch(count: Int, source: RandomSource): List<GeneratedHand> {
        val targets = mutableListOf<HandCategory>()
        while (targets.size < count) targets += HandCategory.entries.shuffledSwift(source)
        return targets.take(count).mapNotNull { hand(it, source = source) }.shuffledSwift(source)
    }

    /** The coaching line under a graded answer: it names the two facts that decided the call. */
    fun explain(cards: List<BridgeCard>, answer: HandCategory): String {
        val shape = Shape(cards)
        val hcp = shape.highCardPoints
        val points = "$hcp high-card point${if (hcp == 1) "" else "s"}"
        return when (answer) {
            HandCategory.PASS ->
                "$points, ${shape.pattern}. You need about 12 to open at the one level, so pass and wait for your partner."
            HandCategory.ONE_NOTRUMP ->
                "$points and a balanced ${shape.pattern} with no five-card major. That is the 15 to 17 notrump range, so open 1NT and describe the whole hand in one call."
            HandCategory.ONE_HEART, HandCategory.ONE_SPADE -> {
                val suit = if (answer == HandCategory.ONE_SPADE) Suit.SPADES else Suit.HEARTS
                var line = "$points with ${shape.length(suit)} ${suit.displayName.lowercase()}. With 12 or more and a five-card major, open the major: ${answer.displayName}."
                if (shape.length(Suit.SPADES) >= 5 && shape.length(Suit.HEARTS) >= 5) {
                    line += " Holding five of each major, start with the higher ranking suit."
                }
                line
            }
            HandCategory.ONE_CLUB, HandCategory.ONE_DIAMOND -> {
                var line = "$points, ${shape.pattern}, no five-card major"
                if (shape.isBalanced && hcp !in 15..17) line += " and outside the 15 to 17 notrump range"
                line += ". Open your longer minor: ${answer.displayName}."
                if (shape.length(Suit.CLUBS) == shape.length(Suit.DIAMONDS)) {
                    line += if (shape.length(Suit.CLUBS) == 3) {
                        " With three of each minor the convention is the short club."
                    } else {
                        " With equal length in the minors, open the higher ranking one."
                    }
                }
                line
            }
        }
    }
}
