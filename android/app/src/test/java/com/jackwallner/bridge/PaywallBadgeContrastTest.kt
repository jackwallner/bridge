package com.jackwallner.bridge

import androidx.compose.ui.graphics.Color
import com.jackwallner.bridge.ui.theme.BridgeColors
import kotlin.math.pow
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of the iOS gold text fix: the paywall plan badge uses the readable gold shade. */
class PaywallBadgeContrastTest {
    private fun channel(value: Float): Double = value.toDouble().let { if (it <= 0.03928) it / 12.92 else ((it + 0.055) / 1.055).pow(2.4) }
    private fun luminance(c: Color) = 0.2126 * channel(c.red) + 0.7152 * channel(c.green) + 0.0722 * channel(c.blue)
    private fun over(top: Color, alpha: Float, base: Color) = Color(
        top.red * alpha + base.red * (1 - alpha), top.green * alpha + base.green * (1 - alpha), top.blue * alpha + base.blue * (1 - alpha),
    )
    private fun contrast(a: Color, b: Color) = listOf(luminance(a), luminance(b)).sorted().let { (dark, light) -> (light + 0.05) / (dark + 0.05) }

    /** The paywall plan badge is gold text on an 18% gold pill over the card surface. */
    @Test
    fun paywallBadgeTextIsReadable() {
        listOf("light" to BridgeColors.light, "dark" to BridgeColors.dark).forEach { (name, colors) ->
            val pill = over(colors.gold, 0.18f, colors.card)
            assertTrue("$name ${contrast(colors.goldText, pill)}", contrast(colors.goldText, pill) >= 4.5)
        }
    }
}
