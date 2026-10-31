package com.jackwallner.bridge

import com.jackwallner.bridge.data.AppClock
import com.jackwallner.bridge.data.InMemoryStore
import com.jackwallner.bridge.data.ProgressStore
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.TimeZone
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of the iOS BR-03 streak tests: day keys, a westward trip, DST, and a zone change mid-process. */
class StreakTimeZoneTest {
    private val originalZone = TimeZone.getDefault()
    private val newYork = ZoneId.of("America/New_York")
    private val chicago = ZoneId.of("America/Chicago")
    private val losAngeles = ZoneId.of("America/Los_Angeles")

    @After
    fun restoreZone() = TimeZone.setDefault(originalZone)

    private fun at(text: String, zone: ZoneId) = Clock.fixed(Instant.parse(text), zone)

    @Test
    fun westwardTravelKeepsTheStreak() {
        val clock = AppClock(at("2026-10-29T00:00:00Z", newYork))
        val store = ProgressStore(InMemoryStore(), clock)
        clock.clock = at("2026-10-29T00:00:00Z", newYork) // Oct 28 evening in New York
        store.recordSession("a")
        clock.clock = at("2026-10-30T00:00:00Z", newYork)
        store.recordSession("a")
        assertEquals(2, store.streakCount)
        clock.clock = at("2026-10-30T14:00:00Z", chicago) // Friday morning, a zone west
        store.recordSession("a")
        assertEquals(3, store.streakCount)
    }

    @Test
    fun westwardTravelDoesNotCountTheSameDayTwice() {
        val clock = AppClock(at("2026-10-29T13:00:00Z", newYork))
        val store = ProgressStore(InMemoryStore(), clock)
        store.recordSession("a")
        clock.clock = at("2026-10-30T03:00:00Z", losAngeles) // still Oct 29 evening
        store.recordSession("a")
        assertEquals(1, store.streakCount)
    }

    @Test
    fun westwardTravelKeepsGetStartedDoneForTheDay() {
        val clock = AppClock(at("2026-10-29T13:00:00Z", newYork))
        val store = ProgressStore(InMemoryStore(), clock)
        store.markQuickSessionCompleted()
        clock.clock = at("2026-10-30T03:00:00Z", losAngeles)
        assertTrue(store.quickSessionCompletedToday())
        clock.clock = at("2026-10-30T09:00:00Z", losAngeles)
        assertFalse(store.quickSessionCompletedToday())
    }

    @Test
    fun streakSurvivesSpringForwardAndFallBack() {
        val clock = AppClock(at("2026-03-08T01:00:00-08:00", losAngeles)) // spring forward is 2am
        val store = ProgressStore(InMemoryStore(), clock)
        store.recordSession("a")
        clock.clock = at("2026-03-09T23:30:00-07:00", losAngeles)
        store.recordSession("a")
        assertEquals(2, store.streakCount)
        clock.clock = at("2026-10-31T23:30:00-07:00", losAngeles) // fall back is Nov 1, 2am
        store.recordSession("a")
        clock.clock = at("2026-11-01T23:30:00-08:00", losAngeles)
        store.recordSession("a")
        clock.clock = at("2026-11-02T00:30:00-08:00", losAngeles)
        store.recordSession("a")
        assertEquals(3, store.streakCount)
    }

    /** The default clock must follow a device zone change; `Clock.systemDefaultZone()` froze the first zone. */
    @Test
    fun defaultClockFollowsADeviceZoneChange() {
        val clock = AppClock()
        listOf("Pacific/Kiritimati", "Pacific/Pago_Pago", "America/Chicago").forEach { id ->
            TimeZone.setDefault(TimeZone.getTimeZone(id))
            assertEquals(id, ZoneId.of(id), clock.zone)
            assertEquals(id, LocalDate.now(ZoneId.of(id)), clock.today())
        }
    }
}
