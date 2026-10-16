package com.jackwallner.bridge.ui.components

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.ui.theme.BridgeUI
import com.jackwallner.bridge.ui.theme.pressable

/**
 * A compact, readable playing-card face (iOS `BridgeCardView`): ivory face,
 * serif rank over the suit. Sizes are in dp, not sp: a card is a picture of an
 * object and must not grow with the font scale.
 */
@Composable
fun BridgeCardView(
    card: BridgeCard,
    width: Dp = 44.dp,
    modifier: Modifier = Modifier,
    tag: String? = null,
    selected: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    val colors = BridgeUI.colors
    val height = width * 1.38f
    val shape = RoundedCornerShape(width * 0.13f)
    var base = modifier
        .size(width, height)
        // A drawn drop shadow rather than an elevation one: elevation shadows on many
        // small, re-laid-out cards render as grey boxes on some GPUs.
        .drawBehind {
            val radius = CornerRadius(width.toPx() * 0.13f)
            drawRoundRect(Color.Black.copy(alpha = 0.14f), topLeft = Offset(0f, 2.dp.toPx()), size = size, cornerRadius = radius)
            drawRoundRect(Color.Black.copy(alpha = 0.08f), topLeft = Offset(0f, 1.dp.toPx()), size = size, cornerRadius = radius)
        }
        .background(colors.tileIvory, shape)
        .border(1.dp, colors.tileEdge, shape)
        .semantics {
            contentDescription = card.spokenName
            this.selected = selected
            if (onClick != null) role = Role.Button
        }
    if (tag != null) base = base.testTag(tag)
    if (onClick != null) base = base.pressable(onClick = onClick)
    Box(base, contentAlignment = Alignment.Center) {
        val color = if (card.suit.isRed) colors.cardRed else colors.cardBlack
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy((-1).dp)) {
            Text(card.rank.raw, style = glyph(width * 0.40f, FontWeight.Bold, serif = true), color = color)
            Text(card.suit.symbol, style = glyph(width * 0.42f, FontWeight.SemiBold), color = color)
        }
    }
}

@Composable
private fun glyph(size: Dp, weight: FontWeight, serif: Boolean = false): TextStyle {
    val sp = with(LocalDensity.current) { size.toSp() }
    return TextStyle(
        fontFamily = if (serif) FontFamily.Serif else FontFamily.Default,
        fontWeight = weight,
        fontSize = sp,
        lineHeight = sp,
        lineHeightStyle = LineHeightStyle(LineHeightStyle.Alignment.Center, LineHeightStyle.Trim.Both),
    )
}

/** A wrapping row of cards, seven to a row like iOS `BridgeHandView`. */
@Composable
fun BridgeHandView(
    cards: List<BridgeCard>,
    modifier: Modifier = Modifier,
    cardWidth: Dp = 44.dp,
    highlighted: Set<Int> = emptySet(),
    onTap: ((Int) -> Unit)? = null,
) {
    val rows = cards.withIndex().chunked(7)
    val gold = BridgeUI.colors.gold
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        rows.forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                row.forEach { (index, card) ->
                    val selected = index in highlighted
                    val lift by animateDpAsState(if (selected) (-8).dp else 0.dp, spring(dampingRatio = 0.7f, stiffness = 500f), label = "lift")
                    Box(Modifier.offset(y = lift)) {
                        BridgeCardView(
                            card,
                            cardWidth,
                            tag = "hand-card-$index",
                            selected = selected,
                            onClick = onTap?.let { tap -> { tap(index) } },
                        )
                        if (selected) {
                            Box(Modifier.size(cardWidth, cardWidth * 1.38f).border(3.dp, gold, RoundedCornerShape(cardWidth * 0.13f)))
                        }
                    }
                }
            }
        }
    }
}
