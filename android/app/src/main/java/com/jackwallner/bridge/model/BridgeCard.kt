package com.jackwallner.bridge.model

// Case order matches the iOS `allCases` order. The seeded generators walk
// these lists, so reordering a case changes every shared daily challenge.

enum class Suit(val raw: String, val symbol: String, val sortOrder: Int) {
    CLUBS("clubs", "♣", 3),
    DIAMONDS("diamonds", "♦", 2),
    HEARTS("hearts", "♥", 1),
    SPADES("spades", "♠", 0);

    val displayName: String get() = raw.replaceFirstChar { it.uppercase() }
    val isMajor: Boolean get() = this == HEARTS || this == SPADES
    val isRed: Boolean get() = this == DIAMONDS || this == HEARTS
}

enum class Rank(val raw: String) {
    TWO("2"), THREE("3"), FOUR("4"), FIVE("5"), SIX("6"),
    SEVEN("7"), EIGHT("8"), NINE("9"), TEN("10"),
    JACK("J"), QUEEN("Q"), KING("K"), ACE("A");

    val sortOrder: Int get() = ordinal

    val spokenName: String
        get() = when (this) {
            JACK -> "Jack"
            QUEEN -> "Queen"
            KING -> "King"
            ACE -> "Ace"
            else -> raw
        }

    val highCardPoints: Int
        get() = when (this) {
            ACE -> 4
            KING -> 3
            QUEEN -> 2
            JACK -> 1
            else -> 0
        }
}

data class BridgeCard(val rank: Rank, val suit: Suit) {
    val shortLabel: String get() = "${rank.raw}${suit.symbol}"
    val spokenName: String get() = "${rank.spokenName} of ${suit.displayName}"
    val highCardPoints: Int get() = rank.highCardPoints
    val sortKey: Int get() = suit.sortOrder * 20 + (20 - rank.sortOrder)

    /** The card's code in the exported content, e.g. `H10` or `SQ`. */
    val code: String get() = "${suit.raw.take(1).uppercase()}${rank.raw}"

    companion object {
        fun c(rank: Rank) = BridgeCard(rank, Suit.CLUBS)
        fun d(rank: Rank) = BridgeCard(rank, Suit.DIAMONDS)
        fun h(rank: Rank) = BridgeCard(rank, Suit.HEARTS)
        fun s(rank: Rank) = BridgeCard(rank, Suit.SPADES)

        /** Suit by suit, two to ace, the same order as iOS `fullDeck`. */
        val fullDeck: List<BridgeCard> = Suit.entries.flatMap { suit -> Rank.entries.map { BridgeCard(it, suit) } }

        private val byCode: Map<String, BridgeCard> = fullDeck.associateBy { it.code }

        fun fromCode(code: String): BridgeCard = byCode[code] ?: error("Unknown card code $code")
    }
}

/** Sorted spades first, high to low, the way a bridge hand is held. */
val List<BridgeCard>.racked: List<BridgeCard> get() = sortedBy { it.sortKey }

val List<BridgeCard>.highCardPoints: Int get() = sumOf { it.highCardPoints }
