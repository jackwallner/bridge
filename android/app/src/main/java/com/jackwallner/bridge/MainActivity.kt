package com.jackwallner.bridge

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.Modifier
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalView
import com.jackwallner.bridge.data.AlarmReminderScheduler
import com.jackwallner.bridge.data.Appearance
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.RootScreen
import com.jackwallner.bridge.ui.theme.Haptics
import com.jackwallner.bridge.ui.theme.BridgeTheme
import com.jackwallner.bridge.ui.theme.SoundPlayer
import kotlinx.coroutines.launch

@OptIn(ExperimentalComposeUiApi::class)
class MainActivity : ComponentActivity() {
    private var pendingRoute by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val graph = (application as BridgeApplication).graph
        if (savedInstanceState == null) {
            graph.review.recordAppLaunch()
            graph.diagnostics.recordAppOpen()
        }
        DebugLaunchOptions.apply(graph, intent)
        pendingRoute = intent?.getStringExtra(AlarmReminderScheduler.ROUTE_KEY)
        SoundPlayer.load(this)
        setContent {
            val settings = graph.settings
            val dark = when (settings.appearance) {
                Appearance.SYSTEM -> isSystemInDarkTheme()
                Appearance.LIGHT -> false
                Appearance.DARK -> true
            }
            LaunchedEffect(dark) {
                val bars = if (dark) SystemBarStyle.dark(Color.TRANSPARENT) else SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT)
                enableEdgeToEdge(statusBarStyle = bars, navigationBarStyle = bars)
            }
            val view = LocalView.current
            DisposableEffect(view) {
                Haptics.attach(view)
                onDispose { Haptics.attach(null) }
            }
            LaunchedEffect(settings.hapticsEnabled) { Haptics.enabled = settings.hapticsEnabled }
            LaunchedEffect(settings.soundEnabled) { SoundPlayer.enabled = settings.soundEnabled }
            LaunchedEffect(Unit) { launch { graph.subscriptions.start() } }
            CompositionLocalProvider(LocalGraph provides graph) {
                BridgeTheme(dark) {
                    // Test tags double as resource ids so UI Automator and screenshot scripts can find controls.
                    Box(Modifier.semantics { testTagsAsResourceId = true }) {
                        RootScreen(graph, pendingRoute, onRouteConsumed = { pendingRoute = null })
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra(AlarmReminderScheduler.ROUTE_KEY)?.let { pendingRoute = it }
    }
}
