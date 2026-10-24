package com.jackwallner.bridge.ui

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.runtime.staticCompositionLocalOf
import com.jackwallner.bridge.AppGraph
import com.jackwallner.bridge.data.StoreLinks
import com.jackwallner.bridge.ui.nav.Route

val LocalGraph = staticCompositionLocalOf<AppGraph> { error("No app graph") }

/** App-wide presentations any screen can ask for; the root owns the sheets. */
interface AppActions {
    fun openPaywall(source: String, destination: Route? = null)
    fun openFeedback()
    fun openWhatsNew()

    /** A finished drill: count the positive moment and maybe show Play's review card. */
    fun positiveMoment()
}

/** A locked action is consumed once, after the paywall has closed. */
class UpgradeIntent<Destination> {
    var destination: Destination? = null

    fun consume(isMember: Boolean): Destination? {
        val result = if (isMember) destination else null
        destination = null
        return result
    }
}

val LocalAppActions = staticCompositionLocalOf<AppActions> { error("No app actions") }

/** Opens a web page in a Custom Tab, falling back to the browser. */
fun Context.openUrl(url: String) {
    runCatching { CustomTabsIntent.Builder().setShowTitle(true).build().launchUrl(this, Uri.parse(url)) }
        .onFailure { openExternal(url) }
}

fun Context.openExternal(url: String): Boolean = try {
    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    true
} catch (_: ActivityNotFoundException) {
    false
}

/** The Play listing, in the Play Store app when it is installed. */
fun Context.openPlayListing() {
    if (!openExternal(StoreLinks.PLAY_MARKET_URI)) openExternal(StoreLinks.PLAY_LISTING_URL)
}

fun Context.shareText(text: String) {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    startActivity(Intent.createChooser(intent, null))
}

/** Opens a mail draft; false when no mail app can take it. */
fun Context.openFeedbackMail(body: String): Boolean {
    val uri = Uri.parse(
        "mailto:${StoreLinks.FEEDBACK_EMAIL}?subject=${Uri.encode("Bridge Trainer feedback")}&body=${Uri.encode(body)}",
    )
    return try {
        startActivity(Intent(Intent.ACTION_SENDTO, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}

tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}
