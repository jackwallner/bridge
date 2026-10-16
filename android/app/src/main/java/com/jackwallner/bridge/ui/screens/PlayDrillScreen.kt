package com.jackwallner.bridge.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.scaleIn
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.model.PlayScenario
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.BridgeCardView
import com.jackwallner.bridge.ui.components.DrillProgress
import com.jackwallner.bridge.ui.components.DrillStage
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.nav.LocalNavigator
import com.jackwallner.bridge.ui.theme.BridgeScreen
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.CenteringScroll
import com.jackwallner.bridge.ui.theme.PrimaryCTA
import com.jackwallner.bridge.ui.theme.Readable
import com.jackwallner.bridge.ui.theme.rounded
import com.jackwallner.bridge.ui.theme.screenPadding
import com.jackwallner.bridge.ui.theme.themedCard

/** iOS `PlayDrillView`: read the table situation, tap the card you would play. */
@Composable
fun PlayDrillScreen(drill: Drill, scenarios: List<PlayScenario>) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = BridgeUI.colors
    var index by rememberSaveable { mutableIntStateOf(0) }
    var selection by rememberSaveable { mutableStateOf<Int?>(null) }
    var score by rememberSaveable { mutableIntStateOf(0) }
    var finished by rememberSaveable { mutableStateOf(false) }
    var confetti by remember { mutableIntStateOf(0) }

    if (finished) {
        DrillCompleteScreen(drill, score, scenarios.size) { navigator.pop() }
        return
    }
    val scenario = scenarios[index]
    val answered = selection != null

    fun select(cardIndex: Int) {
        if (answered) return
        selection = cardIndex
        val correct = cardIndex == scenario.answerIndex
        graph.recordAnswer(scenario.id, DrillLibrary.roomID(drill.id), correct)
        if (correct) {
            score += 1
            confetti += 1
            celebrateCorrect()
        } else {
            consoleMiss()
        }
    }

    BridgeScreen(drill.title, onBack = { navigator.pop() }) {
        DrillStage(confetti) {
            Readable(Modifier.fillMaxSize()) {
                Column(Modifier.fillMaxSize().screenPadding(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    DrillProgress(index, scenarios.size)
                    CenteringScroll(Modifier.weight(1f)) {
                        Column(
                            Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(20.dp),
                        ) {
                            Text(
                                scenario.situation,
                                style = BridgeType.display(21.sp, FontWeight.SemiBold),
                                color = colors.ink,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(top = 8.dp).testTag("play-situation"),
                            )
                            Text("Tap the card you would play", style = BridgeType.subheadline, color = colors.inkSecondary)
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                scenario.cards.forEachIndexed { cardIndex, card ->
                                    val border = when {
                                        !answered -> Color.Transparent
                                        cardIndex == scenario.answerIndex -> colors.jade
                                        cardIndex == selection -> colors.coral
                                        else -> Color.Transparent
                                    }
                                    Box {
                                        BridgeCardView(
                                            card,
                                            54.dp,
                                            tag = "play-card-$cardIndex",
                                            onClick = if (answered) null else ({ select(cardIndex) }),
                                        )
                                        Box(Modifier.size(54.dp, 54.dp * 1.38f).border(3.dp, border, rounded(7.dp)))
                                    }
                                }
                            }
                            AnimatedVisibility(answered, enter = fadeIn() + scaleIn(initialScale = 0.96f)) {
                                PlayCoachCard(scenario, selection == scenario.answerIndex)
                            }
                        }
                    }
                    if (answered) {
                        PrimaryCTA(if (index + 1 < scenarios.size) "Next Play" else "Finish", Modifier.testTag("next")) {
                            if (index + 1 < scenarios.size) {
                                selection = null
                                index += 1
                            } else {
                                finished = true
                            }
                        }
                    } else {
                        Box(Modifier.fillMaxWidth().height(56.dp), contentAlignment = Alignment.Center) {
                            Text("Play ${index + 1} of ${scenarios.size}", style = BridgeType.caption, color = colors.inkTertiary)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PlayCoachCard(scenario: PlayScenario, right: Boolean) {
    val colors = BridgeUI.colors
    Column(
        Modifier.fillMaxWidth().wrapContentHeight().themedCard(16.dp).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(
                symbol(if (right) "checkmark.circle.fill" else "lightbulb.fill"),
                null,
                tint = if (right) colors.jade else colors.gold,
                modifier = Modifier.size(20.dp),
            )
            Text(
                if (right) "Right play" else "Coach's play",
                style = BridgeType.headline,
                color = if (right) colors.jade else colors.gold,
                modifier = Modifier.testTag("coach-headline"),
            )
        }
        Text(scenario.reasoning, style = BridgeType.subheadline, color = colors.ink)
        Text(scenario.tip, style = BridgeType.footnote.copy(fontWeight = FontWeight.Medium), color = colors.inkSecondary)
    }
}
