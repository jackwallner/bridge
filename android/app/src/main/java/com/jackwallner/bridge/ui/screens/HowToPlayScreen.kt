package com.jackwallner.bridge.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.content.HowToPlayContent
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.ConfettiBurst
import com.jackwallner.bridge.ui.components.BridgeHandView
import com.jackwallner.bridge.ui.components.shine
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.theme.Haptics
import com.jackwallner.bridge.ui.theme.IconBadge
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeGeo
import com.jackwallner.bridge.ui.theme.BridgeScreen
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.PrimaryCTA
import com.jackwallner.bridge.ui.theme.QuietButton
import com.jackwallner.bridge.ui.theme.Readable
import com.jackwallner.bridge.ui.theme.pressable
import com.jackwallner.bridge.ui.theme.rounded
import com.jackwallner.bridge.ui.theme.screenPadding
import com.jackwallner.bridge.ui.theme.themedCard
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * The How to Play primer. Runs inside onboarding (with [onSkip] as the
 * escape hatch) and re-opens from Home and Settings. Pages by swipe and by
 * buttons; Back sits next to Continue where the thumb already is.
 */
@Composable
fun HowToPlayScreen(onDone: () -> Unit, onSkip: (() -> Unit)? = null, onBack: (() -> Unit)? = null) {
    val graph = LocalGraph.current
    val colors = BridgeUI.colors
    val scope = rememberCoroutineScope()
    val pages = HowToPlayContent.pages
    var index by rememberSaveable { mutableIntStateOf(0) }
    var forward by remember { mutableStateOf(true) }
    var shineTrigger by remember { mutableIntStateOf(0) }
    var confetti by remember { mutableIntStateOf(0) }
    val drag = remember { Animatable(0f) }
    val skillLevel = graph.defaults.getString(SKILL_LEVEL).orEmpty()
    val recommended = HowToPlayContent.recommendedRoom(skillLevel)
    val isFirst = index == 0
    val isLast = index == pages.lastIndex

    LaunchedEffect(index) {
        delay(350)
        shineTrigger += 1
    }

    fun advance() {
        if (isLast) {
            Haptics.success()
            graph.defaults.putBoolean(HAS_READ_PRIMER, true)
            graph.defaults.putString(RECOMMENDED_ROOM_HINT, recommended.id)
            onDone()
            return
        }
        Haptics.soft()
        forward = true
        index += 1
        if (index == pages.lastIndex) confetti += 1
    }

    fun goBack() {
        if (isFirst) return
        Haptics.soft()
        forward = false
        index -= 1
    }

    BridgeScreen("How to Play", onBack = onBack) {
        Box(Modifier.fillMaxSize()) {
            Readable(Modifier.fillMaxSize()) {
                Column(Modifier.fillMaxSize().screenPadding(), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    Dots(pages.size, index, Modifier.align(Alignment.CenterHorizontally).padding(top = 6.dp))
                    AnimatedContent(
                        targetState = index,
                        transitionSpec = {
                            val direction = if (forward) 1 else -1
                            (slideInHorizontally(tween(320)) { it * direction } + fadeIn(tween(320))) togetherWith
                                (slideOutHorizontally(tween(320)) { -it * direction } + fadeOut(tween(320)))
                        },
                        modifier = Modifier.fillMaxWidth().weight(1f),
                        label = "primer",
                    ) { shown ->
                        val page = pages[shown]
                        Column(
                            Modifier.fillMaxSize().verticalScroll(rememberScrollState()),
                            verticalArrangement = Arrangement.Center,
                        ) {
                            Column(
                                Modifier
                                    .fillMaxWidth()
                                    .graphicsLayer {
                                        translationX = drag.value
                                        rotationZ = drag.value / density / 40f
                                        transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0.5f, 1f)
                                    }
                                    .pointerInput(shown) {
                                        detectHorizontalDragGestures(
                                            onDragEnd = {
                                                val travel = drag.value
                                                scope.launch { drag.animateTo(0f, spring(dampingRatio = 0.8f)) }
                                                if (travel < -60 * density && shown < pages.lastIndex) advance()
                                                else if (travel > 60 * density && shown > 0) goBack()
                                            },
                                        ) { change, amount ->
                                            change.consume()
                                            val atEdge = (amount > 0 && shown == 0) || (amount < 0 && shown == pages.lastIndex)
                                            scope.launch { drag.snapTo(drag.value + if (atEdge) amount * 0.25f else amount) }
                                        }
                                    }
                                    .themedCard(22.dp)
                                    .shine(shineTrigger, 22.dp)
                                    .padding(24.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(16.dp),
                            ) {
                                IconBadge(page.icon, colors.jade, size = 76.dp, iconSize = 34.dp, alpha = 0.12f)
                                Text(page.title, style = BridgeType.display(27.sp), color = colors.ink, textAlign = TextAlign.Center)
                                if (page.cards.isNotEmpty()) BridgeHandView(page.cards, cardWidth = 46.dp)
                                Text(page.body, style = BridgeType.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
                                page.tip?.let { tip ->
                                    Row(
                                        Modifier.fillMaxWidth().background(colors.gold.copy(alpha = 0.12f), rounded(10.dp)).padding(10.dp),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    ) {
                                        Icon(symbol("lightbulb.fill"), null, tint = colors.gold, modifier = Modifier.size(16.dp))
                                        Text(tip, style = BridgeType.footnote.copy(fontWeight = FontWeight.Medium), color = colors.ink)
                                    }
                                }
                                if (shown == pages.lastIndex) {
                                    val accent = recommended.accent(colors)
                                    Row(
                                        Modifier
                                            .fillMaxWidth()
                                            .pressable { advance() }
                                            .background(accent.copy(alpha = 0.08f), rounded(14.dp))
                                            .border(1.2.dp, accent.copy(alpha = 0.35f), rounded(14.dp))
                                            .padding(12.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                                    ) {
                                        IconBadge(recommended.icon, accent, size = 40.dp, alpha = 0.14f)
                                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                            Text("Recommended: ${recommended.name}", style = BridgeType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
                                            Text(recommended.tagline, style = BridgeType.caption, color = colors.inkSecondary)
                                        }
                                        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(16.dp))
                                    }
                                }
                            }
                        }
                    }
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                Modifier
                                    .size(56.dp)
                                    .semantics { contentDescription = "Previous page" }
                                    .graphicsLayer { alpha = if (isFirst) 0.45f else 1f }
                                    .background(colors.card, rounded(BridgeGeo.ctaCorner))
                                    .border(1.dp, colors.rule, rounded(BridgeGeo.ctaCorner))
                                    .pressable(enabled = !isFirst) { goBack() },
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(symbol("chevron.left"), null, tint = if (isFirst) colors.inkTertiary else colors.jade, modifier = Modifier.size(24.dp))
                            }
                            PrimaryCTA(if (isLast) "Take your seat" else "Continue", Modifier.weight(1f).testTag("primer-continue")) { advance() }
                        }
                        if (onSkip != null) {
                            QuietButton("Skip for now") {
                                graph.defaults.putString(RECOMMENDED_ROOM_HINT, recommended.id)
                                onSkip()
                            }
                        }
                    }
                }
            }
            ConfettiBurst(confetti, origin = Offset(0.5f, 0.35f))
        }
    }
}

@Composable
fun Dots(count: Int, index: Int, modifier: Modifier = Modifier) {
    val colors = BridgeUI.colors
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        repeat(count) { dot ->
            val active = dot == index
            Box(Modifier.width(if (active) 20.dp else 7.dp).height(7.dp).background(if (active) colors.jade else colors.jade.copy(alpha = 0.22f), CircleShape))
        }
    }
}
