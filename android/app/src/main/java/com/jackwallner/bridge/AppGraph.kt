package com.jackwallner.bridge

import android.content.Context
import com.jackwallner.bridge.data.AlarmReminderScheduler
import com.jackwallner.bridge.data.AppClock
import com.jackwallner.bridge.data.AppSettings
import com.jackwallner.bridge.data.ConversionDiagnostics
import com.jackwallner.bridge.data.BridgeMinuteStore
import com.jackwallner.bridge.data.PracticeRecordStore
import com.jackwallner.bridge.data.ProgressStore
import com.jackwallner.bridge.data.ReviewPromptTracker
import com.jackwallner.bridge.data.SharedPreferencesStore
import com.jackwallner.bridge.data.SubscriptionService
import com.jackwallner.bridge.data.WhatsNewTracker
import kotlinx.coroutines.MainScope

/** Every long-lived object the screens share, built once per process. */
class AppGraph(context: Context) {
    val appContext: Context = context.applicationContext
    val scope = MainScope()
    val clock = AppClock()
    val defaults = SharedPreferencesStore(appContext)
    val settings = AppSettings(defaults, AlarmReminderScheduler(appContext))
    val progress = ProgressStore(defaults, clock)
    val records = PracticeRecordStore(defaults, clock)
    val minutes = BridgeMinuteStore(defaults, clock)
    val review = ReviewPromptTracker(defaults, clock)
    val diagnostics = ConversionDiagnostics(defaults, clock)
    val subscriptions = SubscriptionService(appContext, defaults, diagnostics)
    val whatsNew = WhatsNewTracker(defaults, BuildConfig.VERSION_NAME)

    /** Settings' Reset Progress: every practice stat, never onboarding or purchases. */
    fun resetProgress() {
        progress.resetAll()
        records.resetAll()
        minutes.resetAll()
    }
}
