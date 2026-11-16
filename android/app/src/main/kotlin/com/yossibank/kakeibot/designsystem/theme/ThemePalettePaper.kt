package com.yossibank.kakeibot.designsystem.theme

import com.yossibank.kakeibot.core.concepts.theme.ThemePalette
import kotlin.math.roundToInt

internal val ThemePalette.paper: Int
    get() {
        if (!isDark) {
            return cardTop
        }

        val card = mix(
            base = cardTop,
            other = cardBottom,
            ratio = 0.5,
        )

        return mix(
            base = card,
            other = accent,
            ratio = 0.05,
        )
    }

internal val ThemePalette.paperEdge: Int
    get() = mix(
        base = cardTop,
        other = accent,
        ratio = 0.35,
    )

private val ThemePalette.isDark: Boolean
    get() = luminance(cardTop) < 0.4

private fun channels(rgb: Int): List<Double> = listOf(16, 8, 0).map { shift ->
    ((rgb shr shift) and 0xFF).toDouble()
}

private fun luminance(rgb: Int): Double {
    val values = channels(rgb)

    return (0.299 * values[0] + 0.587 * values[1] + 0.114 * values[2]) / 255
}

private fun mix(
    base: Int,
    other: Int,
    ratio: Double,
): Int = channels(base).zip(channels(other)).fold(0) { result, pair ->
    val value = (pair.first + (pair.second - pair.first) * ratio).roundToInt()

    (result shl 8) or value
}
