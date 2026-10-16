package com.jackwallner.bridge

import android.content.Intent
import android.graphics.Bitmap
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Raw captures for the Play listing: the same six screens as the App Store set
 * (scripts/screenshot_raw/), named as scripts/play_screenshot_compositor.py
 * expects. Excluded from `connectedDebugAndroidTest` (`notClass` in
 * build.gradle.kts); run it with
 * `am instrument -e class com.jackwallner.bridge.StoreScreenshotTest`.
 * Files land in the app's external files dir under `screens/`.
 */
@RunWith(AndroidJUnit4::class)
class StoreScreenshotTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    @After
    fun tearDown() {
        scenario?.close()
    }

    @Test
    fun capture01QuickSession() {
        launch()
        tag("get-started")
        tag("choice-0")
        waitForTag("explanation")
        capture("01-quicksession")
    }

    @Test
    fun capture02Opening() {
        openDrill("auction-room", "opening-bid")
        waitForTag("hand-card-12")
        capture("02-opening")
    }

    @Test
    fun capture03LeadOrHold() {
        openDrill("defense-room", "defense-calls")
        waitForText("Make the call")
        capture("03-leadorhold")
    }

    @Test
    fun capture04Declarer() {
        openDrill("declarer-room", "choose-card")
        waitForTag("play-card-0")
        capture("04-declarer")
    }

    @Test
    fun capture05Home() {
        launch(seed = true)
        waitForText("Your seat at the table.")
        capture("05-home")
    }

    @Test
    fun capture06AuctionRoom() {
        launch(seed = true)
        tag("room-auction-room")
        waitForText("Name Your Opening")
        capture("06-auctionroom")
    }

    private fun launch(seed: Boolean = false) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java)
            .putExtra("resetAll", true)
            .putExtra("uiTest", true)
            .putExtra("onboarded", true)
            .putExtra("seedProgress", seed)
            .putExtra("appearance", "light")
        scenario = ActivityScenario.launch(intent)
    }

    private fun openDrill(room: String, drill: String) {
        launch()
        tag("room-$room")
        tag("drill-$drill")
    }

    private fun waitForTag(tag: String) {
        compose.waitUntil(30_000) { compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().size == 1 }
    }

    private fun waitForText(text: String) {
        compose.waitUntil(30_000) { compose.onAllNodes(hasText(text, substring = true)).fetchSemanticsNodes().isNotEmpty() }
    }

    private fun tag(tag: String) {
        waitForTag(tag)
        runCatching { compose.onNodeWithTag(tag).performScrollTo() }
        compose.onNodeWithTag(tag).performClick()
        compose.waitForIdle()
    }

    private fun capture(name: String) {
        compose.waitForIdle()
        Thread.sleep(1_500)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val bitmap: Bitmap = instrumentation.uiAutomation.takeScreenshot() ?: error("Screenshot failed for $name")
        val dir = File(instrumentation.targetContext.getExternalFilesDir(null), "screens").apply { mkdirs() }
        File(dir, "$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }
}
