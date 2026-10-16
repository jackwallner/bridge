package com.jackwallner.bridge.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.bridge.content.BridgeContent
import com.jackwallner.bridge.content.BridgeMinuteCategory
import com.jackwallner.bridge.content.BridgeMinuteChallenge
import com.jackwallner.bridge.content.BridgeMinuteContent
import com.jackwallner.bridge.content.WhatsNewRelease
import java.time.Instant
import java.time.LocalDate
import java.time.temporal.WeekFields
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

data class BridgeMinuteResult(
    val dayKey: String,
    val shortDate: String,
    val completedAt: Long,
    val answers: List<Boolean>,
    val correctByCategory: Map<String, Int>,
    val totalByCategory: Map<String, Int>,
) {
    val score: Int get() = answers.count { it }
    val total: Int get() = answers.size

    fun correct(category: BridgeMinuteCategory) = correctByCategory[category.raw] ?: 0
    fun total(category: BridgeMinuteCategory) = totalByCategory[category.raw] ?: 0

    val shareText: String
        get() {
            val grid = answers.joinToString("") { if (it) "🟩" else "⬜️" }
            return "Bridge Minute $shortDate: $score/$total\n$grid\nCan you beat me? ${StoreLinks.PLAY_LISTING_URL}"
        }

    fun toJson(): JSONObject = JSONObject().apply {
        put("dayKey", dayKey)
        put("shortDate", shortDate)
        put("completedAt", completedAt)
        put("answers", JSONArray(answers))
        put("correctByCategory", JSONObject(correctByCategory as Map<*, *>))
        put("totalByCategory", JSONObject(totalByCategory as Map<*, *>))
    }

    companion object {
        fun fromJson(json: JSONObject): BridgeMinuteResult {
            val answers = json.getJSONArray("answers")
            fun counts(key: String): Map<String, Int> {
                val obj = json.getJSONObject(key)
                return obj.keys().asSequence().associateWith { obj.getInt(it) }
            }
            return BridgeMinuteResult(
                dayKey = json.getString("dayKey"),
                shortDate = json.getString("shortDate"),
                completedAt = json.getLong("completedAt"),
                answers = (0 until answers.length()).map { answers.getBoolean(it) },
                correctByCategory = counts("correctByCategory"),
                totalByCategory = counts("totalByCategory"),
            )
        }
    }
}

class BridgeMinuteStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    var results by mutableStateOf(load())
        private set

    fun result(day: LocalDate): BridgeMinuteResult? = results[BridgeMinuteContent.key(day)]

    /** Only the first attempt on a day counts. */
    fun record(challenge: BridgeMinuteChallenge, answers: List<Boolean>): BridgeMinuteResult {
        results[challenge.dayKey]?.let { return it }
        val correct = mutableMapOf<String, Int>()
        val total = mutableMapOf<String, Int>()
        challenge.questions.zip(answers).forEach { (question, right) ->
            total[question.category.raw] = (total[question.category.raw] ?: 0) + 1
            if (right) correct[question.category.raw] = (correct[question.category.raw] ?: 0) + 1
        }
        val result = BridgeMinuteResult(challenge.dayKey, challenge.shortDate, clock.millis(), answers, correct, total)
        results = results + (challenge.dayKey to result)
        persist()
        return result
    }

    fun completedThisWeek(): Int {
        val fields = WeekFields.of(Locale.getDefault())
        val today = clock.today()
        val start = today.with(fields.dayOfWeek(), 1)
        val end = start.plusDays(7)
        return results.values.count {
            val day = Instant.ofEpochMilli(it.completedAt).atZone(clock.zone).toLocalDate()
            !day.isBefore(start) && day.isBefore(end)
        }
    }

    fun archiveDates(count: Int = 30): List<LocalDate> = (1..count).map { clock.today().minusDays(it.toLong()) }

    fun resetAll() {
        results = emptyMap()
        defaults.remove(KEY)
    }

    private fun persist() {
        val json = JSONObject()
        results.forEach { (key, value) -> json.put(key, value.toJson()) }
        defaults.putString(KEY, json.toString())
    }

    private fun load(): Map<String, BridgeMinuteResult> {
        val raw = defaults.getString(KEY) ?: return emptyMap()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return json.keys().asSequence().associateWith { BridgeMinuteResult.fromJson(json.getJSONObject(it)) }
    }

    private companion object {
        const val KEY = "bridgeMinute.results"
    }
}

/**
 * The post-update notes, once. A fresh install never sees them: onboarding
 * marks the running version as the baseline.
 */
class WhatsNewTracker(private val defaults: KeyValueStore, val currentVersion: String) {
    val currentRelease: WhatsNewRelease?
        get() = BridgeContent.library.whatsNew.firstOrNull { it.version == currentVersion }

    fun shouldPresent(hasOnboarded: Boolean): Boolean {
        if (!hasOnboarded || currentRelease == null) return false
        return (defaults.getString(KEY) ?: "") != currentVersion
    }

    fun markSeen() = defaults.putString(KEY, currentVersion)

    fun markCurrentAsBaseline() = defaults.putString(KEY, currentVersion)

    private companion object {
        const val KEY = "whatsnew.lastSeenVersion"
    }
}
