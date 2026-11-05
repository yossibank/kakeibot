package com.yossibank.kakeibot.core.concepts.theme

import kotlin.math.abs
import kotlin.math.roundToLong

fun ThemePalette.color(semantic: ThemePalette.Semantic): Int {
    val base = if (isLight) semantic.light else semantic.dark

    if (lowestContrast(base) >= semanticMinimum) {
        return base
    }

    val hsl = HSL.of(base)
    val directions = if (isLight) listOf(-1.0, 1.0) else listOf(1.0, -1.0)
    val shifts = directions.map { shifted(hsl, direction = it) }

    val found = shifts.firstNotNullOfOrNull { it.found }

    if (found != null) {
        return found
    }

    val candidates = listOf(base) + shifts.map { it.best }

    return candidates.maxWithOrNull { first, second ->
        lowestContrast(first).compareTo(lowestContrast(second))
    } ?: base
}

private const val semanticMinimum = 3.0
private const val semanticSteps = 100

private class Shift(
    val found: Int?,
    val best: Int,
)

private class HSL(
    val hue: Double,
    val saturation: Double,
    val lightness: Double,
) {
    val rgb: Int
        get() {
            val chroma = (1 - abs(2 * lightness - 1)) * saturation
            val sector = hue / 60
            val sectorRemainder = sector % 2
            val mid = chroma * (1 - abs(sectorRemainder - 1))
            val offset = lightness - chroma / 2
            val parts = when (sector.toInt()) {
                0 -> Triple(chroma, mid, 0.0)
                1 -> Triple(mid, chroma, 0.0)
                2 -> Triple(0.0, chroma, mid)
                3 -> Triple(0.0, mid, chroma)
                4 -> Triple(mid, 0.0, chroma)
                else -> Triple(chroma, 0.0, mid)
            }

            fun byte(value: Double): Int = ((value + offset) * 255).roundToLong().toInt()

            return (byte(parts.first) shl 16) or (byte(parts.second) shl 8) or byte(parts.third)
        }

    fun lightness(by: Double): HSL {
        val shifted = lightness + by
        val lowerClamped = maxOf(shifted, 0.0)
        val clamped = minOf(lowerClamped, 1.0)

        return HSL(
            hue = hue,
            saturation = saturation,
            lightness = clamped,
        )
    }

    companion object {
        fun of(rgb: Int): HSL {
            val red = ((rgb shr 16) and 0xFF).toDouble() / 255
            val green = ((rgb shr 8) and 0xFF).toDouble() / 255
            val blue = (rgb and 0xFF).toDouble() / 255
            val high = maxOf(red, green, blue)
            val low = minOf(red, green, blue)
            val delta = high - low
            val lightness = (high + low) / 2

            if (delta <= 0) {
                return HSL(
                    hue = 0.0,
                    saturation = 0.0,
                    lightness = lightness,
                )
            }

            val saturation = delta / (1 - abs(2 * lightness - 1))

            val sector = when (high) {
                red -> ((green - blue) / delta) % 6
                green -> (blue - red) / delta + 2
                else -> (red - green) / delta + 4
            }

            val hue = (if (sector < 0) sector + 6 else sector) * 60

            return HSL(
                hue = hue,
                saturation = saturation,
                lightness = lightness,
            )
        }
    }
}

private fun ThemePalette.lowestContrast(color: Int): Double =
    ThemePalette.surfaces.map { ThemePalette.contrast(color, this[it]) }.minOrNull() ?: 0.0

private fun ThemePalette.shifted(
    hsl: HSL,
    direction: Double,
): Shift {
    var best = hsl.rgb

    for (step in 1..semanticSteps) {
        val amount = direction * step.toDouble() / semanticSteps.toDouble()
        val color = hsl.lightness(by = amount).rgb

        if (lowestContrast(color) >= semanticMinimum) {
            return Shift(
                found = color,
                best = color,
            )
        }

        if (lowestContrast(color) > lowestContrast(best)) {
            best = color
        }
    }

    return Shift(
        found = null,
        best = best,
    )
}
