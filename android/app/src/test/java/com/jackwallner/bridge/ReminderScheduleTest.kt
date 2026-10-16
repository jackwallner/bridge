package com.jackwallner.bridge

import com.jackwallner.bridge.data.AlarmReminderScheduler
import java.time.DayOfWeek
import java.time.LocalDateTime
import org.junit.Assert.assertEquals
import org.junit.Test

class ReminderScheduleTest {
    /** Each occurrence is laid in local wall time, so DST cannot shift it an hour. */
    @Test
    fun dailyReminderKeepsItsLocalTimeAcrossTheClockChange() {
        // Los Angeles falls back on November 1, 2026.
        val delivered = LocalDateTime.of(2026, 10, 31, 9, 0, 5)
        assertEquals(LocalDateTime.of(2026, 11, 1, 9, 0), AlarmReminderScheduler.nextDaily(delivered, 9, 0))
    }

    @Test
    fun dailyReminderLaterTodayStaysToday() {
        val now = LocalDateTime.of(2026, 10, 12, 8, 0)
        assertEquals(LocalDateTime.of(2026, 10, 12, 9, 30), AlarmReminderScheduler.nextDaily(now, 9, 30))
    }

    @Test
    fun weeklyReminderLandsOnTheChosenDayAndHour() {
        val delivered = LocalDateTime.of(2026, 10, 29, 17, 0, 10) // a Thursday
        assertEquals(
            LocalDateTime.of(2026, 11, 5, 17, 0),
            AlarmReminderScheduler.nextWeekly(delivered, DayOfWeek.THURSDAY, 17, 0),
        )
        assertEquals(
            LocalDateTime.of(2026, 10, 31, 10, 0),
            AlarmReminderScheduler.nextWeekly(delivered, DayOfWeek.SATURDAY, 10, 0),
        )
    }
}
