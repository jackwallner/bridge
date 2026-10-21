package com.jackwallner.bridge.ui.screens

import androidx.compose.material3.TextButton

import androidx.compose.material3.OutlinedTextFieldDefaults

import androidx.compose.material3.OutlinedTextField

import androidx.compose.material3.AlertDialog

import androidx.compose.foundation.combinedClickable

import androidx.compose.foundation.ExperimentalFoundationApi

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.BuildConfig
import com.jackwallner.bridge.data.Appearance
import com.jackwallner.bridge.data.Membership
import com.jackwallner.bridge.data.PurchaseException
import com.jackwallner.bridge.data.StoreLinks
import com.jackwallner.bridge.ui.LocalAppActions
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.nav.LocalNavigator
import com.jackwallner.bridge.ui.nav.Route
import com.jackwallner.bridge.ui.openFeedbackMail
import com.jackwallner.bridge.ui.openPlayListing
import com.jackwallner.bridge.ui.openUrl
import com.jackwallner.bridge.ui.theme.BarTextButton
import com.jackwallner.bridge.ui.theme.FormDivider
import com.jackwallner.bridge.ui.theme.FormRow
import com.jackwallner.bridge.ui.theme.FormSection
import com.jackwallner.bridge.ui.theme.Haptics
import com.jackwallner.bridge.ui.theme.IconBadge
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeAlert
import com.jackwallner.bridge.ui.theme.BridgeBar
import com.jackwallner.bridge.ui.theme.BridgeScreen
import com.jackwallner.bridge.ui.theme.BridgeSwitch
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.PrimaryCTA
import com.jackwallner.bridge.ui.theme.PlusBadge
import com.jackwallner.bridge.ui.theme.Readable
import com.jackwallner.bridge.ui.theme.Segmented
import com.jackwallner.bridge.ui.theme.TimePickerRow
import com.jackwallner.bridge.ui.theme.navBarPadding
import com.jackwallner.bridge.ui.theme.pressable
import com.jackwallner.bridge.ui.theme.QuietButton
import com.jackwallner.bridge.ui.theme.themedCard
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(requestNotifications: (onGranted: () -> Unit) -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val context = LocalContext.current
    val colors = BridgeUI.colors
    val scope = rememberCoroutineScope()
    val settings = graph.settings
    val service = graph.subscriptions
    var restoreMessage by remember { mutableStateOf<String?>(null) }
    var confirmReset by remember { mutableStateOf(false) }
    var showReviewerCode by remember { mutableStateOf(false) }

    BridgeScreen("Settings", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(22.dp)) {
                FormSection("Appearance") {
                    Box(Modifier.padding(12.dp)) {
                        Segmented(Appearance.entries, settings.appearance, { it.displayName }) { settings.updateAppearance(it) }
                    }
                }
                FormSection("Practice") {
                    FormRow("Haptics") { BridgeSwitch(settings.hapticsEnabled, "Haptics") { settings.updateHaptics(it) } }
                    FormDivider()
                    FormRow("Sound Effects") { BridgeSwitch(settings.soundEnabled, "Sound Effects") { settings.updateSound(it) } }
                    FormDivider()
                    FormRow("Daily Reminder") {
                        BridgeSwitch(settings.reminderEnabled, "Daily Reminder") { on ->
                            if (on) requestNotifications { settings.updateReminderEnabled(true) } else settings.updateReminderEnabled(false)
                        }
                    }
                    if (settings.reminderEnabled) {
                        FormDivider()
                        Box(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                            TimePickerRow("Reminder Time", settings.reminderHour, settings.reminderMinute) { h, m -> settings.updateReminderTime(h, m) }
                        }
                    }
                    if (service.isPro) {
                        FormDivider()
                        FormRow("Game Night Prep", icon = "person.2.fill", onClick = { navigator.push(Route.GameNightPrep) }) { Chevron() }
                    }
                }
                FormSection("Membership") {
                    if (service.isPro) {
                        FormRow("${Membership.NAME} unlocked", icon = "checkmark.seal.fill", tint = colors.jade)
                        FormDivider()
                        FormRow("Manage Subscription", onClick = { context.openUrl(StoreLinks.manageSubscriptionURL(service.activeProductId)) }) { Chevron() }
                    } else {
                        FormRow("Get ${Membership.NAME}", icon = "sparkles", onClick = { actions.openPaywall("bridge_settings_sheet") }) { PlusBadge() }
                    }
                    FormDivider()
                    FormRow("Restore Purchases", tint = colors.jade, onClick = {
                        scope.launch {
                            restoreMessage = try {
                                service.restore()
                                if (service.isPro) "${Membership.NAME} restored!" else "No previous purchase found on this Google account."
                            } catch (error: PurchaseException) {
                                error.message
                            }
                        }
                    })
                }
                FormSection("Your Practice History") {
                    FormRow("Your Progress", icon = "chart.bar.fill", onClick = { navigator.push(Route.Stats) }) { Chevron() }
                    FormDivider()
                    FormRow("Reset Progress", tint = colors.crakRed, onClick = { confirmReset = true })
                }
                FormSection("Support") {
                    FormDivider()
                    FormRow("How to Play", icon = "book.fill", onClick = { navigator.push(Route.HowToPlay) }) { Chevron() }
                    if (graph.whatsNew.currentRelease != null) {
                        FormDivider()
                        FormRow("What's New", icon = "sparkle", onClick = { actions.openWhatsNew() })
                    }
                    FormDivider()
                    FormRow("Rate Bridge Trainer", icon = "star.fill", onClick = {
                        graph.review.markOpenedWriteReview()
                        context.openPlayListing()
                    })
                    FormDivider()
                    FormRow("Send Feedback", icon = "envelope.fill", onClick = { actions.openFeedback() })
                }
                FormSection("About") {
                    // Long press opens the private reviewer access for Google Play's review team.
                    FormRow(
                        "Version",
                        Modifier.testTag("version-row").combinedClickable(onClick = {}, onLongClick = { showReviewerCode = true }),
                    ) { Text(BuildConfig.VERSION_NAME, style = BridgeType.body, color = colors.inkSecondary) }
                    FormDivider()
                    Text(
                        "Bridge Trainer teaches beginner Standard American bidding, declarer play, and defense. Partnership agreements vary, so always confirm conventions with your partner.",
                        style = BridgeType.footnote,
                        color = colors.inkSecondary,
                        modifier = Modifier.padding(16.dp),
                    )
                }
                if (BuildConfig.DEBUG) {
                    FormSection("Developer") {
                        FormRow("Local ${Membership.NAME} override") {
                            BridgeSwitch(service.isPro, "Local override") { service.setLocalOverride(it) }
                        }
                    }
                }
            }
        }
    }

    restoreMessage?.let { BridgeAlert("Restore", it, onConfirm = { restoreMessage = null }) }
    if (showReviewerCode) ReviewerCodeDialog { showReviewerCode = false }
    if (confirmReset) {
        BridgeAlert(
            "Reset all progress?",
            "Your streak, completed drills, and practice history will be cleared. Purchases are not affected.",
            confirmTitle = "Reset",
            destructive = true,
            dismissTitle = "Cancel",
            onConfirm = {
                confirmReset = false
                graph.resetProgress()
            },
            onDismiss = { confirmReset = false },
        )
    }
    // The "Notifications are off" alert lives in RootScreen, next to the
    // permission request, so Game Night Prep gets it too.
}

/** Private unlock for Google Play's review team; only the code's SHA-256 ships in the app. */
@Composable
private fun ReviewerCodeDialog(onDismiss: () -> Unit) {
    val service = LocalGraph.current.subscriptions
    val colors = BridgeUI.colors
    var code by remember { mutableStateOf("") }
    var failed by remember { mutableStateOf(false) }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.card,
        titleContentColor = colors.ink,
        title = { Text("Reviewer Access", style = BridgeType.headline) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Enter the reviewer code provided with this app's review notes.", style = BridgeType.subheadline, color = colors.inkSecondary)
                OutlinedTextField(
                    code,
                    { code = it; failed = false },
                    singleLine = true,
                    textStyle = BridgeType.body.copy(color = colors.ink),
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = colors.jade, unfocusedBorderColor = colors.rule, cursorColor = colors.jade),
                    modifier = Modifier.testTag("reviewer-code"),
                )
                if (failed) Text("That code isn't valid.", style = BridgeType.caption, color = colors.crakRed)
            }
        },
        confirmButton = {
            TextButton(onClick = { if (service.activateReviewAccess(code)) onDismiss() else failed = true }, modifier = Modifier.testTag("reviewer-unlock")) {
                Text("Unlock", style = BridgeType.headline, color = colors.jade)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel", style = BridgeType.body, color = colors.inkSecondary) } },
    )
}

@Composable
private fun Chevron() {
    Icon(symbol("chevron.right"), null, tint = BridgeUI.colors.inkTertiary, modifier = Modifier.size(18.dp))
}

/**
 * Shown once on the first launch after an update: what a member already owns,
 * or what the membership would add. One dismiss, at most one soft upgrade.
 */
@Composable
fun WhatsNewSheet(onClose: () -> Unit, onUpgrade: () -> Unit) {
    val graph = LocalGraph.current
    val colors = BridgeUI.colors
    val release = graph.whatsNew.currentRelease ?: return
    val isPro = graph.subscriptions.isPro
    val hasLocked = !isPro && release.items.any { it.isPlus }
    fun close() {
        graph.whatsNew.markSeen()
        onClose()
    }
    Column(Modifier.fillMaxSize()) {
        BridgeBar("", onBack = null, trailing = { BarTextButton("Done", colors.inkSecondary) { close() } }, inSheet = true)
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("WHAT'S NEW", style = BridgeType.eyebrow, color = colors.inkSecondary)
                Text(release.headline, style = BridgeType.display(30.sp), color = colors.ink)
                Text("Version ${release.version}", style = BridgeType.footnote, color = colors.inkTertiary)
            }
            release.items.forEach { item ->
                val locked = item.isPlus && !isPro
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    IconBadge(item.icon, if (locked) colors.gold else colors.jade, size = 42.dp, iconSize = 22.dp, corner = 13.dp)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(item.title, style = BridgeType.headline, color = colors.ink)
                            if (locked) PlusBadge()
                        }
                        Text(item.body, style = BridgeType.subheadline, color = colors.inkSecondary)
                    }
                }
            }
        }
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 10.dp).padding(navBarPadding(0.dp)), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (hasLocked) {
                PrimaryCTA("Unlock with ${Membership.NAME}", color = colors.gold) {
                    graph.whatsNew.markSeen()
                    onUpgrade()
                }
                QuietButton("Keep practicing free", Modifier.fillMaxWidth()) { close() }
            } else {
                PrimaryCTA("Start practicing") { close() }
            }
        }
    }
}

/** Feedback goes to a real person through the mail app, and only claims success if one opened. */
@Composable
fun FeedbackSheet(onClose: () -> Unit) {
    val graph = LocalGraph.current
    val context = LocalContext.current
    val clipboard: ClipboardManager = LocalClipboardManager.current
    val colors = BridgeUI.colors
    var text by remember { mutableStateOf("") }
    var mailFailed by remember { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    val trimmed = text.trim()
    Column(Modifier.fillMaxSize()) {
        BridgeBar("Help us improve", onBack = null, leading = { BarTextButton("Cancel", colors.inkSecondary, onClick = onClose) }, inSheet = true)
        Column(Modifier.weight(1f).padding(24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("What would make Bridge Trainer better for you?", style = BridgeType.headline, color = colors.ink)
            BasicTextField(
                text,
                { text = it },
                textStyle = BridgeType.body.copy(color = colors.ink),
                cursorBrush = SolidColor(colors.jade),
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f, fill = false)
                    .testTag("feedback-text")
                    .focusRequester(focus)
                    .themedCard(14.dp)
                    .padding(12.dp),
                minLines = 6,
            )
            if (mailFailed) {
                // Plenty of people have no mail app set up; say so rather than claim it sent.
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Your mail app didn't open. You can email us directly:", style = BridgeType.caption, color = colors.ink)
                    Row(
                        Modifier.testTag("copy-email").pressable {
                            clipboard.setText(AnnotatedString(StoreLinks.FEEDBACK_EMAIL))
                            Haptics.success()
                        }.padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Icon(symbol("doc.on.doc"), null, tint = colors.jade, modifier = Modifier.size(14.dp))
                        Text("Copy ${StoreLinks.FEEDBACK_EMAIL}", style = BridgeType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.jade)
                    }
                }
            } else {
                Text("Opens your mail app with a draft to the developer. It goes to a real person.", style = BridgeType.caption, color = colors.inkSecondary)
            }
            PrimaryCTA("Send feedback", Modifier.testTag("send-feedback"), enabled = trimmed.isNotEmpty()) {
                if (context.openFeedbackMail(trimmed)) {
                    onClose()
                } else {
                    mailFailed = true
                }
            }
        }
    }
}
