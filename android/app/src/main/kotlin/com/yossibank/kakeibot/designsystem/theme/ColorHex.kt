package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.ui.graphics.Color
import kotlin.math.roundToInt

val Color.hex: String
    get() {
        val values = listOf(red, green, blue).map { value ->
            (value.coerceIn(0f, 1f) * 255).roundToInt()
        }

        return "#" + values.joinToString("") { "%02X".format(it) }
    }

fun colorOf(hex: String): Color? {
    val digits = hex.removePrefix("#")

    if (digits.length != 6) {
        return null
    }

    val value = digits.toIntOrNull(radix = 16) ?: return null

    return colorOf(rgb = value)
}

fun colorOf(rgb: Int): Color = Color(
    red = (rgb shr 16) and 0xFF,
    green = (rgb shr 8) and 0xFF,
    blue = rgb and 0xFF,
)

internal fun colorOf(
    rgb: Int,
    isLight: Boolean,
    lightOpacity: Float,
): Color {
    val alpha = if (isLight) lightOpacity else 1f
    return colorOf(rgb = rgb).copy(alpha = alpha)
}
