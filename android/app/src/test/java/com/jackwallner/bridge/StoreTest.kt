package com.jackwallner.bridge

import com.jackwallner.bridge.content.BridgeContent
import com.jackwallner.bridge.content.BridgeMinuteContent
import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.content.PracticeSkill
import com.jackwallner.bridge.content.SessionBuilder
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.data.AppClock
import com.jackwallner.bridge.data.ConversionDiagnostics
import com.jackwallner.bridge.data.BridgeMinuteStore
import com.jackwallner.bridge.data.InMemoryStore
import com.jackwallner.bridge.data.PracticeRecordStore
import com.jackwallner.bridge.data.ProgressStore
import com.jackwallner.bridge.data.ReviewAccess
import com.jackwallner.bridge.data.ReviewPromptTracker
import com.jackwallner.bridge.data.WhatsNewTracker
import com.jackwallner.bridge.ui.UpgradeIntent
import com.jackwallner.bridge.ui.nav.PracticeMode
import com.jackwallner.bridge.ui.nav.Route
import com.jackwallner.bridge.ui.nav.SessionPurpose
import java.security.MessageDigest
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ports of the iOS store tests: the logic that was hand-translated rather than exported. */
class StoreTest {
    private val defaults = InMemoryStore()
    private val clock = AppClock(Clock.fixed(Instant.parse("2026-10-16T12:00:00Z"), ZoneOffset.UTC))
    private val room = "card-room"
    private val reviewIDs get() = SessionBuilder.reviewableItemIDs.sorted()
    private val unsupportedIDs get() = DrillLibrary.rooms.flatMap { it.drills }.flatMap {
        when (val kind = it.kind) {
            is DrillKind.Play -> kind.scenarios.map { it.id }
            is DrillKind.Flashcards -> kind.cards.filter { it.choice == null }.map { it.id }
            else -> emptyList()
        }
    }

    @Test
    fun unsupportedAndStaleMistakesDoNotCountOrQueueAfterReload() {
        val ids = unsupportedIDs + "removed-question"
        assertTrue(unsupportedIDs.isNotEmpty())
        val store = PracticeRecordStore(defaults, clock)
        ids.forEach { store.record(it, room, correct = false) }
        val reloaded = PracticeRecordStore(defaults, clock)
        assertEquals(0, reloaded.dueCount)
        assertTrue(reloaded.reviewQueue().isEmpty())
        assertEquals(ids.size, reloaded.totalAttempts)
    }

    @Test
    fun unsupportedMistakesCannotFillTheQueueAheadOfPlayableItems() {
        val store = PracticeRecordStore(defaults, clock)
        (unsupportedIDs + (0 until 12).map { "removed-$it" }).forEach { store.record(it, room, correct = false) }
        advanceDays(1)
        reviewIDs.take(13).forEach { store.record(it, room, correct = false) }
        assertEquals(13, store.dueCount)
        val queue = store.reviewQueue()
        assertEquals(12, queue.size)
        assertEquals(queue, SessionBuilder.reviewSession(queue, true).map { it.id })
    }

    private fun advanceDays(days: Long) {
        clock.clock = Clock.offset(clock.clock, java.time.Duration.ofDays(days))
    }

    @Test
    fun purchasedActionsAreConsumedOnce() {
        val destinations = listOf(
            Route.EndlessPicker, Route.BridgeMinute, Route.GameNightPrep,
            Route.Practice(PracticeMode.Timed), Route.Practice(PracticeMode.Review),
            Route.Session(emptyList(), SessionPurpose.GameNightPrep), Route.Drill("chosen-room", "chosen-drill"),
        )
        for (destination in destinations) {
            val intent = UpgradeIntent<Route>()
            intent.destination = destination
            assertEquals(destination, intent.consume(isMember = true))
            assertEquals(null, intent.consume(isMember = true))
        }
    }

    @Test
    fun cancelledActionDoesNotOpenAfterALaterUpgrade() {
        val intent = UpgradeIntent<Route>()
        intent.destination = Route.Drill("chosen-room", "chosen-drill")
        assertEquals(null, intent.consume(isMember = false))
        assertEquals(null, intent.consume(isMember = true))
    }

    @Test
    fun genericUpgradeDoesNotInventADestination() {
        assertEquals(null, UpgradeIntent<Route>().consume(isMember = true))
    }

    // MARK: - ProgressStoreTests

    @Test
    fun recordSessionCountsAndStreakRules() {
        val store = ProgressStore(defaults, clock)
        store.recordSession("meet-cards")
        store.recordSession("meet-cards")
        assertEquals(2, store.completions("meet-cards"))
        assertEquals(2, store.totalSessions)
        assertEquals("Same-day sessions keep the streak", 1, store.streakCount)
        advanceDays(1)
        store.recordSession("card-quiz")
        assertEquals(2, store.streakCount)
        advanceDays(3)
        store.recordSession("card-quiz")
        assertEquals("A gap resets to one", 1, store.streakCount)
    }

    @Test
    fun roomProgressCountsFinishedDrills() {
        val store = ProgressStore(defaults, clock)
        val first = DrillLibrary.rooms.first()
        assertEquals(0.0, store.roomProgress(first), 0.0)
        store.recordSession(first.drills[0].id)
        assertEquals(1.0 / first.drills.size, store.roomProgress(first), 0.001)
    }

    @Test
    fun seenAndMissedPersist() {
        val store = ProgressStore(defaults, clock)
        store.recordItem("q1", correct = false)
        assertTrue("q1" in store.missedItems)
        val reloaded = ProgressStore(defaults, clock)
        assertTrue("q1" in reloaded.seenItems && "q1" in reloaded.missedItems)
        reloaded.recordItem("q1", correct = true)
        assertTrue("q1" in reloaded.seenItems)
        assertFalse("A correct answer clears the miss", "q1" in reloaded.missedItems)
    }

    @Test
    fun resetKeepsOnboardingAndTheQuickSessionRestsForTheDay() {
        val store = ProgressStore(defaults, clock)
        store.setOnboarded(true)
        store.recordSession("a")
        store.recordItem("q1", correct = false)
        store.markQuickSessionCompleted()
        assertTrue(store.quickSessionCompletedToday())
        advanceDays(1)
        assertFalse(store.quickSessionCompletedToday())
        store.resetAll()
        assertEquals(0, store.streakCount)
        assertEquals(0, store.totalSessions)
        assertEquals(0, store.completions("a"))
        assertTrue(store.seenItems.isEmpty() && store.missedItems.isEmpty())
        assertTrue("Reset must not re-trigger onboarding", ProgressStore(defaults, clock).hasOnboarded)
    }

    // MARK: - PracticeRecordStoreTests

    @Test
    fun recordsAccuracyAndPersists() {
        val store = PracticeRecordStore(defaults, clock)
        store.record("q1", room, correct = true)
        store.record("q1", room, correct = false)
        val record = PracticeRecordStore(defaults, clock).records.getValue("q1")
        assertEquals(2, record.attempts)
        assertEquals(1, record.correct)
        assertEquals(0.5, record.accuracy, 0.0)
    }

    @Test
    fun missedItemEntersAndLeavesTheQueueWorstFirst() {
        val store = PracticeRecordStore(defaults, clock)
        store.record(reviewIDs[0], room, correct = false)
        assertEquals(listOf(reviewIDs[0]), store.reviewQueue())
        store.record(reviewIDs[0], room, correct = true)
        assertEquals("One correct answer schedules it a day out", emptyList<String>(), store.reviewQueue())
        store.record(reviewIDs[0], room, correct = true)
        assertFalse("Two in a row retires it", store.records.getValue(reviewIDs[0]).needsReview)

        repeat(3) { store.record(reviewIDs[1], room, correct = false) }
        store.record(reviewIDs[2], room, correct = true)
        store.record(reviewIDs[2], room, correct = false)
        assertEquals(reviewIDs[1], store.reviewQueue().first())
    }

    @Test
    fun generatedItemsCollapseAndStayOutOfTheQueue() {
        val store = PracticeRecordStore(defaults, clock)
        val prefix = PracticeSkill.OPENINGS.itemPrefix
        store.record(prefix + "a", room, correct = false)
        store.record(prefix + "b", room, correct = true)
        store.record("bridge-minute-declarer", "declarer-room", correct = false, isReviewable = false)
        assertEquals(2, store.records.size)
        assertEquals(2, store.records.getValue(PracticeSkill.OPENINGS.raw).attempts)
        assertTrue(store.reviewQueue().isEmpty())
        assertEquals(0, store.dueCount)
    }

    @Test
    fun roomStatsWeakestRoomAndChallengeBest() {
        val store = PracticeRecordStore(defaults, clock)
        store.record("q1", "card-room", correct = true)
        store.record("q2", "card-room", correct = false)
        store.record("q3", "auction-room", correct = true)
        val stats = store.roomStats()
        assertEquals(2, stats.size)
        assertEquals(0.5, stats.first { it.id == "card-room" }.accuracy, 0.0)
        assertEquals(2.0 / 3.0, store.overallAccuracy, 0.0001)
        assertEquals("Needs five attempts to mean it", null, store.weakestRoom())
        repeat(4) { store.record("q4", "auction-room", correct = false) }
        assertEquals("auction-room", store.weakestRoom()!!.id)
        store.recordChallengeScore(12)
        store.recordChallengeScore(7)
        assertEquals(12, store.bestChallengeScore)
        store.resetAll()
        assertTrue(PracticeRecordStore(defaults, clock).records.isEmpty())
        assertEquals(0, store.bestChallengeScore)
    }

    // MARK: - BridgeMinuteStore

    @Test
    fun bridgeMinuteKeepsOnlyTheFirstAttempt() {
        val store = BridgeMinuteStore(defaults, clock)
        val challenge = BridgeMinuteContent.challenge(LocalDate.of(2026, 10, 16))
        val first = store.record(challenge, listOf(true, false, true, true, false))
        assertEquals(3, first.score)
        assertEquals(5, first.total)
        assertEquals(3, store.record(challenge, List(5) { true }).score)
        assertEquals(3, BridgeMinuteStore(defaults, clock).result(LocalDate.of(2026, 10, 16))!!.score)
        assertEquals("10/16", first.shortDate)
        assertTrue(first.shareText.startsWith("Bridge Minute 10/16: 3/5"))
        assertTrue(first.shareText.endsWith("https://play.google.com/store/apps/details?id=com.jackwallner.bridge"))
        assertEquals(1, store.completedThisWeek())
        assertEquals(30, store.archiveDates().size)
    }

    // MARK: - ReviewPromptTrackerTests

    @Test
    fun reviewCardWaitsForTheSecondLaunchAndHonoursCooldowns() {
        val tracker = ReviewPromptTracker(defaults, clock)
        tracker.recordAppLaunch()
        tracker.recordPositiveMoment()
        assertFalse("never in the first session", tracker.shouldShowAfterPositiveMoment())
        tracker.recordAppLaunch()
        assertTrue(tracker.shouldShowAfterPositiveMoment())
        tracker.markStoreCardRequested()
        assertFalse(tracker.shouldShowAfterPositiveMoment())
        advanceDays(29)
        assertFalse(tracker.shouldShowAfterPositiveMoment())
        advanceDays(2)
        assertTrue(tracker.shouldShowAfterPositiveMoment())
        tracker.markOpenedWriteReview()
        advanceDays(400)
        assertFalse("Opening the listing ends the asks", tracker.shouldShowAfterPositiveMoment())
    }

    // MARK: - PaywallFunnelTests

    @Test
    fun conversionAttributesStayEmptyUntilAPitchAndFreezeAtConversion() {
        val diagnostics = ConversionDiagnostics(defaults, clock)
        diagnostics.recordAppOpen()
        assertTrue(diagnostics.subscriberAttributes.isEmpty())
        diagnostics.recordPitchView("bridge_onboarding_trial")
        diagnostics.recordPitchView("bridge_home_sheet")
        diagnostics.recordConversion("monthly", startedTrial = true, offeringId = "android")
        diagnostics.recordConversion("yearly", startedTrial = false, offeringId = null)
        val attributes = diagnostics.subscriberAttributes
        assertEquals("2", attributes["pitch_views_total"])
        assertEquals("1", attributes["pitch_views_onboarding_trial"])
        assertEquals("home_sheet", attributes["converted_surface"])
        assertEquals("monthly", attributes["converted_plan"])
        assertEquals("true", attributes["converted_with_trial"])
        assertEquals("android", attributes["converted_offering"])
        assertEquals("1", attributes["opens_before_first_pitch"])
        assertTrue(attributes.keys.all { it.length <= 40 })
    }

    // MARK: - WhatsNewTests

    @Test
    fun whatsNewNeverShowsOnAFreshInstall() {
        val tracker = WhatsNewTracker(defaults, "1.2.0")
        assertFalse(tracker.shouldPresent(hasOnboarded = false))
        assertTrue("An onboarded player without a marker updated from an old build", tracker.shouldPresent(hasOnboarded = true))
        tracker.markCurrentAsBaseline()
        assertFalse(tracker.shouldPresent(hasOnboarded = true))
        assertFalse("No notes for a maintenance version", WhatsNewTracker(InMemoryStore(), BuildConfig.VERSION_NAME).shouldPresent(true))
    }

    @Test
    fun releaseNotesAreWellFormedAndAndroidOnly() {
        val releases = BridgeContent.library.whatsNew
        assertEquals(releases.size, releases.map { it.version }.toSet().size)
        for (release in releases) {
            assertTrue(release.headline.isNotEmpty() && "\u2014" !in release.headline)
            assertTrue(release.items.isNotEmpty())
            assertEquals(release.items.size, release.items.map { it.id }.toSet().size)
            for (item in release.items) {
                assertTrue(item.body.isNotEmpty() && "\u2014" !in item.body)
                assertFalse("No iPad copy on Android", item.body.contains("iPad"))
            }
        }
    }

    // MARK: - Play reviewer access

    @Test
    fun reviewerCodeUnlocksOnlyWithTheRightCode() {
        val code = "test-code-123"
        val digest = MessageDigest.getInstance("SHA-256").digest(code.toByteArray()).joinToString("") { "%02x".format(it) }
        val access = ReviewAccess(defaults, digest)
        assertFalse(access.isGranted)
        assertFalse(access.activate("wrong"))
        assertFalse(access.isGranted)
        assertTrue(access.activate("  $code "))
        assertTrue(ReviewAccess(defaults, digest).isGranted)
        assertFalse("No digest in the build means no unlock", ReviewAccess(InMemoryStore(), "").activate(code))
    }
}
