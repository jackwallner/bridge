package com.jackwallner.bridge

import com.jackwallner.bridge.model.BridgeCard
import org.json.JSONArray
import org.json.JSONObject

/** The iOS output recorded in `bridge-parity.json` by `scripts/sync-android-content.sh`. */
object ParityFixtures {
    val json: JSONObject by lazy {
        val stream = javaClass.classLoader!!.getResourceAsStream("bridge-parity.json")!!
        JSONObject(stream.bufferedReader().use { it.readText() })
    }
}

fun JSONArray.strings() = (0 until length()).map { getString(it) }
fun JSONArray.ints() = (0 until length()).map { getInt(it) }
fun JSONArray.objects() = (0 until length()).map { getJSONObject(it) }
fun JSONArray.cards() = strings().map(BridgeCard::fromCode)
fun codes(cards: List<BridgeCard>) = cards.map { it.code }
