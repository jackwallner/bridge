package com.jackwallner.bridge.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.VectorConverter
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
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
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.model.ChoiceShuffle
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.model.Flashcard
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.ConfettiBurst
import com.jackwallner.bridge.ui.components.BridgeHandView
import com.jackwallner.bridge.ui.components.shine
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.nav.LocalNavigator
import com.jackwallner.bridge.ui.theme.BarIconButton
import com.jackwallner.bridge.ui.theme.CapsuleBar
import com.jackwallner.bridge.ui.theme.Haptics
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeGeo
import com.jackwallner.bridge.ui.theme.BridgeScreen
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.PrimaryCTA
import com.jackwallner.bridge.ui.theme.pressable
import com.jackwallner.bridge.ui.theme.rounded
import com.jackwallner.bridge.ui.theme.screenPadding
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val HAS_SWIPED_DECK = "bridge.hasSwipedDeck"

private data class SwipeRecord(val card: Flashcard, val gotIt: Boolean)

/**
 * Flashcards as a swipeable deck. Tap flips the card; only a flipped card can
 * be swiped. Right is "knew it" (leaves the deck), left is "again" (returns
 * at the back). Cards with a self-test choice are graded by the pick, and the
 * held result advances with Next.
 */
@Composable
fun FlashcardDrillScreen(drill: Drill, cards: List<Flashcard>, accent: Color) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = BridgeUI.colors
    val scope = rememberCoroutineScope()
    val roomID = remember(drill.id) { DrillLibrary.roomID(drill.id) }

    var queueIds by rememberSaveable { mutableStateOf(cards.map { it.id }) }
    val queue = queueIds.mapNotNull { id -> cards.firstOrNull { it.id == id } }
    var flipped by rememberSaveable { mutableStateOf(false) }
    var choicePick by rememberSaveable { mutableStateOf<Int?>(null) }
    var finished by rememberSaveable { mutableStateOf(false) }
    var flinging by remember { mutableStateOf(false) }
    var lastSwipe by remember { mutableStateOf<SwipeRecord?>(null) }
    var confetti by remember { mutableIntStateOf(0) }
    var didHint by remember { mutableStateOf(false) }
    val drag = remember { Animatable(Offset.Zero, Offset.VectorConverter) }
    val fade = remember { Animatable(1f) }

    if (finished) {
        DrillCompleteScreen(drill, null, cards.size) { navigator.pop() }
        return
    }

    val choiceAnswered = queue.firstOrNull()?.choice != null && choicePick != null

    fun maybeHint() {
        if (graph.defaults.getBoolean(HAS_SWIPED_DECK) || didHint || queue.size <= 1) return
        didHint = true
        scope.launch {
            delay(700)
            if (flinging || !flipped || drag.value != Offset.Zero) return@launch
            drag.animateTo(Offset(52f * graph.appContext.resources.displayMetrics.density, 0f), spring(dampingRatio = 0.6f, stiffness = 300f))
            delay(430)
            if (!flinging) drag.animateTo(Offset.Zero, spring(dampingRatio = 0.72f, stiffness = 200f))
        }
    }

    fun commit(gotIt: Boolean) {
        val card = queue.firstOrNull() ?: return
        val choice = card.choice
        val pick = choicePick
        val knewIt = if (choice != null && pick != null) pick == choice.answerIndex else {
            graph.recordAnswer(card.id, roomID, gotIt)
            gotIt
        }
        lastSwipe = SwipeRecord(card, knewIt)
        choicePick = null
        val rest = queueIds.drop(1)
        queueIds = if (knewIt) rest else rest + card.id
        if (queueIds.isEmpty()) {
            Haptics.success()
            finished = true
        }
    }

    fun fling(direction: Float, width: Float) {
        if (flinging) return
        flinging = true
        graph.defaults.putBoolean(HAS_SWIPED_DECK, true)
        Haptics.rigid()
        scope.launch {
            coroutineScope {
                launch { drag.animateTo(Offset(direction * width * 1.5f, drag.value.y * 1.1f), tween(340, easing = FastOutLinearInEasing)) }
                launch { fade.animateTo(0f, tween(340)) }
            }
            commit(direction > 0)
            drag.snapTo(Offset.Zero)
            fade.snapTo(1f)
            flipped = false
            flinging = false
        }
    }

    fun flip() {
        if (flinging || choiceAnswered) return
        Haptics.soft()
        flipped = !flipped
        if (flipped) maybeHint()
    }

    fun choose(index: Int, card: Flashcard) {
        val choice = card.choice ?: return
        if (choicePick != null || flipped || flinging) return
        choicePick = index
        val correct = index == choice.answerIndex
        graph.recordAnswer(card.id, roomID, correct)
        if (correct) {
            confetti += 1
            celebrateCorrect()
        } else {
            consoleMiss()
        }
        flipped = true
        maybeHint()
    }

    fun undo() {
        val record = lastSwipe ?: return
        if (flinging) return
        Haptics.light()
        lastSwipe = null
        choicePick = null
        var ids = queueIds
        if (!record.gotIt && ids.lastOrNull() == record.card.id) ids = ids.dropLast(1)
        queueIds = listOf(record.card.id) + ids
        flipped = false
    }

    val mastered = cards.size - queue.size
    BridgeScreen(
        drill.title,
        onBack = { navigator.pop() },
        trailing = {
            if (lastSwipe != null) BarIconButton("arrow.uturn.backward", "Undo last answer", colors.jade) { undo() }
        },
    ) {
        Box(Modifier.fillMaxSize()) {
            Column(Modifier.fillMaxSize().screenPadding(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    CapsuleBar(mastered.toFloat() / maxOf(cards.size, 1), accent)
                    Text("$mastered of ${cards.size} down", style = BridgeType.footnote.copy(fontWeight = FontWeight.Medium), color = colors.inkSecondary)
                }
                BoxWithConstraints(Modifier.fillMaxWidth().weight(1f).padding(horizontal = 4.dp), contentAlignment = Alignment.Center) {
                    val cardWidth = minOf(maxWidth, 520.dp)
                    val cardHeight = minOf(maxHeight - 26.dp, cardWidth * 1.5f)
                    val density = LocalDensity.current
                    val widthPx = with(density) { cardWidth.toPx() }
                    val dismiss = maxOf(with(density) { 90.dp.toPx() }, widthPx * 0.30f)
                    val raw = drag.value
                    val effective = if (!flipped && !flinging) Offset(raw.x * 0.16f, raw.y * 0.10f) else raw
                    val progress01 = if (flipped) minOf(1f, abs(raw.x) / with(density) { 110.dp.toPx() }) else 0f
                    Box(Modifier.padding(bottom = 26.dp), contentAlignment = Alignment.TopCenter) {
                        queue.take(3).withIndex().reversed().forEach { (slot, card) ->
                            val restingScale = 1f - slot * 0.04f
                            val scale = if (slot == 0) 1f else restingScale + ((1f - (slot - 1) * 0.04f) - restingScale) * progress01
                            val restingY = slot * 24f
                            val yOffset = if (slot == 0) 0f else restingY + ((slot - 1) * 24f - restingY) * progress01
                            val top = slot == 0
                            var modifier = Modifier
                                .size(cardWidth, cardHeight)
                                .offset { IntOffset(0, with(density) { yOffset.dp.roundToPx() }) }
                                .graphicsLayer {
                                    scaleX = scale
                                    scaleY = scale
                                    if (top) {
                                        translationX = effective.x
                                        translationY = effective.y
                                        rotationZ = (effective.x / density.density / 14f).coerceIn(-12f, 12f)
                                        transformOrigin = TransformOrigin(0.5f, 1f)
                                        alpha = fade.value
                                    }
                                }
                            if (top) {
                                val tracker = remember(card.id) { VelocityTracker() }
                                modifier = modifier
                                    .testTag("deck-card")
                                    .semantics {
                                        contentDescription = if (flipped) "${card.backTitle}. ${card.backBody}" else card.frontTitle
                                        onClick(label = if (flipped) null else "Reveal the answer") {
                                            flip()
                                            true
                                        }
                                    }
                                    .pointerInput(card.id, flipped, choiceAnswered) {
                                        detectTapGestures(onTap = { flip() })
                                    }
                                    .pointerInput(card.id, flipped, choiceAnswered, widthPx) {
                                        var crossed = false
                                        detectDragGestures(
                                            onDragStart = { tracker.resetTracking() },
                                            onDragEnd = {
                                                crossed = false
                                                val dx = drag.value.x
                                                val velocity = tracker.calculateVelocity().x
                                                val flung = abs(dx) > dismiss || abs(dx + velocity * 0.25f) > widthPx * 0.75f
                                                if (flipped && !choiceAnswered && flung) {
                                                    fling(if (dx >= 0) 1f else -1f, widthPx)
                                                } else {
                                                    scope.launch { drag.animateTo(Offset.Zero, spring(dampingRatio = 0.78f, stiffness = 400f)) }
                                                }
                                            },
                                            onDragCancel = { scope.launch { drag.animateTo(Offset.Zero) } },
                                        ) { change, amount ->
                                            if (flinging) return@detectDragGestures
                                            change.consume()
                                            tracker.addPosition(change.uptimeMillis, change.position)
                                            scope.launch { drag.snapTo(drag.value + amount) }
                                            if (flipped) {
                                                val past = abs(drag.value.x) > dismiss
                                                if (past != crossed) {
                                                    crossed = past
                                                    if (past) Haptics.soft()
                                                }
                                            }
                                        }
                                    }
                            }
                            Box(modifier) {
                                FlipCard(
                                    card = card,
                                    flipped = top && flipped,
                                    accent = accent,
                                    choicePick = if (top) choicePick else null,
                                    onChoose = if (top) { index -> choose(index, card) } else null,
                                    onAdvance = if (top && choicePick != null) { { fling(1f, widthPx) } } else null,
                                )
                                if (top && flipped && !choiceAnswered) {
                                    val travel = raw.x / density.density
                                    Stamp("KNEW IT", colors.jade, -12f, (travel / 80f).coerceIn(0f, 1f), Modifier.align(Alignment.TopStart).padding(22.dp))
                                    Stamp("AGAIN", colors.coral, 12f, (-travel / 80f).coerceIn(0f, 1f), Modifier.align(Alignment.TopEnd).padding(22.dp))
                                }
                            }
                        }
                    }
                }
            }
            ConfettiBurst(confetti, origin = Offset(0.5f, 0.42f))
        }
    }
}

@Composable
private fun Stamp(text: String, color: Color, angle: Float, opacity: Float, modifier: Modifier) {
    if (opacity <= 0f) return
    Text(
        text,
        style = BridgeType.display(24.sp, FontWeight.Black),
        color = color,
        modifier = modifier
            .graphicsLayer { alpha = opacity }
            .rotate(angle)
            .border(3.dp, color, rounded(8.dp))
            .padding(horizontal = 10.dp, vertical = 4.dp),
    )
}

/**
 * One card, both faces, flipped as a single rigid unit: the whole card
 * rotates and the faces swap exactly at 90 degrees, while it is edge-on.
 */
@Composable
fun FlipCard(
    card: Flashcard,
    flipped: Boolean,
    accent: Color,
    choicePick: Int?,
    onChoose: ((Int) -> Unit)?,
    onAdvance: (() -> Unit)?,
    showsSwipeHints: Boolean = true,
) {
    val angle by animateFloatAsState(if (flipped) 180f else 0f, spring(dampingRatio = 0.8f, stiffness = 180f), label = "flip")
    var shineTrigger by remember { mutableIntStateOf(0) }
    val verdictCorrect = card.choice?.let { choice -> choicePick?.let { it == choice.answerIndex } }
    LaunchedEffect(flipped) {
        if (flipped && verdictCorrect == true) {
            delay(450)
            shineTrigger += 1
        }
    }
    Box(
        Modifier
            .fillMaxSize()
            .graphicsLayer {
                rotationY = angle
                cameraDistance = 14f * density
            }
            .shine(shineTrigger, BridgeGeo.deckCorner),
    ) {
        if (angle < 90f) {
            CardFront(card, accent, onChoose)
        } else {
            Box(Modifier.fillMaxSize().graphicsLayer { rotationY = 180f }) {
                CardBack(card, accent, choicePick, onAdvance, showsSwipeHints)
            }
        }
    }
}

@Composable
private fun CardFront(card: Flashcard, accent: Color, onChoose: ((Int) -> Unit)?) {
    val colors = BridgeUI.colors
    val count = card.frontCards.size
    val rows = maxOf(1, (count + 6) / 7)
    val widest = (count + rows - 1) / rows
    val tileWidth = when {
        widest <= 5 -> 52.dp
        widest == 6 -> 44.dp
        else -> 38.dp
    }
    BridgeCardFace(accent, "BRIDGE TRAINER") {
        Spacer(Modifier.weight(1f))
        Text(card.frontTitle, style = BridgeType.display(25.sp), color = colors.ink, textAlign = TextAlign.Center)
        if (card.frontCards.isNotEmpty()) BridgeHandView(card.frontCards, cardWidth = tileWidth)
        card.frontSubtitle?.let { Text(it, style = BridgeType.subheadline, color = colors.inkSecondary, textAlign = TextAlign.Center) }
        Spacer(Modifier.weight(1f))
        val choice = card.choice
        if (choice != null && onChoose != null) {
            val order = remember(card.id) { ChoiceShuffle.permutation(choice.options.size, card.id) }
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Make the call", style = BridgeType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkTertiary)
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    order.forEach { index ->
                        Box(
                            Modifier
                                .weight(1f)
                                .heightIn(min = 44.dp)
                                .testTag("card-choice-$index")
                                .pressable { onChoose(index) }
                                .background(accent.copy(alpha = 0.10f), rounded(13.dp))
                                .border(1.5.dp, accent.copy(alpha = 0.45f), rounded(13.dp))
                                .padding(8.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                choice.options[index],
                                style = BridgeType.subheadline.copy(fontWeight = FontWeight.SemiBold),
                                color = accent,
                                textAlign = TextAlign.Center,
                                maxLines = 2,
                            )
                        }
                    }
                }
            }
        } else {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(symbol("hand.tap.fill"), null, tint = colors.inkTertiary, modifier = Modifier.size(14.dp))
                Text("Tap to reveal", style = BridgeType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkTertiary)
            }
        }
    }
}

@Composable
private fun CardBack(card: Flashcard, accent: Color, choicePick: Int?, onAdvance: (() -> Unit)?, showsSwipeHints: Boolean) {
    val colors = BridgeUI.colors
    BridgeCardFace(accent, "THE CALL") {
        val choice = card.choice
        if (choice != null && choicePick != null) {
            val correct = choicePick == choice.answerIndex
            val tint = if (correct) colors.jade else colors.coral
            val said = "You said \"${choice.options[choicePick]}\""
            Row(
                Modifier.background(tint.copy(alpha = 0.13f), CircleShape).padding(horizontal = 12.dp, vertical = 7.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Icon(symbol(if (correct) "checkmark.circle.fill" else "xmark.circle.fill"), null, tint = tint, modifier = Modifier.size(16.dp))
                Text(
                    if (correct) "$said. Right!" else "$said. Not this time.",
                    style = BridgeType.footnote.copy(fontWeight = FontWeight.SemiBold),
                    color = tint,
                    modifier = Modifier.testTag("card-verdict"),
                )
            }
        }
        Spacer(Modifier.weight(1f))
        Text(card.backTitle, style = BridgeType.display(22.sp), color = accent, textAlign = TextAlign.Center)
        Box(Modifier.size(44.dp, 2.dp).background(colors.rule))
        Text(card.backBody, style = BridgeType.body, color = colors.ink, textAlign = TextAlign.Center)
        Spacer(Modifier.weight(1f))
        if (showsSwipeHints) {
            if (onAdvance != null) {
                PrimaryCTA("Next", Modifier.testTag("card-next"), color = accent, onClick = onAdvance)
            } else {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Icon(symbol("hand.draw.fill"), null, tint = colors.inkTertiary, modifier = Modifier.size(14.dp))
                    Text("Knew it? Swipe right · Again? Swipe left", style = BridgeType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkTertiary)
                }
            }
        }
    }
}

/** The bridge-card chrome both faces share: ivory surface, double frame, eyebrow and watermark. */
@Composable
private fun BridgeCardFace(accent: Color, eyebrow: String, content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit) {
    val colors = BridgeUI.colors
    val shape = rounded(BridgeGeo.deckCorner)
    Box(
        Modifier
            .fillMaxSize()
            .shadow(10.dp, shape, ambientColor = Color.Black.copy(alpha = 0.10f), spotColor = Color.Black.copy(alpha = 0.12f))
            .clip(shape)
            .background(colors.card)
            .border(1.dp, colors.rule, shape),
    ) {
        Text(
            "♠",
            style = BridgeType.display(190.sp),
            color = accent.copy(alpha = 0.05f),
            modifier = Modifier.align(Alignment.BottomEnd).offset(x = 60.dp, y = 70.dp).rotate(-10f),
        )
        Box(Modifier.fillMaxSize().padding(9.dp).border(1.5.dp, accent.copy(alpha = 0.28f), rounded(BridgeGeo.deckCorner - 9.dp)))
        Column(
            Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Box(Modifier.size(4.dp).background(accent.copy(alpha = 0.4f), CircleShape))
                Text(eyebrow, style = BridgeType.caption2.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = 2.2.sp), color = accent.copy(alpha = 0.65f))
                Box(Modifier.size(4.dp).background(accent.copy(alpha = 0.4f), CircleShape))
            }
            content()
        }
    }
}
