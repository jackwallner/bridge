package com.jackwallner.bridge.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.bridge.model.Room
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import org.json.JSONObject

/** Streaks, drill completions, and the flat seen/missed sets behind the daily mix. */
class ProgressStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    var streakCount by mutableStateOf(defaults.getInt(Keys.STREAK_COUNT))
        private set
    var totalSessions by mutableStateOf(defaults.getInt(Keys.TOTAL_SESSIONS))
        private set
    var completions by mutableStateOf(loadCompletions())
        private set
    var seenItems by mutableStateOf(defaults.getStringSet(Keys.SEEN_ITEMS))
        private set
    var missedItems by mutableStateOf(defaults.getStringSet(Keys.MISSED_ITEMS))
        private set

    /** Root branches onboarding vs Home on this, so it is observable. */
    var hasOnboarded by mutableStateOf(defaults.getBoolean(Keys.HAS_ONBOARDED))
        private set

    /** Bumps whenever the day-based state may have moved, so Home recomposes. */
    var quickSessionDay by mutableStateOf(defaults.getString(Keys.LAST_QUICK_SESSION_DAY))
        private set

    fun setOnboarded(value: Boolean) {
        hasOnboarded = value
        defaults.putBoolean(Keys.HAS_ONBOARDED, value)
    }

    fun completions(drillID: String): Int = completions[drillID] ?: 0

    fun roomProgress(room: Room): Double {
        if (room.drills.isEmpty()) return 0.0
        return room.drills.count { completions(it.id) > 0 }.toDouble() / room.drills.size
    }

    fun recordSession(drillID: String) {
        completions = completions + (drillID to completions(drillID) + 1)
        totalSessions += 1
        bumpStreak()
        defaults.putString(Keys.COMPLETIONS, JSONObject(completions as Map<*, *>).toString())
        defaults.putInt(Keys.TOTAL_SESSIONS, totalSessions)
    }

    /** Consecutive calendar days with at least one finished drill. */
    private fun bumpStreak() {
        val today = clock.today()
        val last = defaults.getString(Keys.LAST_ACTIVE_DAY)?.let(LocalDate::parse)
        streakCount = when {
            last == null -> 1
            ChronoUnit.DAYS.between(last, today) == 1L -> streakCount + 1
            ChronoUnit.DAYS.between(last, today) > 1L -> 1
            else -> streakCount
        }
        defaults.putString(Keys.LAST_ACTIVE_DAY, today.toString())
        defaults.putInt(Keys.STREAK_COUNT, streakCount)
    }

    /** Anything answered wrong comes back first; unseen items come next. */
    fun recordItem(id: String, correct: Boolean) {
        seenItems = seenItems + id
        missedItems = if (correct) missedItems - id else missedItems + id
        persistItems()
    }

    data class ItemSnapshot(val id: String, val seen: Boolean, val missed: Boolean)

    fun snapshotItem(id: String) = ItemSnapshot(id, id in seenItems, id in missedItems)

    fun restoreItem(snapshot: ItemSnapshot) {
        seenItems = if (snapshot.seen) seenItems + snapshot.id else seenItems - snapshot.id
        missedItems = if (snapshot.missed) missedItems + snapshot.id else missedItems - snapshot.id
        persistItems()
    }

    private fun persistItems() {
        defaults.putStringSet(Keys.SEEN_ITEMS, seenItems)
        defaults.putStringSet(Keys.MISSED_ITEMS, missedItems)
    }

    /** Get Started is once a day: a fresh mix each day, resting once today's is done. */
    fun quickSessionCompletedToday(): Boolean = quickSessionDay == clock.today().toString()

    fun markQuickSessionCompleted() {
        quickSessionDay = clock.today().toString()
        defaults.putString(Keys.LAST_QUICK_SESSION_DAY, quickSessionDay!!)
    }

    /** Clears every practice stat. Leaves onboarding and purchases alone. */
    fun resetAll() {
        streakCount = 0
        totalSessions = 0
        completions = emptyMap()
        seenItems = emptySet()
        missedItems = emptySet()
        quickSessionDay = null
        listOf(
            Keys.STREAK_COUNT, Keys.LAST_ACTIVE_DAY, Keys.TOTAL_SESSIONS, Keys.COMPLETIONS,
            Keys.SEEN_ITEMS, Keys.MISSED_ITEMS, Keys.REVIEW_GATE_SHOWN, Keys.LAST_QUICK_SESSION_DAY,
        ).forEach(defaults::remove)
    }

    private fun loadCompletions(): Map<String, Int> {
        val raw = defaults.getString(Keys.COMPLETIONS) ?: return emptyMap()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return json.keys().asSequence().associateWith { json.getInt(it) }
    }

    private object Keys {
        const val STREAK_COUNT = "progress.streakCount"
        const val LAST_ACTIVE_DAY = "progress.lastActiveDay"
        const val TOTAL_SESSIONS = "progress.totalSessions"
        const val COMPLETIONS = "progress.completions"
        const val HAS_ONBOARDED = "progress.hasOnboarded"
        const val REVIEW_GATE_SHOWN = "progress.reviewGateShown"
        const val SEEN_ITEMS = "progress.seenItems"
        const val MISSED_ITEMS = "progress.missedItems"
        const val LAST_QUICK_SESSION_DAY = "progress.lastQuickSessionDay"
    }
}
