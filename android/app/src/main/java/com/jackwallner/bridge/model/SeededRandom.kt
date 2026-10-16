package com.jackwallner.bridge.model

import java.security.SecureRandom

/**
 * A source of 64-bit values, the Kotlin side of Swift's
 * `RandomNumberGenerator`. The helpers below reproduce the Swift standard
 * library's algorithms exactly (Lemire's bounded draw, its Fisher-Yates
 * shuffle), so a seeded stream deals the same cards on Android as on iOS.
 */
interface RandomSource {
    fun next(): ULong
}

/** FNV-1a seeded xorshift64*, identical to iOS `StableSeededGenerator`. */
class StableSeededGenerator(seed: String) : RandomSource {
    private var state: ULong

    init {
        var hash = 0xcbf29ce484222325uL
        for (byte in seed.toByteArray(Charsets.UTF_8)) {
            hash = hash xor (byte.toUByte().toULong())
            hash *= 0x100000001b3uL
        }
        state = if (hash == 0uL) 0x9E3779B97F4A7C15uL else hash
    }

    override fun next(): ULong {
        state = state xor (state shl 13)
        state = state xor (state shr 7)
        state = state xor (state shl 17)
        return state * 2685821657736338717uL
    }
}

object SystemRandomSource : RandomSource {
    private val random = SecureRandom()
    override fun next(): ULong = random.nextLong().toULong()
}

private fun multiplyHigh(a: ULong, b: ULong): ULong {
    val mask = 0xffffffffuL
    val aLo = a and mask
    val aHi = a shr 32
    val bLo = b and mask
    val bHi = b shr 32
    val loLo = aLo * bLo
    val hiLo = aHi * bLo
    val loHi = aLo * bHi
    val hiHi = aHi * bHi
    val cross = (loLo shr 32) + (hiLo and mask) + loHi
    return hiHi + (hiLo shr 32) + (cross shr 32)
}

/** Swift's `next(upperBound:)`. */
fun RandomSource.next(upperBound: ULong): ULong {
    require(upperBound != 0uL)
    var random = next()
    var low = random * upperBound
    if (low < upperBound) {
        val threshold = (0uL - upperBound) % upperBound
        while (low < threshold) {
            random = next()
            low = random * upperBound
        }
    }
    return multiplyHigh(random, upperBound)
}

/** Swift's `Int.random(in: range, using:)`, for a closed range. */
fun RandomSource.nextInt(range: IntRange): Int {
    val delta = (range.last.toLong() - range.first.toLong()).toULong() + 1uL
    return (range.first.toLong() + next(delta).toLong()).toInt()
}

/** Swift's `Int.random(in: 0..<count, using:)`. */
fun RandomSource.nextIndex(count: Int): Int = nextInt(0 until count)

/** Swift's `randomElement(using:)`. */
fun <T> List<T>.randomElement(source: RandomSource): T? =
    if (isEmpty()) null else this[source.nextIndex(size)]

/** Swift's `shuffle(using:)`, in place. */
fun <T> MutableList<T>.shuffleSwift(source: RandomSource) {
    if (size <= 1) return
    var amount = size
    var current = 0
    while (amount > 1) {
        val offset = source.nextIndex(amount)
        amount -= 1
        val target = current + offset
        val held = this[current]
        this[current] = this[target]
        this[target] = held
        current += 1
    }
}

fun <T> List<T>.shuffledSwift(source: RandomSource): List<T> = toMutableList().also { it.shuffleSwift(source) }

/**
 * Deterministic answer-position shuffling. The same id always gives the same
 * order, so a question's choices hold still across recomposition and undo.
 */
object ChoiceShuffle {
    fun permutation(count: Int, seed: String): List<Int> {
        if (count <= 1) return (0 until count).toList()
        return (0 until count).toList().shuffledSwift(StableSeededGenerator(seed))
    }
}
