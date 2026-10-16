package com.jackwallner.bridge.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.content.SessionBuilder
import com.jackwallner.bridge.data.Membership
import com.jackwallner.bridge.model.Room
import com.jackwallner.bridge.ui.LocalAppActions
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.nav.LocalNavigator
import com.jackwallner.bridge.ui.nav.PracticeMode
import com.jackwallner.bridge.ui.nav.Route
import com.jackwallner.bridge.ui.nav.SessionPurpose
import com.jackwallner.bridge.ui.theme.BarIconButton
import com.jackwallner.bridge.ui.theme.Eyebrow
import com.jackwallner.bridge.ui.theme.IconBadge
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeColors
import com.jackwallner.bridge.ui.theme.BridgeGeo
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.PlusBadge
import com.jackwallner.bridge.ui.theme.jadeGradient
import com.jackwallner.bridge.ui.theme.navBarPadding
import com.jackwallner.bridge.ui.theme.pressable
import com.jackwallner.bridge.ui.theme.rounded
import com.jackwallner.bridge.ui.theme.themedCard
import kotlinx.coroutines.delay

/** Room identity: each room keeps its own accent so the doors feel like places. */
fun Room.accent(colors: BridgeColors): Color = when (id) {
    "card-room" -> colors.jade
    "auction-room" -> colors.coral
    "declarer-room" -> colors.plum
    else -> colors.gold
}

/**
 * Home is the lobby: Get Started, the training modes, then the rooms as
 * doors. Everything that is not a room earns its space or leaves.
 */
@Composable
fun HomeScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val colors = BridgeUI.colors
    val progress = graph.progress
    val isPro = graph.subscriptions.isPro
    val scroll = rememberScrollState()
    var highlightedRoom by remember { mutableStateOf<String?>(null) }
    val roomOffsets = remember { mutableMapOf<String, Int>() }

    // The one-shot hint the primer leaves: scroll to and briefly ring the recommended room.
    LaunchedEffect(navigator.popCount) {
        val hint = graph.defaults.getString(RECOMMENDED_ROOM_HINT).orEmpty()
        if (hint.isEmpty()) return@LaunchedEffect
        graph.defaults.remove(RECOMMENDED_ROOM_HINT)
        if (DrillLibrary.room(hint) == null) return@LaunchedEffect
        delay(400)
        roomOffsets[hint]?.let { scroll.animateScrollTo((it - 200).coerceAtLeast(0)) }
        highlightedRoom = hint
        delay(2_200)
        highlightedRoom = null
    }

    Column(Modifier.fillMaxSize().background(colors.background)) {
        Row(
            Modifier.fillMaxWidth().statusBarsPadding().height(52.dp).padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Spacer(Modifier.weight(1f))
            BarIconButton("gearshape", "Settings") { navigator.push(Route.Settings) }
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(scroll).padding(horizontal = 16.dp).padding(navBarPadding()),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Header(progress.streakCount, progress.totalSessions) { navigator.push(Route.Stats) }
            if (progress.quickSessionCompletedToday()) GetStartedDoneCard() else GetStartedCard {
                val items = SessionBuilder.quickSession(seen = progress.seenItems, missed = progress.missedItems, includePro = isPro)
                navigator.push(Route.Session(items, SessionPurpose.Quick(isDaily = true)))
            }
            val skillLevel = graph.defaults.getString(SKILL_LEVEL).orEmpty()
            if (skillLevel == "new" && !graph.defaults.getBoolean(HAS_READ_PRIMER)) {
                HowToPlayCard { navigator.push(Route.HowToPlay) }
            }
            TrainingSection(isPro, onLocked = { actions.openPaywall("bridge_home_sheet") })
            Row(Modifier.padding(top = 6.dp, start = 4.dp)) { Eyebrow("THE ROOMS") }
            DrillLibrary.rooms.forEach { room ->
                // Count only the drills this player can open, so a free player's ring can close.
                val open = room.drills.filter { !room.isLocked(it, isPro) }
                val done = open.count { progress.completions(it.id) > 0 }
                Box(Modifier.onGloballyPositioned { roomOffsets[room.id] = it.positionInParent().y.toInt() }) {
                    RoomCard(
                        room = room,
                        locked = !room.isFree && !isPro,
                        done = done,
                        total = open.size,
                        highlighted = highlightedRoom == room.id,
                    ) { navigator.push(Route.Room(room.id)) }
                }
            }
            if (!isPro) UpgradeCard { actions.openPaywall("bridge_home_sheet") }
            Text(
                "Bridge Trainer uses a beginner Standard American framework. Partnership agreements vary, so confirm conventions with your partner.",
                style = BridgeType.caption2,
                color = colors.inkTertiary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
            )
        }
    }
}

const val SKILL_LEVEL = "bridge.skillLevel"
const val HAS_READ_PRIMER = "bridge.hasReadPrimer"
const val RECOMMENDED_ROOM_HINT = "bridge.recommendedRoomHint"

@Composable
private fun Header(streak: Int, sessions: Int, onStats: () -> Unit) {
    val colors = BridgeUI.colors
    Row(Modifier.fillMaxWidth().padding(top = 2.dp), verticalAlignment = Alignment.Top) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Bridge Trainer", style = BridgeType.display(32.sp), color = colors.ink)
            Text("Your seat at the table.", style = BridgeType.subheadline, color = colors.inkSecondary)
        }
        Spacer(Modifier.width(8.dp))
        // The chips are the honest summary of practice, so they open the full breakdown.
        Row(
            Modifier.padding(top = 4.dp).testTag("stats-chips").pressable(label = "Opens your progress breakdown", onClick = onStats),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            StatChip(streak, "flame.fill", colors.coral, "$streak day streak")
            StatChip(sessions, "checkmark.seal.fill", colors.jade, "$sessions drills done")
        }
    }
}

@Composable
private fun StatChip(value: Int, icon: String, color: Color, label: String) {
    Row(
        Modifier.background(color.copy(alpha = 0.12f), CircleShape).padding(horizontal = 9.dp, vertical = 6.dp).semantics(mergeDescendants = true) {
            contentDescription = label
        },
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(symbol(icon), null, tint = color, modifier = Modifier.size(14.dp))
        Text("$value", style = BridgeType.subheadline.copy(fontWeight = FontWeight.Bold), color = BridgeUI.colors.ink)
    }
}

@Composable
private fun GetStartedCard(onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("get-started")
            .pressable(onClick = onClick)
            .background(jadeGradient(), rounded(BridgeGeo.cardCorner))
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Get Started", style = BridgeType.display(24.sp), color = Color.White)
            Text("A five-minute mix of what you need next", style = BridgeType.subheadline, color = Color.White.copy(alpha = 0.85f))
        }
        Icon(symbol("play.circle.fill"), null, tint = Color.White, modifier = Modifier.size(44.dp))
    }
}

/** Today's Get Started is spent; the card rests until tomorrow. */
@Composable
private fun GetStartedDoneCard() {
    val colors = BridgeUI.colors
    Row(
        Modifier.fillMaxWidth().themedCard().padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        IconBadge("checkmark.circle.fill", colors.jade, size = 44.dp, iconSize = 28.dp, alpha = 0.12f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text("Today's session is done", style = BridgeType.headline, color = colors.ink)
            Text("A fresh mix lands tomorrow. Keep going in any room below.", style = BridgeType.subheadline, color = colors.inkSecondary)
        }
    }
}

@Composable
private fun HowToPlayCard(onClick: () -> Unit) {
    val colors = BridgeUI.colors
    Row(
        Modifier.fillMaxWidth().pressable(onClick = onClick).themedCard(16.dp).padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("book.fill", colors.gold, corner = 12.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("How to Play", style = BridgeType.headline, color = colors.ink)
            Text("New here? Start with the five-minute primer", style = BridgeType.caption, color = colors.inkSecondary)
        }
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
    }
}

/** The cross-cutting practice modes in one scrolling row of compact cards. */
@Composable
private fun TrainingSection(isPro: Boolean, onLocked: () -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = BridgeUI.colors
    val records = graph.records
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp)) { Eyebrow("TRAINING") }
        Row(
            Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 4.dp, vertical = 2.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            TrainingTile("Endless\nPractice", "infinity", colors.jade, null, locked = !isPro, tag = "tile-endless") {
                if (isPro) navigator.push(Route.EndlessPicker) else onLocked()
            }
            val minute = graph.minutes.result(graph.clock.today())
            TrainingTile(
                "Bridge\nMinute", "calendar.badge.clock", colors.coral,
                minute?.let { "${it.score}/${it.total} today" } ?: "Daily", locked = !isPro, tag = "tile-minute",
            ) { if (isPro) navigator.push(Route.BridgeMinute) else onLocked() }
            TrainingTile(
                "Game Night\nPrep", "person.2.fill", colors.plum,
                if (graph.settings.gameNightReminderEnabled) graph.settings.gameNightDay.displayName else "Weekly",
                locked = !isPro, tag = "tile-game-night",
            ) { if (isPro) navigator.push(Route.GameNightPrep) else onLocked() }
            TrainingTile(
                "Timed\nChallenge", "timer", colors.coral,
                if (records.bestChallengeScore > 0) "Best ${records.bestChallengeScore}" else null, locked = !isPro, tag = "tile-timed",
            ) { if (isPro) navigator.push(Route.Practice(PracticeMode.Timed)) else onLocked() }
            // Only offered when there is something to fix: an empty review is a dead end.
            val due = records.dueCount
            if (due > 0) {
                TrainingTile("Fix My\nMistakes", "arrow.trianglehead.counterclockwise", colors.plum, "$due due", locked = !isPro, tag = "tile-review") {
                    if (!isPro) {
                        onLocked()
                    } else {
                        val items = SessionBuilder.reviewSession(records.reviewQueue(), isPro)
                        navigator.push(Route.Practice(PracticeMode.Review, items))
                    }
                }
            }
        }
    }
}

@Composable
private fun TrainingTile(title: String, icon: String, color: Color, badge: String?, locked: Boolean, tag: String, onClick: () -> Unit) {
    val colors = BridgeUI.colors
    Column(
        Modifier
            .width(128.dp)
            .height(118.dp)
            .testTag(tag)
            .pressable(label = if (locked) "Included with ${Membership.NAME}" else null, onClick = onClick)
            .themedCard(16.dp)
            .padding(12.dp),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Icon(symbol(icon), null, tint = color, modifier = Modifier.size(24.dp))
            Spacer(Modifier.weight(1f))
            if (locked) Icon(symbol("lock.fill"), null, tint = colors.gold, modifier = Modifier.size(12.dp))
        }
        Spacer(Modifier.weight(1f))
        Text(title, style = BridgeType.subheadline.copy(fontWeight = FontWeight.Bold), color = colors.ink)
        Text(
            badge ?: if (locked) Membership.NAME else " ",
            style = BridgeType.caption2.copy(fontWeight = FontWeight.SemiBold),
            color = if (badge != null) color else colors.gold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun RoomCard(room: Room, locked: Boolean, done: Int, total: Int, highlighted: Boolean, onClick: () -> Unit) {
    val colors = BridgeUI.colors
    val accent = room.accent(colors)
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("room-${room.id}")
            .pressable(
                label = if (locked) "Locked. $total drills, included with ${Membership.NAME}" else "$done of $total drills done",
                onClick = onClick,
            )
            .themedCard()
            .border(2.5.dp, if (highlighted) accent else Color.Transparent, rounded(BridgeGeo.cardCorner))
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        IconBadge(room.icon, accent, size = 48.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(room.name, style = BridgeType.headline, color = colors.ink)
                if (locked) PlusBadge()
            }
            Text(room.tagline, style = BridgeType.subheadline, color = colors.inkSecondary, maxLines = 2)
        }
        if (locked) Icon(symbol("lock.fill"), null, tint = colors.gold, modifier = Modifier.size(16.dp))
        else ProgressRing(done, total, accent)
    }
}

/** Room completion at a glance: a ring that fills as drills get done, then a check. */
@Composable
fun ProgressRing(done: Int, total: Int, color: Color) {
    val colors = BridgeUI.colors
    val target = if (total > 0) done.toFloat() / total else 0f
    val fraction by animateFloatAsState(target, spring(dampingRatio = 0.8f, stiffness = 200f), label = "ring")
    Box(Modifier.size(32.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val stroke = 3.dp.toPx()
            val inset = stroke / 2
            val arcSize = Size(size.width - stroke, size.height - stroke)
            drawArc(color.copy(alpha = 0.18f), 0f, 360f, false, Offset(inset, inset), arcSize, style = Stroke(stroke))
            if (fraction > 0f) {
                drawArc(color, -90f, 360f * fraction, false, Offset(inset, inset), arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
            }
        }
        if (done == total && total > 0) {
            Icon(symbol("checkmark"), null, tint = color, modifier = Modifier.size(12.dp))
        } else {
            Text("$done/$total", style = BridgeType.caption2.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold), color = colors.inkSecondary)
        }
    }
}

@Composable
private fun UpgradeCard(onClick: () -> Unit) {
    val colors = BridgeUI.colors
    val locked = DrillLibrary.rooms.sumOf { it.plusDrillCount }
    Row(
        Modifier
            .fillMaxWidth()
            .padding(top = 2.dp)
            .pressable(onClick = onClick)
            .themedCard(16.dp)
            .border(1.dp, colors.gold.copy(alpha = 0.35f), rounded(16.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge("sparkles", colors.gold, alpha = 0.14f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("Get ${Membership.NAME}", style = BridgeType.headline, color = colors.ink)
            Text(
                "Bridge Minute, Game Night Prep, endless modes, and $locked more drills across every room",
                style = BridgeType.caption,
                color = colors.inkSecondary,
            )
        }
        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
    }
}
