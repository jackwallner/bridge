package com.jackwallner.bridge.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.content.PracticeSkill
import org.json.JSONObject

/** One item's answering history and its next review date. Times are epoch millis. */
data class PracticeRecord(
    val attempts: Int = 0,
    val correct: Int = 0,
    val streak: Int = 0,
    val lastAnswered: Long = 0,
    val dueDate: Long = 0,
    val intervalDays: Double = 0.0,
    val ease: Double = 2.5,
    val roomID: String = "",
    val reviewSuppressed: Boolean? = null,
) {
    val accuracy: Double get() = if (attempts == 0) 0.0 else correct.toDouble() / attempts

    fun isDue(now: Long): Boolean = dueDate <= now

    /** Missed at least once and not yet answered right twice running. */
    val needsReview: Boolean get() = reviewSuppressed != true && attempts > correct && streak < 2

    fun toJson(): JSONObject = JSONObject().apply {
        put("attempts", attempts)
        put("correct", correct)
        put("streak", streak)
        put("lastAnswered", lastAnswered)
        put("dueDate", dueDate)
        put("intervalDays", intervalDays)
        put("ease", ease)
        put("roomID", roomID)
        reviewSuppressed?.let { put("reviewSuppressed", it) }
    }

    companion object {
        fun fromJson(json: JSONObject) = PracticeRecord(
            attempts = json.optInt("attempts"),
            correct = json.optInt("correct"),
            streak = json.optInt("streak"),
            lastAnswered = json.optLong("lastAnswered"),
            dueDate = json.optLong("dueDate"),
            intervalDays = json.optDouble("intervalDays", 0.0),
            ease = json.optDouble("ease", 2.5),
            roomID = json.optString("roomID"),
            reviewSuppressed = if (json.has("reviewSuppressed")) json.getBoolean("reviewSuppressed") else null,
        )
    }
}

/** Per-item practice history, the spaced-repetition queue, and the room rollups. */
class PracticeRecordStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    var records by mutableStateOf(load())
        private set
    var bestChallengeScore by mutableStateOf(defaults.getInt(Keys.BEST_CHALLENGE))
        private set

    /** Generated items collapse onto one row per skill, so the map stays bounded. */
    fun record(itemID: String, roomID: String, correct: Boolean, isReviewable: Boolean = true) {
        val now = clock.millis()
        val skill = PracticeSkill.skill(itemID)
        val key = skill?.raw ?: itemID
        val isGenerated = skill != null
        val old = records[key] ?: PracticeRecord()
        var record = old.copy(
            attempts = old.attempts + 1,
            roomID = roomID,
            reviewSuppressed = !isReviewable || isGenerated,
            lastAnswered = now,
            correct = if (correct) old.correct + 1 else old.correct,
            streak = if (correct) old.streak + 1 else 0,
        )
        if (isReviewable && !isGenerated) record = schedule(record, correct, now)
        records = records + (key to record)
        persist()
    }

    /** SM-2, trimmed: a miss resets the interval and costs ease, a hit multiplies it. */
    private fun schedule(record: PracticeRecord, correct: Boolean, now: Long): PracticeRecord {
        val interval: Double
        val ease: Double
        if (correct) {
            interval = when (record.streak) {
                1 -> 1.0
                2 -> 3.0
                else -> minOf(record.intervalDays * record.ease, 180.0)
            }
            ease = minOf(record.ease + 0.1, 2.8)
        } else {
            interval = 0.0
            ease = maxOf(record.ease - 0.2, 1.3)
        }
        return record.copy(intervalDays = interval, ease = ease, dueDate = now + (interval * DAY_MS).toLong())
    }

    fun recordChallengeScore(score: Int) {
        if (score <= bestChallengeScore) return
        bestChallengeScore = score
        defaults.putInt(Keys.BEST_CHALLENGE, score)
    }

    /** Due ids, worst first: lowest accuracy, then longest overdue. */
    fun reviewQueue(limit: Int = 12): List<String> =
        dueRecords().entries
            .sortedWith(compareBy<Map.Entry<String, PracticeRecord>> { it.value.accuracy }.thenBy { it.value.dueDate })
            .take(limit)
            .map { it.key }

    /** How many items are waiting, for the Home tile's badge. */
    val dueCount: Int get() = dueRecords().size

    private fun dueRecords(): Map<String, PracticeRecord> {
        val now = clock.millis()
        return records.filter { (id, record) -> record.needsReview && record.isDue(now) && PracticeSkill.fromRaw(id) == null }
    }

    data class RoomStat(val id: String, val name: String, val attempts: Int, val correct: Int) {
        val accuracy: Double get() = if (attempts == 0) 0.0 else correct.toDouble() / attempts
    }

    val totalAttempts: Int get() = records.values.sumOf { it.attempts }
    val totalCorrect: Int get() = records.values.sumOf { it.correct }
    val overallAccuracy: Double get() = if (totalAttempts == 0) 0.0 else totalCorrect.toDouble() / totalAttempts

    /** Accuracy per room, in library order, skipping rooms never practised. */
    fun roomStats(): List<RoomStat> = DrillLibrary.rooms.mapNotNull { room ->
        val mine = records.values.filter { it.roomID == room.id }
        val attempts = mine.sumOf { it.attempts }
        if (attempts == 0) null else RoomStat(room.id, room.name, attempts, mine.sumOf { it.correct })
    }

    /** The room a player is worst at, once there is enough data to mean it. */
    fun weakestRoom(): RoomStat? = roomStats().filter { it.attempts >= 5 }.minByOrNull { it.accuracy }

    fun resetAll() {
        records = emptyMap()
        bestChallengeScore = 0
        defaults.remove(Keys.RECORDS)
        defaults.remove(Keys.BEST_CHALLENGE)
    }

    private fun persist() {
        val json = JSONObject()
        records.forEach { (id, record) -> json.put(id, record.toJson()) }
        defaults.putString(Keys.RECORDS, json.toString())
    }

    private fun load(): Map<String, PracticeRecord> {
        val raw = defaults.getString(Keys.RECORDS) ?: return emptyMap()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return json.keys().asSequence().associateWith { PracticeRecord.fromJson(json.getJSONObject(it)) }
    }

    private object Keys {
        const val RECORDS = "practice.records"
        const val BEST_CHALLENGE = "practice.bestChallengeScore"
    }
}
