package com.jackwallner.bridge.ui.theme

import android.view.WindowManager
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider
import com.jackwallner.bridge.data.Membership
import com.jackwallner.bridge.ui.components.symbol

fun rounded(radius: Dp): Shape = RoundedCornerShape(radius)

/** Press-scale feedback for card-shaped buttons, like iOS `PressableCardStyle`. */
fun Modifier.pressable(
    enabled: Boolean = true,
    role: Role = Role.Button,
    label: String? = null,
    haptic: Boolean = false,
    onClick: () -> Unit,
): Modifier = composed {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.975f else 1f, spring(dampingRatio = 0.7f, stiffness = 700f), label = "press")
    this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
        }
        .clickable(interactionSource = source, indication = null, enabled = enabled, role = role, onClickLabel = label) {
            if (haptic) Haptics.light()
            onClick()
        }
}

/** Standard raised card: warm surface, hairline, soft shadow. */
@Composable
fun Modifier.themedCard(corner: Dp = BridgeGeo.cardCorner): Modifier {
    val colors = BridgeUI.colors
    val shape = rounded(corner)
    return this
        .shadow(if (colors.isDark) 2.dp else 5.dp, shape, ambientColor = Color.Black.copy(alpha = 0.10f), spotColor = Color.Black.copy(alpha = 0.10f))
        .background(colors.card, shape)
        .border(1.dp, colors.rule, shape)
}

/** A tinted rounded background, the SwiftUI `.background(color.opacity(x), in: shape)`. */
fun Modifier.tinted(color: Color, alpha: Float, corner: Dp): Modifier = background(color.copy(alpha = alpha), rounded(corner))

/** The full-width primary button every screen ends with. */
@Composable
fun PrimaryCTA(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = BridgeUI.colors.jade,
    enabled: Boolean = true,
    loading: Boolean = false,
    dimmed: Boolean = !enabled,
    icon: ImageVector? = null,
    onClick: () -> Unit,
) {
    val shape = rounded(BridgeGeo.ctaCorner)
    Box(
        modifier
            .fillMaxWidth()
            .height(BridgeGeo.ctaHeight)
            .graphicsLayer { alpha = if (dimmed) 0.5f else 1f }
            .shadow(6.dp, shape, ambientColor = color.copy(alpha = 0.35f), spotColor = color.copy(alpha = 0.35f))
            .background(color, shape)
            .pressable(enabled = enabled && !loading, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (loading) {
            CircularProgressIndicator(color = Color.White, strokeWidth = 2.5.dp, modifier = Modifier.size(22.dp))
        } else {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (icon != null) Icon(icon, null, tint = Color.White, modifier = Modifier.size(20.dp))
                Text(text, style = BridgeType.headline, color = Color.White, textAlign = TextAlign.Center)
            }
        }
    }
}

/** A quiet text button under a primary CTA ("Skip", "Maybe later", "Done"). */
@Composable
fun QuietButton(text: String, modifier: Modifier = Modifier, color: Color = BridgeUI.colors.inkSecondary, enabled: Boolean = true, onClick: () -> Unit) {
    Box(
        modifier.heightIn(min = 44.dp).pressable(enabled = enabled, onClick = onClick).padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, style = BridgeType.subheadline.copy(fontWeight = FontWeight.Medium), color = color, textAlign = TextAlign.Center)
    }
}

/** The gold pill that marks anything behind the membership. */
@Composable
fun PlusBadge(text: String = Membership.NAME) {
    val gold = BridgeUI.colors.gold
    Text(
        text,
        style = BridgeType.caption.copy(fontWeight = FontWeight.ExtraBold),
        color = gold,
        modifier = Modifier.background(gold.copy(alpha = 0.15f), CircleShape).padding(horizontal = 8.dp, vertical = 3.dp),
    )
}

/** An icon on a tinted circle or rounded square, the recurring leading glyph. */
@Composable
fun IconBadge(
    name: String,
    color: Color,
    size: Dp = 38.dp,
    iconSize: Dp = 20.dp,
    corner: Dp? = null,
    alpha: Float = 0.13f,
) {
    val shape = corner?.let { rounded(it) } ?: CircleShape
    Box(Modifier.size(size).background(color.copy(alpha = alpha), shape), contentAlignment = Alignment.Center) {
        Icon(symbol(name), null, tint = color, modifier = Modifier.size(iconSize))
    }
}

@Composable
fun Eyebrow(text: String, color: Color = BridgeUI.colors.inkSecondary, modifier: Modifier = Modifier) {
    Text(text, style = BridgeType.eyebrow, color = color, modifier = modifier.semantics { heading() })
}

/**
 * A screen: the inline iOS-style bar (back chevron, centred title, optional
 * trailing actions) on the cream background, content below.
 */
@Composable
fun BridgeScreen(
    title: String,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
    backLabel: String = "Back",
    leading: (@Composable RowScope.() -> Unit)? = null,
    trailing: (@Composable RowScope.() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(modifier.fillMaxSize().background(BridgeUI.colors.background)) {
        BridgeBar(title, onBack, backLabel, leading, trailing)
        Column(Modifier.fillMaxWidth().weight(1f), content = content)
    }
}

@Composable
fun BridgeBar(
    title: String,
    onBack: (() -> Unit)?,
    backLabel: String = "Back",
    leading: (@Composable RowScope.() -> Unit)? = null,
    trailing: (@Composable RowScope.() -> Unit)? = null,
    inSheet: Boolean = false,
) {
    val colors = BridgeUI.colors
    Column(Modifier.fillMaxWidth().background(colors.background)) {
        if (!inSheet) Spacer(Modifier.statusBarsPadding())
        Box(Modifier.fillMaxWidth().height(52.dp).padding(horizontal = 8.dp)) {
            Row(Modifier.align(Alignment.CenterStart), verticalAlignment = Alignment.CenterVertically) {
                if (onBack != null) {
                    Box(
                        Modifier.size(44.dp).semantics { contentDescription = backLabel }.pressable(onClick = onBack),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(symbol("chevron.left"), null, tint = colors.jade, modifier = Modifier.size(30.dp))
                    }
                }
                leading?.invoke(this)
            }
            Text(
                title,
                style = BridgeType.headline,
                color = colors.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
                modifier = Modifier.align(Alignment.Center).widthIn(max = 240.dp).semantics { heading() },
            )
            Row(Modifier.align(Alignment.CenterEnd), verticalAlignment = Alignment.CenterVertically) { trailing?.invoke(this) }
        }
    }
}

/** A toolbar text action ("Done", "Close", "Finish"). */
@Composable
fun BarTextButton(text: String, color: Color = BridgeUI.colors.jade, bold: Boolean = false, onClick: () -> Unit) {
    Box(Modifier.heightIn(min = 44.dp).pressable(onClick = onClick).padding(horizontal = 10.dp), contentAlignment = Alignment.Center) {
        Text(text, style = if (bold) BridgeType.headline else BridgeType.body, color = color)
    }
}

@Composable
fun BarIconButton(name: String, label: String, color: Color = BridgeUI.colors.inkSecondary, onClick: () -> Unit) {
    Box(
        Modifier.size(44.dp).semantics { contentDescription = label }.pressable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(symbol(name), null, tint = color, modifier = Modifier.size(24.dp))
    }
}

/**
 * Scrolls like a plain column, but centres content shorter than the
 * viewport, the port of iOS `CenteringScrollView`.
 */
@Composable
fun CenteringScroll(
    modifier: Modifier = Modifier,
    state: ScrollState = rememberScrollState(),
    content: @Composable ColumnScope.() -> Unit,
) {
    BoxWithConstraints(modifier) {
        val viewport = maxHeight
        Column(
            Modifier.fillMaxWidth().verticalScroll(state).heightIn(min = viewport),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            content = content,
        )
    }
}

/** Centred content capped at a readable width on tablets. */
@Composable
fun Readable(modifier: Modifier = Modifier, maxWidth: Dp = BridgeGeo.readableWidth, content: @Composable ColumnScope.() -> Unit) {
    Box(modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Column(Modifier.widthIn(max = maxWidth).fillMaxWidth(), content = content)
    }
}

/** Bottom padding so scrolling content clears the gesture bar. */
@Composable
fun navBarPadding(extra: Dp = 24.dp): PaddingValues =
    PaddingValues(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding() + extra)

/**
 * A page sheet: slides up over everything with its own bar. Back, the scrim,
 * or a swipe-down on the bar area dismisses it.
 */
@OptIn(androidx.compose.ui.ExperimentalComposeUiApi::class)
@Composable
fun BridgeSheet(visible: Boolean, onDismiss: () -> Unit, content: @Composable () -> Unit) {
    val state = remember { MutableTransitionState(false) }
    state.targetState = visible
    if (!state.currentState && !state.targetState && state.isIdle) return
    val dismiss = rememberUpdatedState(onDismiss)
    val colors = BridgeUI.colors
    Dialog(
        onDismissRequest = { dismiss.value() },
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        val view = LocalView.current
        LaunchedEffect(view) {
            (view.parent as? DialogWindowProvider)?.window?.let { window ->
                window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
                window.setWindowAnimations(0)
            }
        }
        Box(Modifier.fillMaxSize()) {
            AnimatedVisibility(state, enter = fadeIn(tween(250)), exit = fadeOut(tween(250))) {
                Box(
                    Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.35f)).clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) { dismiss.value() },
                )
            }
            AnimatedVisibility(
                state,
                enter = slideInVertically(tween(320)) { it },
                exit = slideOutVertically(tween(280)) { it },
                modifier = Modifier.fillMaxSize(),
            ) {
                BackHandler { dismiss.value() }
                val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding() + 10.dp
                Box(
                    Modifier
                        .fillMaxSize()
                        .padding(top = top)
                        .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                        .background(colors.background)
                        // A dialog is its own window, so it needs its own opt-in for test tags as resource ids.
                        .semantics { testTagsAsResourceId = true }
                        .imePadding(),
                ) { content() }
            }
        }
    }
}

/** A confirmation or message dialog in the app's palette. */
@Composable
fun BridgeAlert(
    title: String,
    message: String?,
    confirmTitle: String = "OK",
    onConfirm: () -> Unit,
    onDismiss: () -> Unit = onConfirm,
    dismissTitle: String? = null,
    destructive: Boolean = false,
) {
    val colors = BridgeUI.colors
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.card,
        titleContentColor = colors.ink,
        textContentColor = colors.inkSecondary,
        title = { Text(title, style = BridgeType.headline) },
        text = message?.let { { Text(it, style = BridgeType.subheadline) } },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(confirmTitle, style = BridgeType.headline, color = if (destructive) colors.crakRed else colors.jade)
            }
        },
        dismissButton = dismissTitle?.let {
            {
                TextButton(onClick = onDismiss) { Text(it, style = BridgeType.body, color = colors.inkSecondary) }
            }
        },
    )
}

/** The jade gradient behind the Get Started card. */
@Composable
fun jadeGradient(): Brush {
    val jade = BridgeUI.colors.jade
    return Brush.linearGradient(listOf(jade, jade.copy(alpha = 0.82f)))
}

/** A capsule progress bar on the well colour. */
@Composable
fun CapsuleBar(fraction: Float, color: Color, modifier: Modifier = Modifier, height: Dp = 8.dp) {
    val colors = BridgeUI.colors
    val animated by animateFloatAsState(fraction.coerceIn(0f, 1f), spring(dampingRatio = 0.8f, stiffness = 300f), label = "bar")
    Box(modifier.fillMaxWidth().height(height).clip(CircleShape).background(colors.well)) {
        if (animated > 0f) {
            Box(Modifier.fillMaxWidth(animated).height(height).clip(CircleShape).background(color))
        }
    }
}

/** Padding every screen body uses, including room for the gesture bar. */
@Composable
fun Modifier.screenPadding(): Modifier = padding(horizontal = 16.dp).navigationBarsPadding().padding(bottom = 12.dp)
