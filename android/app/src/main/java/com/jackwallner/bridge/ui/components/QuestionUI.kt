package com.jackwallner.bridge.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.pressable
import com.jackwallner.bridge.ui.theme.rounded
import com.jackwallner.bridge.ui.theme.CenteringScroll

/**
 * The shape every choice drill shares: prompt, cards, choices, and once
 * graded the explanation. The coaching scrolls into view when it appears.
 */
@Composable
fun QuestionPager(
    prompt: String,
    cards: List<BridgeCard>,
    explanation: String,
    answered: Boolean,
    modifier: Modifier = Modifier,
    eyebrow: String? = null,
    scroll: ScrollState = rememberScrollState(),
    choices: @Composable () -> Unit,
) {
    val colors = BridgeUI.colors
    LaunchedEffect(answered) {
        if (answered) scroll.animateScrollTo(scroll.maxValue)
    }
    LaunchedEffect(scroll.maxValue, answered) {
        if (answered) scroll.animateScrollTo(scroll.maxValue)
    }
    CenteringScroll(modifier, scroll) {
        Column(
            Modifier.fillMaxWidth().padding(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            if (eyebrow != null) {
                Text(eyebrow, style = BridgeType.caption2.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = BridgeType.eyebrow.letterSpacing), color = colors.inkTertiary)
            }
            Text(
                prompt,
                style = BridgeType.display(22.sp),
                color = colors.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp).testTag("question-prompt"),
            )
            if (cards.isNotEmpty()) BridgeHandView(cards)
            choices()
            AnimatedVisibility(answered, enter = fadeIn() + expandVertically()) {
                CoachNote(explanation)
            }
        }
    }
}

/** The gold lightbulb card that carries every explanation. */
@Composable
fun CoachNote(text: String, modifier: Modifier = Modifier) {
    val colors = BridgeUI.colors
    Row(
        modifier.fillMaxWidth().background(colors.gold.copy(alpha = 0.12f), rounded(14.dp)).padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(symbol("lightbulb.fill"), null, tint = colors.gold, modifier = Modifier.size(20.dp))
        Text(text, style = BridgeType.subheadline, color = colors.ink, modifier = Modifier.testTag("explanation"))
    }
}

/**
 * The answer rows. On reveal the correct answer lands: it pops, glows and a
 * shine sweeps across it, and the graded state holds until the drill's Next
 * button. The correct row is never dimmed.
 */
@Composable
fun ChoiceList(
    labels: List<String>,
    selection: Int?,
    answerIndex: Int,
    onAnswerBounds: (Rect) -> Unit = {},
    onPick: (Int) -> Unit,
) {
    val answered = selection != null
    var shineTrigger by remember { mutableIntStateOf(0) }
    var shakeTrigger by remember { mutableIntStateOf(0) }
    var landed by remember { mutableStateOf(false) }
    LaunchedEffect(answered) {
        if (!answered) {
            landed = false
            return@LaunchedEffect
        }
        landed = true
        shineTrigger += 1
        if (selection != answerIndex) shakeTrigger += 1
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        labels.forEachIndexed { index, label ->
            ChoiceRow(
                label = label,
                index = index,
                isAnswer = index == answerIndex,
                isMiss = answered && index == selection && index != answerIndex,
                answered = answered,
                landed = landed,
                shineTrigger = if (answered && index == answerIndex) shineTrigger else 0,
                shakeTrigger = if (answered && index == selection && index != answerIndex) shakeTrigger else 0,
                onAnswerBounds = onAnswerBounds,
                onPick = onPick,
            )
        }
    }
}

@Composable
private fun ChoiceRow(
    label: String,
    index: Int,
    isAnswer: Boolean,
    isMiss: Boolean,
    answered: Boolean,
    landed: Boolean,
    shineTrigger: Int,
    shakeTrigger: Int,
    onAnswerBounds: (Rect) -> Unit,
    onPick: (Int) -> Unit,
) {
    val colors = BridgeUI.colors
    val recedes = answered && !isAnswer && !isMiss
    val background by animateColorAsState(
        when {
            !answered -> colors.card
            isAnswer -> colors.bamGreen.copy(alpha = 0.18f)
            isMiss -> colors.crakRed.copy(alpha = 0.15f)
            else -> colors.card
        },
        label = "row-bg",
    )
    val border = when {
        !answered -> colors.rule
        isAnswer -> colors.bamGreen.copy(alpha = 0.6f)
        isMiss -> colors.crakRed.copy(alpha = 0.5f)
        else -> colors.rule
    }
    val pop by animateFloatAsState(if (answered && isAnswer && landed) 1.035f else 1f, spring(dampingRatio = 0.5f, stiffness = 400f), label = "pop")
    val glow = answered && isAnswer && landed
    val shape = rounded(14.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .shake(shakeTrigger)
            .scale(pop)
            .graphicsLayer { alpha = if (recedes) 0.72f else 1f }
            .shadow(if (glow) 14.dp else 0.dp, shape, ambientColor = colors.bamGreen, spotColor = colors.bamGreen)
            // An opaque base first: a translucent tint over an elevation shadow shows the shadow through it.
            .background(colors.card, shape)
            .background(background, shape)
            .border(if (answered && isAnswer) 2.5.dp else 1.dp, border, shape)
            .shine(shineTrigger, 14.dp)
            .onGloballyPositioned { if (isAnswer) onAnswerBounds(it.boundsInRoot()) }
            .testTag("choice-$index")
            .semantics {
                if (answered) stateDescription = when {
                    isAnswer -> "Correct answer"
                    isMiss -> "Your answer, incorrect"
                    else -> ""
                }
            }
            .pressable(enabled = !answered, role = Role.Button) { onPick(index) }
            .padding(16.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            label,
            style = BridgeType.body.copy(fontWeight = if (answered && isAnswer) FontWeight.SemiBold else FontWeight.Medium),
            color = colors.ink,
            modifier = Modifier.weight(1f),
        )
        Box(Modifier.width(22.dp), contentAlignment = Alignment.Center) {
            when {
                answered && isAnswer -> {
                    val iconScale by animateFloatAsState(if (landed) 1.2f else 0.4f, spring(dampingRatio = 0.5f), label = "check")
                    Icon(symbol("checkmark.circle.fill"), null, tint = colors.bamGreen, modifier = Modifier.size(20.dp).scale(iconScale))
                }
                answered && isMiss -> Icon(symbol("xmark.circle.fill"), null, tint = colors.crakRed, modifier = Modifier.size(20.dp))
                else -> Spacer(Modifier.size(22.dp))
            }
        }
    }
}

/** A drill's progress line. */
@Composable
fun DrillProgress(value: Int, total: Int) {
    com.jackwallner.bridge.ui.theme.CapsuleBar(value.toFloat() / maxOf(total, 1), BridgeUI.colors.jade, height = 4.dp)
}

/**
 * Hosts a drill body with a full-size confetti overlay. [answerRect] is in
 * root coordinates, as ChoiceList reports it; the host converts to its own.
 */
@Composable
fun DrillStage(
    confettiTrigger: Int,
    modifier: Modifier = Modifier,
    particleCount: Int = 30,
    origin: Offset = Offset(0.5f, 0.35f),
    answerRect: Rect? = null,
    flash: Float = 0f,
    content: @Composable BoxScope.() -> Unit,
) {
    var hostOrigin by remember { mutableStateOf(Offset.Zero) }
    Box(modifier.fillMaxSize().onGloballyPositioned { hostOrigin = it.positionInRoot() }) {
        content()
        if (flash > 0f) Box(Modifier.fillMaxSize().background(BridgeUI.colors.bamGreen.copy(alpha = flash)))
        ConfettiBurst(
            confettiTrigger,
            particleCount = particleCount,
            origin = origin,
            source = answerRect?.translate(-hostOrigin.x, -hostOrigin.y),
        )
    }
}

/** Sentence-cases a fragment that was authored to sit mid-sentence. */
val String.capitalizedFirst: String get() = replaceFirstChar { it.uppercase() }
