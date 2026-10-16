package com.jackwallner.bridge.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.jackwallner.bridge.ui.theme.BridgeUI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.sin

/**
 * A one-shot confetti burst: bump [trigger] to fire. Pieces launch along a
 * wide upward fan from across [source] (or [origin] when there is none),
 * decelerate through air drag toward a slow fall, sway, and flip end over end.
 */
@Composable
fun ConfettiBurst(
    trigger: Int,
    modifier: Modifier = Modifier,
    origin: Offset = Offset(0.5f, 0.35f),
    particleCount: Int = 26,
    source: Rect? = null,
) {
    val colors = BridgeUI.colors
    val palette = listOf(colors.jade, colors.coral, colors.gold, colors.plum, colors.bamGreen, colors.tileIvory)
    var elapsed by remember { mutableFloatStateOf(-1f) }
    var launch by remember { mutableStateOf<Rect?>(null) }
    LaunchedEffect(trigger) {
        if (trigger <= 0) return@LaunchedEffect
        launch = source
        val start = withFrameNanos { it }
        while (true) {
            val now = withFrameNanos { it }
            elapsed = (now - start) / 1_000_000_000f
            if (elapsed >= DURATION) break
        }
        elapsed = -1f
    }
    if (elapsed < 0f) return
    Canvas(modifier.fillMaxSize()) {
        val t = elapsed.toDouble()
        var random = SeededRandom((trigger * 7919L + 13).toULong())
        val k = 1.9
        val g = 1100.0
        val decay = (1 - exp(-k * t)) / k
        val unit = density
        for (index in 0 until particleCount) {
            val rect = launch
            val start = if (rect != null && rect.width > 1f) {
                val spread = (index + random.next(0.15, 0.85)) / particleCount
                Offset(rect.left + rect.width * spread.toFloat(), rect.center.y - rect.height * 0.25f)
            } else {
                Offset(origin.x * size.width, origin.y * size.height)
            }
            val side = if (index % 2 == 0) 1.0 else -1.0
            val angle = -Math.PI / 2 + side * random.next(0.06, 1.15)
            val speed = random.next(340.0, 760.0) * unit
            val vx = cos(angle) * speed
            val vy = sin(angle) * speed
            var x = start.x + (vx * decay).toFloat()
            val y = start.y + ((vy + g * unit / k) * decay - g * unit * t / k).toFloat()
            val swayPhase = random.next(0.0, 6.28)
            val swaySpeed = random.next(3.5, 7.0)
            val swayWidth = random.next(4.0, 14.0) * unit
            val spinSpeed = random.next(4.0, 11.0) * if (index % 3 == 0) -1 else 1
            val tiltBase = random.next(-0.5, 0.5)
            val isRibbon = index % 5 == 0
            val w = (if (isRibbon) random.next(3.0, 5.0) else random.next(6.0, 11.0)) * unit
            val h = (if (isRibbon) random.next(14.0, 22.0) else random.next(6.0, 11.0)) * unit
            if (y > size.height + 30 * unit || y < -60 * unit) continue
            x += (sin(t * swaySpeed + swayPhase) * swayWidth).toFloat()
            val life = t / DURATION
            val fade = if (life < 0.72) 1.0 else maxOf(0.0, 1 - (life - 0.72) / 0.28)
            val spin = spinSpeed * t + swayPhase
            val tilt = tiltBase + spin * 0.12
            val squash = maxOf(0.15, abs(cos(spin)))
            translate(x, y) {
                rotate(Math.toDegrees(tilt).toFloat(), pivot = Offset.Zero) {
                    scale(squash.toFloat(), 1f, pivot = Offset.Zero) {
                        drawRoundRect(
                            palette[index % palette.size].copy(alpha = fade.toFloat()),
                            topLeft = Offset(-(w / 2).toFloat(), -(h / 2).toFloat()),
                            size = Size(w.toFloat(), h.toFloat()),
                            cornerRadius = CornerRadius((if (isRibbon) 1 * unit else 1.8f * unit)),
                        )
                    }
                }
            }
        }
    }
}

private const val DURATION = 2.0f

/** Tiny deterministic generator so a burst draws identically every frame. */
private class SeededRandom(seed: ULong) {
    private var state = if (seed == 0uL) 0x9E3779B9uL else seed

    fun next(low: Double, high: Double): Double {
        state = state xor (state shl 13)
        state = state xor (state shr 7)
        state = state xor (state shl 17)
        return low + (high - low) * ((state % 10_000uL).toDouble() / 10_000)
    }
}

/**
 * One-shot diagonal shine sweep, the "you won" gleam. Bump [trigger] to fire;
 * drawn inside the element's own bounds, clipped to its corners.
 */
fun Modifier.shine(trigger: Int, corner: Dp = 14.dp): Modifier = composed {
    val phase = remember { Animatable(-1f) }
    LaunchedEffect(trigger) {
        if (trigger <= 0) return@LaunchedEffect
        phase.snapTo(-1f)
        phase.animateTo(1.4f, tween(850, easing = FastOutSlowInEasing))
    }
    drawWithContent {
        drawContent()
        val p = phase.value
        if (p <= -1f || p >= 1.4f) return@drawWithContent
        val band = maxOf(size.width * 0.42f, 60.dp.toPx())
        val clip = Path().apply {
            addRoundRect(androidx.compose.ui.geometry.RoundRect(Rect(Offset.Zero, size), CornerRadius(corner.toPx())))
        }
        clipPath(clip) {
            translate(p * (size.width + band), size.height / 2) {
                rotate(16f, pivot = Offset.Zero) {
                    val rect = Rect(-band / 2, -size.height * 1.2f, band / 2, size.height * 1.2f)
                    drawRect(
                        Brush.horizontalGradient(
                            listOf(Color.Transparent, Color.White.copy(alpha = 0.08f), Color.White.copy(alpha = 0.62f), Color.White.copy(alpha = 0.08f), Color.Transparent),
                            startX = rect.left,
                            endX = rect.right,
                        ),
                        topLeft = rect.topLeft,
                        size = rect.size,
                    )
                }
            }
        }
    }
}

/** Horizontal shake for a wrong answer: fires once each time [trigger] goes up. */
fun Modifier.shake(trigger: Int): Modifier = composed {
    val travel = remember { Animatable(0f) }
    LaunchedEffect(trigger) {
        if (trigger <= 0) return@LaunchedEffect
        travel.snapTo(0f)
        travel.animateTo(2f, tween(400, easing = LinearEasing))
    }
    graphicsLayer { translationX = 7.dp.toPx() * sin(travel.value * Math.PI.toFloat() * 2) }
}
