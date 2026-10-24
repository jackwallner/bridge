package com.jackwallner.bridge.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.bridge.content.DrillLibrary
import com.jackwallner.bridge.data.Membership
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.Room
import com.jackwallner.bridge.ui.LocalAppActions
import com.jackwallner.bridge.ui.LocalGraph
import com.jackwallner.bridge.ui.components.symbol
import com.jackwallner.bridge.ui.nav.LocalNavigator
import com.jackwallner.bridge.ui.nav.Route
import com.jackwallner.bridge.ui.theme.IconBadge
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.BridgeScreen
import com.jackwallner.bridge.ui.theme.BridgeType
import com.jackwallner.bridge.ui.theme.PlusBadge
import com.jackwallner.bridge.ui.theme.Readable
import com.jackwallner.bridge.ui.theme.navBarPadding
import com.jackwallner.bridge.ui.theme.pressable
import com.jackwallner.bridge.ui.theme.rounded
import com.jackwallner.bridge.ui.theme.themedCard

val DrillKind.symbolName: String
    get() = when (this) {
        is DrillKind.Flashcards -> "rectangle.stack.fill"
        is DrillKind.Quiz -> "questionmark.circle.fill"
        is DrillKind.HandMatch -> "square.grid.3x3.fill"
        is DrillKind.Play -> "arrow.left.arrow.right"
    }

/** One room, its drills. Free drills open; Bridge+ extra sets show the lock and route to the paywall. */
@Composable
fun RoomScreen(roomId: String) {
    val room = DrillLibrary.room(roomId) ?: return
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val colors = BridgeUI.colors
    val isPro = graph.subscriptions.isPro
    val roomLocked = !room.isFree && !isPro
    val lockedCount = room.drills.count { room.isLocked(it, isPro) }
    val accent = room.accent(colors)

    BridgeScreen(room.name, onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(
                Modifier.padding(horizontal = 16.dp).padding(navBarPadding()),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Column(
                    Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 2.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    IconBadge(room.icon, accent, size = 66.dp, iconSize = 30.dp, alpha = 0.12f)
                    Text(room.name, style = BridgeType.display(28.sp), color = colors.ink, textAlign = TextAlign.Center)
                    Text(room.tagline, style = BridgeType.subheadline, color = colors.inkSecondary, textAlign = TextAlign.Center)
                    if (roomLocked) {
                        Text(
                            "Look around. Every drill here opens with ${Membership.NAME}.",
                            style = BridgeType.caption.copy(fontWeight = FontWeight.Medium),
                            color = colors.gold,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
                room.drills.forEach { drill ->
                    val locked = room.isLocked(drill, isPro)
                    DrillRow(room, drill, locked, done = graph.progress.completions(drill.id) > 0) {
                        if (locked) actions.openPaywall("bridge_room_sheet", Route.Drill(room.id, drill.id))
                        else navigator.push(Route.Drill(room.id, drill.id))
                    }
                }
                if (lockedCount > 0) RoomUpsell(lockedCount) { actions.openPaywall("bridge_room_sheet") }
            }
        }
    }
}

@Composable
private fun DrillRow(room: Room, drill: Drill, locked: Boolean, done: Boolean, onClick: () -> Unit) {
    val colors = BridgeUI.colors
    val accent = room.accent(colors)
    Row(
        Modifier.fillMaxWidth().testTag("drill-${drill.id}").pressable(onClick = onClick).themedCard(16.dp).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        IconBadge(
            drill.kind.symbolName,
            if (locked) accent.copy(alpha = 0.55f) else accent,
            size = 42.dp,
            iconSize = 22.dp,
            corner = 12.dp,
            alpha = if (locked) 0.08f else 0.12f,
        )
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(drill.title, style = BridgeType.headline, color = colors.ink, modifier = Modifier.weight(1f, fill = false))
                if (locked) PlusBadge()
            }
            Text(drill.subtitle, style = BridgeType.subheadline, color = colors.inkSecondary, maxLines = 2)
            Text("${drill.kind.itemCount} ${drill.kind.unitName}", style = BridgeType.caption, color = colors.inkTertiary)
        }
        when {
            locked -> Icon(symbol("lock.fill"), null, tint = colors.gold, modifier = Modifier.size(16.dp))
            done -> Icon(symbol("checkmark.circle.fill"), "Done", tint = accent, modifier = Modifier.size(22.dp))
            else -> Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
        }
    }
}

/** Says exactly what the money buys in this room: same drills, more reps. */
@Composable
private fun RoomUpsell(lockedCount: Int, onClick: () -> Unit) {
    val colors = BridgeUI.colors
    Column(
        Modifier
            .fillMaxWidth()
            .padding(top = 4.dp)
            .pressable(onClick = onClick)
            .background(colors.gold.copy(alpha = 0.08f), rounded(16.dp))
            .border(1.dp, colors.gold.copy(alpha = 0.35f), rounded(16.dp))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(symbol("sparkles"), null, tint = colors.gold, modifier = Modifier.size(18.dp))
            Text(
                "$lockedCount more ${if (lockedCount == 1) "drill" else "drills"} in this room",
                style = BridgeType.subheadline.copy(fontWeight = FontWeight.SemiBold),
                color = colors.ink,
            )
            Spacer(Modifier.weight(1f))
        }
        Text(
            "${Membership.NAME} unlocks the extra sets here and in every other room, the Master Tables, Bridge Minute, Game Night Prep, and Endless Practice. Everything you already have stays free.",
            style = BridgeType.caption,
            color = colors.inkSecondary,
        )
    }
}

/** Routes a drill to the screen for its kind. */
@Composable
fun DrillScreen(roomId: String, drillId: String) {
    val room = DrillLibrary.room(roomId) ?: return
    val drill = room.drills.firstOrNull { it.id == drillId } ?: return
    when (val kind = drill.kind) {
        is DrillKind.Flashcards -> FlashcardDrillScreen(drill, kind.cards, room.accent(BridgeUI.colors))
        is DrillKind.Quiz -> QuizDrillScreen(drill, kind.questions)
        is DrillKind.HandMatch -> HandMatchDrillScreen(drill, kind.questions)
        is DrillKind.Play -> PlayDrillScreen(drill, kind.scenarios)
    }
}
