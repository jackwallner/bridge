package com.jackwallner.bridge

import android.content.Intent
import com.jackwallner.bridge.data.Appearance

/**
 * Debug-only launch extras for tests and screenshots, the Android side of the
 * iOS launch arguments. None of this is compiled into a release build.
 *
 *     adb shell am start -n com.jackwallner.bridge/.MainActivity \
 *         --ez resetAll true --ez onboarded true --ez forcePro true --es appearance dark
 */
object DebugLaunchOptions {
    fun apply(graph: AppGraph, intent: Intent?) {
        val extras = intent?.extras ?: return
        if (extras.getBoolean("uiTest")) graph.review.isAutomationRun = true
        if (extras.getBoolean("resetAll")) {
            graph.resetProgress()
            graph.progress.setOnboarded(false)
            graph.defaults.keys().filter { it.startsWith("bridge.") || it.startsWith("whatsnew.") || it.startsWith("reviewPrompt.") }
                .forEach(graph.defaults::remove)
        }
        extras.getString("skillLevel")?.let { graph.defaults.putString("bridge.skillLevel", it) }
        if (extras.getBoolean("onboarded")) {
            graph.whatsNew.markCurrentAsBaseline()
            graph.progress.setOnboarded(true)
        }
        if (extras.getBoolean("seedProgress")) ScreenshotFixtures.seed(graph)
        if (extras.containsKey("forcePro")) {
            graph.subscriptions.forceProForDebug(extras.getBoolean("forcePro"))
        }
        extras.getString("appearance")?.let { graph.settings.updateAppearance(Appearance.fromRaw(it)) }
    }
}
