package com.jackwallner.bridge.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import com.jackwallner.bridge.AppGraph
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.ui.LocalAppActions
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.ConfettiBurst
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.theme.Haptics
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.PrimaryCTA
import com.jackwallner.bridge.ui.theme.SoundPlayer
import com.jackwallner.bridge.ui.theme.screenPadding
import com.jackwallner.bridge.ui.theme.themedCard

/** One graded answer, feeding both the daily mix and the review schedule. */
fun AppGraph.recordAnswer(itemID: String, roomID: String, correct: Boolean, isReviewable: Boolean = true) {
    if (isReviewable) progress.recordItem(itemID, correct)
    records.record(itemID, roomID, correct, isReviewable)
}

fun celebrateCorrect() {
    Haptics.correctAnswer()
    SoundPlayer.play(SoundPlayer.Effect.SUCCESS)
}

fun consoleMiss() {
    Haptics.wrongAnswer()
    SoundPlayer.play(SoundPlayer.Effect.MISS)
}

/**
 * The end of every drill: score, streak, confetti. Recording happens once, on
 * first appearance, and a finished drill is the review funnel's positive moment.
 */
@Composable
fun DrillCompleteScreen(drill: Drill, score: Int?, total: Int, onDone: () -> Unit) {
    val graph = LocalGraph.current
    val actions = LocalAppActions.current
    val colors = BridgeUI.colors
    var recorded by rememberSaveable { mutableStateOf(false) }
    var celebrate by rememberSaveable { mutableStateOf(false) }
    var confetti by rememberSaveable { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        celebrate = true
        confetti += 1
        if (recorded || total <= 0) return@LaunchedEffect
        recorded = true
        Haptics.success()
        SoundPlayer.play(SoundPlayer.Effect.COMPLETE)
        graph.progress.recordSession(drill.id)
        actions.positiveMoment()
    }
    val ring by animateFloatAsState(if (celebrate) 1f else 0.6f, spring(dampingRatio = 0.6f, stiffness = 300f), label = "ring")
    val fraction = if (score == null) 1.0 else score.toDouble() / maxOf(total, 1)
    val headline = when {
        score == null -> "Deck cleared!"
        fraction >= 1 -> "Perfect round!"
        fraction >= 0.7 -> "Nice work!"
        else -> "Good practice!"
    }
    val subheadline = if (score == null) "All $total cards down. They'll stick a little better every pass."
    else "Every decision you train here is one you'll make faster at the table."
    Box(Modifier.fillMaxSize().background(colors.background)) {
        Column(
            Modifier.fillMaxSize().screenPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            Spacer(Modifier.weight(1f))
            Box(contentAlignment = Alignment.Center) {
                Box(Modifier.size(132.dp).scale(ring).background(colors.jade.copy(alpha = 0.12f), CircleShape))
                if (score != null) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("$score/$total", style = BridgeType.display(34.sp), color = colors.jade, modifier = Modifier.testTag("drill-score"))
                        Text("right", style = BridgeType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary)
                    }
                } else {
                    Icon(symbol("checkmark.seal.fill"), null, tint = colors.jade, modifier = Modifier.size(58.dp))
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(headline, style = BridgeType.display(30.sp), color = colors.ink, textAlign = TextAlign.Center)
                Text(subheadline, style = BridgeType.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
            }
            Row(
                Modifier.themedCard(22.dp).padding(horizontal = 18.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Icon(symbol("flame.fill"), null, tint = colors.coral, modifier = Modifier.size(18.dp))
                Text("${graph.progress.streakCount}-day streak", style = BridgeType.headline, color = colors.ink)
            }
            Spacer(Modifier.weight(1f))
            PrimaryCTA("Done", Modifier.testTag("drill-done"), onClick = onDone)
        }
        ConfettiBurst(confetti, origin = Offset(0.5f, 0.3f), particleCount = 44)
    }
}

/** The counter line a drill shows under the question until it is answered. */
@Composable
fun FooterCounter(text: String) {
    Box(Modifier.fillMaxWidth().height(54.dp), contentAlignment = Alignment.Center) {
        Text(text, style = BridgeType.caption, color = BridgeUI.colors.inkTertiary)
    }
}

/** A body screen for a run with nothing in it: never scored as a finished round. */
@Composable
fun EmptyRunScreen(icon: String, title: String, body: String, onBack: () -> Unit) {
    val colors = BridgeUI.colors
    Column(
        Modifier.fillMaxSize().background(colors.background).screenPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Spacer(Modifier.weight(1f))
        Icon(symbol(icon), null, tint = colors.jade, modifier = Modifier.size(48.dp))
        Text(title, style = BridgeType.display(28.sp), color = colors.ink, textAlign = TextAlign.Center)
        Text(body, style = BridgeType.subheadline, color = colors.inkSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.weight(1f))
        PrimaryCTA("Back", onClick = onBack)
    }
}

