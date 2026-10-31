package com.jackwallner.bridge.ui.screens

import android.os.SystemClock
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.content.EndlessPractice
import com.jackwallner.bridge.content.BridgeMinuteContent
import com.jackwallner.bridge.content.QuickItem
import com.jackwallner.bridge.content.SessionBuilder
import com.jackwallner.bridge.data.BridgeMinuteResult
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.DrillProgress
import com.jackwallner.bridge.ui.components.DrillStage
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.nav.LocalNavigator
import com.jackwallner.bridge.ui.nav.PracticeMode
import com.jackwallner.bridge.ui.nav.SessionPurpose
import com.jackwallner.bridge.ui.theme.BarTextButton
import com.jackwallner.bridge.ui.theme.Haptics
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeScreen
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.PrimaryCTA
import com.jackwallner.bridge.ui.theme.screenPadding
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private fun QuickItem.asQuestion(): ChoiceQuestion = ChoiceQuestion(
    key = id,
    prompt = prompt,
    cards = cards,
    labels = choices,
    answerIndex = answerIndex,
    explanation = explanation,
    eyebrow = sourceLabel.uppercase(),
)

private fun particleCount(streak: Int) = when {
    streak >= 10 -> 90
    streak >= 5 -> 60
    streak >= 3 -> 44
    else -> 28
}

private val SessionPurpose.drill: Drill
    get() = when (this) {
        is SessionPurpose.Quick -> SessionBuilder.sessionDrill
        is SessionPurpose.Minute -> BridgeMinuteContent.drill
        SessionPurpose.GameNightPrep -> SessionBuilder.gameNightPrepDrill
    }

/**
 * Get Started, Bridge Minute and Game Night Prep: a short, uniform run of
 * single-select items. Pick, grade immediately, the answer holds, explicit
 * Next. The item list is the one the route snapshotted, never re-derived.
 */
@Composable
fun SessionScreen(items: List<QuickItem>, purpose: SessionPurpose, onClose: (() -> Unit)? = null) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = BridgeUI.colors
    val scope = rememberCoroutineScope()
    val close = onClose ?: { navigator.pop(); Unit }
    var index by rememberSaveable { mutableIntStateOf(0) }
    var score by rememberSaveable { mutableIntStateOf(0) }
    var selection by rememberSaveable { mutableStateOf<Int?>(null) }
    var answers by rememberSaveable { mutableStateOf(listOf<Boolean>()) }
    var finished by rememberSaveable { mutableStateOf(false) }
    var minuteResult by remember { mutableStateOf<BridgeMinuteResult?>(null) }
    var streak by remember { mutableIntStateOf(0) }
    var confetti by remember { mutableIntStateOf(0) }
    var particles by remember { mutableIntStateOf(30) }
    var banner by remember { mutableStateOf<String?>(null) }
    var bannerTrigger by remember { mutableIntStateOf(0) }
    var answerRect by remember { mutableStateOf<Rect?>(null) }
    val flash = remember { Animatable(0f) }

    if (finished) {
        val result = minuteResult
        if (purpose is SessionPurpose.Minute && result != null) {
            BridgeMinuteResultScreen(result, recordsCompletion = true, onDone = close)
        } else {
            DrillCompleteScreen(purpose.drill, score, items.size, onDone = close)
        }
        return
    }
    if (items.isEmpty()) {
        // Not a finished round: it must not bank a streak day for a session that asked nothing.
        BridgeScreen(purpose.drill.title, onBack = close) {
            EmptyRunScreen("tray", "Nothing to practice", "No questions could be prepared for this session. Try again in a moment.", close)
        }
        return
    }
    val item = items[index]
    BridgeScreen(
        purpose.drill.title,
        onBack = if (onClose == null) close else null,
        leading = if (onClose != null) { { BarTextButton("Close", colors.inkSecondary, onClick = onClose) } } else null,
    ) {
        DrillStage(confetti, particleCount = particles, answerRect = answerRect, flash = flash.value) {
            ChoiceQuestionBody(
                item.asQuestion(),
                selection,
                nextTitle = if (index + 1 < items.size) "Next" else "Finish",
                footerLabel = "${index + 1} of ${items.size}",
                onPick = { pick ->
                    if (selection != null) return@ChoiceQuestionBody
                    selection = pick
                    val correct = pick == item.answerIndex
                    answers = answers + correct
                    graph.recordAnswer(item.trackingID, item.roomID, correct, item.isReviewable)
                    if (correct) {
                        score += 1
                        streak += 1
                        particles = particleCount(streak)
                        confetti += 1
                        celebrateCorrect()
                        scope.launch {
                            flash.snapTo(0.14f)
                            flash.animateTo(0f, tween(500))
                        }
                        if (streak in setOf(3, 5, 10)) {
                            Haptics.rigid()
                            bannerTrigger += 1
                            val trigger = bannerTrigger
                            banner = "$streak in a row!"
                            scope.launch {
                                delay(1_600)
                                if (trigger == bannerTrigger) banner = null
                            }
                        }
                    } else {
                        streak = 0
                        consoleMiss()
                    }
                },
                onNext = {
                    if (index + 1 < items.size) {
                        selection = null
                        index += 1
                    } else {
                        when (purpose) {
                            is SessionPurpose.Quick -> if (purpose.isDaily) graph.progress.markQuickSessionCompleted()
                            is SessionPurpose.Minute -> minuteResult = graph.minutes.record(purpose.challenge, answers)
                            SessionPurpose.GameNightPrep -> Unit
                        }
                        finished = true
                    }
                },
                onAnswerBounds = { answerRect = it },
            ) { DrillProgress(index, items.size) }
            StreakBannerOverlay(banner, Modifier.align(Alignment.TopCenter).padding(top = 6.dp))
        }
    }
}

@Composable
private fun StreakBannerOverlay(banner: String?, modifier: Modifier) {
    AnimatedVisibility(
        banner != null,
        enter = slideInVertically { -it } + fadeIn(),
        exit = slideOutVertically { -it } + fadeOut(),
        modifier = modifier,
    ) { StreakBanner(banner.orEmpty()) }
}

/** Brief pill for a consecutive-correct milestone (3, 5, 10 in a row). */
@Composable
private fun StreakBanner(text: String) {
    val colors = BridgeUI.colors
    Row(
        Modifier
            .shadow(10.dp, CircleShape, ambientColor = colors.coral, spotColor = colors.coral)
            .background(colors.coral, CircleShape)
            .padding(horizontal = 16.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(symbol("flame.fill"), null, tint = androidx.compose.ui.graphics.Color.White, modifier = Modifier.size(16.dp))
        Text(text, style = BridgeType.subheadline.copy(fontWeight = FontWeight.ExtraBold), color = androidx.compose.ui.graphics.Color.White)
    }
}

private const val CHALLENGE_SECONDS = 90
private const val BATCH_SIZE = 8
private const val TOP_UP_THRESHOLD = 3

/**
 * The runner behind Endless Practice, the Timed Challenge and Fix My
 * Mistakes: the Quick Session beat, with a different source and end.
 */
@Composable
fun PracticeRunScreen(mode: PracticeMode, initialItems: List<QuickItem>) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = BridgeUI.colors
    val scope = rememberCoroutineScope()
    var items by remember {
        mutableStateOf(
            when (mode) {
                is PracticeMode.Endless -> EndlessPractice.items(mode.skill, BATCH_SIZE)
                PracticeMode.Timed -> EndlessPractice.mixedItems(BATCH_SIZE)
                PracticeMode.Review -> initialItems
            },
        )
    }
    var index by remember { mutableIntStateOf(0) }
    var score by remember { mutableIntStateOf(0) }
    var attempted by remember { mutableIntStateOf(0) }
    var selection by remember { mutableStateOf<Int?>(null) }
    var finished by remember { mutableStateOf(false) }
    var secondsLeft by remember { mutableIntStateOf(CHALLENGE_SECONDS) }
    var streak by remember { mutableIntStateOf(0) }
    var confetti by remember { mutableIntStateOf(0) }
    var particles by remember { mutableIntStateOf(30) }
    var answerRect by remember { mutableStateOf<Rect?>(null) }
    val flash = remember { Animatable(0f) }

    val title = when (mode) {
        is PracticeMode.Endless -> mode.skill.title
        PracticeMode.Timed -> "Timed Challenge"
        PracticeMode.Review -> "Fix My Mistakes"
    }
    val completedDrill = when (mode) {
        is PracticeMode.Endless -> EndlessPractice.drill(mode.skill)
        PracticeMode.Timed -> EndlessPractice.challengeDrill
        PracticeMode.Review -> SessionBuilder.reviewDrill
    }

    fun finish() {
        if (mode == PracticeMode.Timed) graph.records.recordChallengeScore(score)
        // A run quit before answering anything is not an achievement.
        if (mode.completionTotal(attempted) == null) navigator.pop() else finished = true
    }

    // Backing out of a timed run keeps the score rather than throwing it away.
    val latest = rememberUpdatedState(Triple(finished, attempted, score))
    DisposableEffect(Unit) {
        onDispose {
            val (done, count, points) = latest.value
            if (mode == PracticeMode.Timed && !done && count > 0) graph.records.recordChallengeScore(points)
        }
    }

    // A deadline, as on iOS, not a count of ticks: a paused or backgrounded
    // scheduler still counted one second per tick, so a run could last well
    // past ninety real seconds and its best score meant nothing.
    var clockEnd by remember { mutableStateOf<Long?>(null) }
    LaunchedEffect(Unit) {
        if (mode != PracticeMode.Timed) return@LaunchedEffect
        val end = clockEnd ?: (SystemClock.elapsedRealtime() + CHALLENGE_SECONDS * 1_000L).also { clockEnd = it }
        while (secondsLeft > 0 && !finished) {
            delay(250)
            val remaining = end - SystemClock.elapsedRealtime()
            secondsLeft = if (remaining <= 0) 0 else ((remaining + 999) / 1_000).toInt()
        }
        if (!finished) {
            Haptics.rigid()
            finish()
        }
    }

    if (finished) {
        DrillCompleteScreen(completedDrill, score, mode.completionTotal(attempted) ?: 0) { navigator.pop() }
        return
    }
    if (items.isEmpty()) {
        BridgeScreen(title, onBack = { navigator.pop() }) {
            if (mode == PracticeMode.Review) {
                EmptyRunScreen("checkmark.circle", "Nothing due", "You have no mistakes waiting right now. Keep practicing and anything you miss will show up here.") { navigator.pop() }
            } else {
                EmptyRunScreen("checkmark.circle", "Nothing to practice", "No questions could be prepared for this run. Try again in a moment.") { navigator.pop() }
            }
        }
        return
    }
    val item = items[minOf(index, items.size - 1)]
    val isLast = mode == PracticeMode.Review && index + 1 >= items.size
    BridgeScreen(
        title,
        onBack = { navigator.pop() },
        trailing = if (mode != PracticeMode.Timed) {
            { BarTextButton(if (mode == PracticeMode.Review) "Close" else "Finish") { finish() } }
        } else null,
    ) {
        DrillStage(confetti, particleCount = particles, answerRect = answerRect, flash = flash.value) {
            ChoiceQuestionBody(
                item.asQuestion(),
                selection,
                nextTitle = if (isLast) "Finish" else "Next",
                footerLabel = if (mode == PracticeMode.Review) "${index + 1} of ${items.size}" else "Question ${index + 1}",
                onPick = { pick ->
                    if (selection != null) return@ChoiceQuestionBody
                    selection = pick
                    attempted += 1
                    val correct = pick == item.answerIndex
                    graph.records.record(item.id, item.roomID, correct)
                    // Generated ids are unique per question; feeding them to the seen/missed sets teaches nothing.
                    if (!mode.isGenerated) graph.progress.recordItem(item.id, correct)
                    if (correct) {
                        score += 1
                        streak += 1
                        particles = particleCount(streak)
                        confetti += 1
                        celebrateCorrect()
                        scope.launch {
                            flash.snapTo(0.14f)
                            flash.animateTo(0f, tween(500))
                        }
                    } else {
                        streak = 0
                        consoleMiss()
                    }
                },
                onNext = {
                    if (isLast) {
                        finish()
                    } else {
                        if (mode.isGenerated && items.size - index <= TOP_UP_THRESHOLD) {
                            items = items + when (mode) {
                                is PracticeMode.Endless -> EndlessPractice.items(mode.skill, BATCH_SIZE)
                                else -> EndlessPractice.mixedItems(BATCH_SIZE)
                            }
                        }
                        selection = null
                        index += 1
                    }
                },
                onAnswerBounds = { answerRect = it },
            ) {
                when (mode) {
                    PracticeMode.Timed -> Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                        val urgent = secondsLeft <= 10
                        Icon(symbol("timer"), null, tint = if (urgent) colors.coral else colors.inkSecondary, modifier = Modifier.size(20.dp))
                        Text(
                            " ${secondsLeft}s",
                            style = BridgeType.title3.copy(fontWeight = FontWeight.Bold),
                            color = if (urgent) colors.coral else colors.ink,
                            modifier = Modifier.testTag("seconds-left"),
                        )
                        Spacer(Modifier.weight(1f))
                        Text("$score correct", style = BridgeType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.jade)
                    }
                    PracticeMode.Review -> DrillProgress(index, items.size)
                    is PracticeMode.Endless -> Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text("$score of $attempted correct", style = BridgeType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary)
                        Spacer(Modifier.weight(1f))
                        if (streak >= 3) {
                            Icon(symbol("flame.fill"), null, tint = colors.coral, modifier = Modifier.size(16.dp))
                            Text(" $streak", style = BridgeType.subheadline.copy(fontWeight = FontWeight.Bold), color = colors.coral)
                        }
                    }
                }
            }
        }
    }
}
