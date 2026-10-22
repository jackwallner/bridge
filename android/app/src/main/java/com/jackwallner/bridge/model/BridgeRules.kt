package com.jackwallner.bridge.model

/** WBF auction, play and duplicate scoring rules. Strains C,D,H,S,NT = 0..4. */
object BridgeRules {
    fun legal(hand: List<BridgeCard>, led: Suit?): List<BridgeCard> = hand.filter { it.suit == led }.ifEmpty { hand }
    fun winner(trick: List<BridgeCard>, trump: Suit?): Int? {
        val lead = trick.firstOrNull() ?: return null
        return trick.indices.maxByOrNull {
            val card = trick[it]
            val group = if (card.suit == trump) 2 else if (card.suit == lead.suit) 1 else 0
            group * 20 + if (group == 0) 0 else card.rank.sortOrder
        }
    }
    fun score(level: Int, strain: Int, multiplier: Int = 1, tricks: Int, vulnerable: Boolean): Int {
        if (level == 0) return 0
        val difference = tricks - level - 6
        if (difference < 0) {
            val down = -difference
            if (multiplier == 1) return -down * if (vulnerable) 100 else 50
            val penalty = if (vulnerable) 200 + (down - 1) * 300
                else 100 + minOf(down - 1, 2) * 200 + maxOf(down - 3, 0) * 300
            return -penalty * (multiplier / 2)
        }
        val unit = if (strain < 2) 20 else 30
        val contracted = (level * unit + if (strain == 4) 10 else 0) * multiplier
        val bonus = if (contracted >= 100) { if (vulnerable) 500 else 300 } else 50
        val insult = if (multiplier == 1) 0 else 50 * (multiplier / 2)
        val over = if (multiplier == 1) difference * unit else difference * (if (vulnerable) 200 else 100) * (multiplier / 2)
        val slam = when (level) { 6 -> if (vulnerable) 750 else 500; 7 -> if (vulnerable) 1500 else 1000; else -> 0 }
        return contracted + bonus + insult + over + slam
    }
    data class Auction(var ended: Boolean = false, var level: Int = 0, var strain: Int = 0,
        var multiplier: Int = 1, var declarer: Int? = null, var nextPlayer: Int = 0)
    fun auction(calls: List<String>, dealer: Int = 0): Auction? {
        val result = Auction(nextPlayer = dealer)
        var bidder: Int? = null
        val first = mutableMapOf<Int, Int>()
        var passes = 0
        for (call in calls) {
            if (result.ended) return null
            val player = result.nextPlayer
            when (call) {
                "P" -> { passes++; result.ended = passes == if (bidder == null) 4 else 3 }
                "X", "XX" -> {
                    val by = bidder ?: return null
                    val opponent = player % 2 != by % 2
                    if (!(call == "X" && opponent && result.multiplier == 1 || call == "XX" && !opponent && result.multiplier == 2)) return null
                    result.multiplier *= 2
                    passes = 0
                }
                else -> {
                    val level = call.firstOrNull()?.digitToIntOrNull() ?: return null
                    val strain = listOf("C", "D", "H", "S", "NT").indexOf(call.drop(1))
                    if (level !in 1..7 || strain < 0 || level * 5 + strain <= result.level * 5 + result.strain) return null
                    result.level = level; result.strain = strain; result.multiplier = 1; bidder = player
                    result.declarer = first.getOrPut(player % 2 * 5 + strain) { player }
                    passes = 0
                }
            }
            result.nextPlayer = (player + 1) % 4
        }
        return result
    }
}
