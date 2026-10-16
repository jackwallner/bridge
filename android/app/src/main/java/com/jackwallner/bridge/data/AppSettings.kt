package com.jackwallner.bridge.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import java.time.DayOfWeek

enum class Appearance(val raw: String, val displayName: String) {
    LIGHT("light", "Light"),
    DARK("dark", "Dark"),
    SYSTEM("system", "Match Device");

    companion object {
        fun fromRaw(raw: String?): Appearance = entries.firstOrNull { it.raw == raw } ?: LIGHT
    }
}

/** 1 = Sunday, matching the iOS weekday numbering the stored value uses. */
enum class GameNightDay(val raw: Int, val displayName: String, val dayOfWeek: DayOfWeek) {
    SUNDAY(1, "Sunday", DayOfWeek.SUNDAY),
    MONDAY(2, "Monday", DayOfWeek.MONDAY),
    TUESDAY(3, "Tuesday", DayOfWeek.TUESDAY),
    WEDNESDAY(4, "Wednesday", DayOfWeek.WEDNESDAY),
    THURSDAY(5, "Thursday", DayOfWeek.THURSDAY),
    FRIDAY(6, "Friday", DayOfWeek.FRIDAY),
    SATURDAY(7, "Saturday", DayOfWeek.SATURDAY);

    companion object {
        fun fromRaw(raw: Int): GameNightDay = entries.firstOrNull { it.raw == raw } ?: THURSDAY
    }
}

/**
 * Appearance, feedback toggles and the two reminders. Appearance defaults to
 * the warm light theme whatever the device style. Scheduling is delegated to
 * `ReminderScheduler`, which the app wires in; tests leave it null.
 */
class AppSettings(private val defaults: KeyValueStore, private val scheduler: ReminderScheduler?) {
    var appearance by mutableStateOf(Appearance.fromRaw(defaults.getString(Keys.APPEARANCE)))
        private set
    var hapticsEnabled by mutableStateOf(defaults.getBoolean(Keys.HAPTICS, true))
        private set
    var soundEnabled by mutableStateOf(defaults.getBoolean(Keys.SOUND, true))
        private set
    var reminderEnabled by mutableStateOf(defaults.getBoolean(Keys.REMINDER_ENABLED))
        private set
    var reminderHour by mutableStateOf(defaults.getInt(Keys.REMINDER_HOUR, 9))
        private set
    var reminderMinute by mutableStateOf(defaults.getInt(Keys.REMINDER_MINUTE, 0))
        private set
    var gameNightReminderEnabled by mutableStateOf(defaults.getBoolean(Keys.GAME_NIGHT_ENABLED))
        private set
    var gameNightDay by mutableStateOf(GameNightDay.fromRaw(defaults.getInt(Keys.GAME_NIGHT_DAY)))
        private set
    var gameNightHour by mutableStateOf(defaults.getInt(Keys.GAME_NIGHT_HOUR, 17))
        private set
    var gameNightMinute by mutableStateOf(defaults.getInt(Keys.GAME_NIGHT_MINUTE, 0))
        private set

    /** Set when a reminder was asked for but notifications are off. */
    var reminderPermissionDenied by mutableStateOf(false)

    fun updateAppearance(value: Appearance) {
        appearance = value
        defaults.putString(Keys.APPEARANCE, value.raw)
    }

    fun updateHaptics(value: Boolean) {
        hapticsEnabled = value
        defaults.putBoolean(Keys.HAPTICS, value)
    }

    fun updateSound(value: Boolean) {
        soundEnabled = value
        defaults.putBoolean(Keys.SOUND, value)
    }

    /** Call only after notification permission is granted; the UI asks first. */
    fun updateReminderEnabled(value: Boolean) {
        reminderEnabled = value
        defaults.putBoolean(Keys.REMINDER_ENABLED, value)
        if (value) scheduler?.scheduleDaily(reminderHour, reminderMinute) else scheduler?.cancelDaily()
    }

    fun updateReminderTime(hour: Int, minute: Int) {
        reminderHour = hour
        reminderMinute = minute
        defaults.putInt(Keys.REMINDER_HOUR, hour)
        defaults.putInt(Keys.REMINDER_MINUTE, minute)
        if (reminderEnabled) scheduler?.scheduleDaily(hour, minute)
    }

    fun updateGameNightReminderEnabled(value: Boolean) {
        gameNightReminderEnabled = value
        defaults.putBoolean(Keys.GAME_NIGHT_ENABLED, value)
        if (value) scheduleGameNight() else scheduler?.cancelGameNight()
    }

    fun updateGameNightDay(value: GameNightDay) {
        gameNightDay = value
        defaults.putInt(Keys.GAME_NIGHT_DAY, value.raw)
        if (gameNightReminderEnabled) scheduleGameNight()
    }

    fun updateGameNightTime(hour: Int, minute: Int) {
        gameNightHour = hour
        gameNightMinute = minute
        defaults.putInt(Keys.GAME_NIGHT_HOUR, hour)
        defaults.putInt(Keys.GAME_NIGHT_MINUTE, minute)
        if (gameNightReminderEnabled) scheduleGameNight()
    }

    /** After a reboot the alarms are gone; put back whatever is switched on. */
    fun rescheduleAll() {
        if (reminderEnabled) scheduler?.scheduleDaily(reminderHour, reminderMinute)
        if (gameNightReminderEnabled) scheduleGameNight()
    }

    private fun scheduleGameNight() = scheduler?.scheduleGameNight(gameNightDay.dayOfWeek, gameNightHour, gameNightMinute)

    private object Keys {
        const val APPEARANCE = "settings.appearance"
        const val HAPTICS = "settings.haptics"
        const val SOUND = "settings.sound"
        const val REMINDER_ENABLED = "settings.reminderEnabled"
        const val REMINDER_HOUR = "settings.reminderHour"
        const val REMINDER_MINUTE = "settings.reminderMinute"
        const val GAME_NIGHT_ENABLED = "settings.gameNightReminderEnabled"
        const val GAME_NIGHT_DAY = "settings.gameNightDay"
        const val GAME_NIGHT_HOUR = "settings.gameNightHour"
        const val GAME_NIGHT_MINUTE = "settings.gameNightMinute"
    }
}

interface ReminderScheduler {
    fun scheduleDaily(hour: Int, minute: Int)
    fun cancelDaily()
    fun scheduleGameNight(day: DayOfWeek, hour: Int, minute: Int)
    fun cancelGameNight()
}
