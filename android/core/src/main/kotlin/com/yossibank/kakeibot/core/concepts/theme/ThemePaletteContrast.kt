package com.yossibank.kakeibot.core.concepts.theme

import kotlin.math.pow

val ThemePalette.unreadableRoles: List<ThemePalette.Role>
    get() = readableRoles.mapNotNull { (role, minimum) ->
        val lowest = ThemePalette.surfaces.map { ThemePalette.contrast(this[role], this[it]) }.minOrNull() ?: 0.0

        if (lowest < minimum) role else null
    }

val ThemePalette.isLight: Boolean
    get() {
        val onBlack = ThemePalette.contrast(backgroundTop, 0x000000)
        val onWhite = ThemePalette.contrast(backgroundTop, 0xFFFFFF)

        return onBlack > onWhite
    }

fun ThemePalette.Companion.contrast(
    first: Int,
    second: Int,
): Double {
    val firstLuminance = luminance(first)
    val secondLuminance = luminance(second)
    val lighter = maxOf(firstLuminance, secondLuminance)
    val darker = minOf(firstLuminance, secondLuminance)

    return (lighter + 0.05) / (darker + 0.05)
}

internal val ThemePalette.Companion.surfaces: List<ThemePalette.Role>
    get() = surfaceRoles

private val surfaceRoles = listOf(
    ThemePalette.Role.backgroundTop,
    ThemePalette.Role.backgroundBottom,
    ThemePalette.Role.panel,
    ThemePalette.Role.cardTop,
    ThemePalette.Role.cardBottom,
)

private val readableRoles = listOf(
    ThemePalette.Role.accent to 3.0,
    ThemePalette.Role.accentStrong to 4.5,
    ThemePalette.Role.text to 4.5,
    ThemePalette.Role.subtext to 3.0,
    ThemePalette.Role.hint to 3.0,
)

private val luminanceWeights = listOf(0.2126, 0.7152, 0.0722)

private fun luminance(rgb: Int): Double {
    val channels = listOf(rgb shr 16, rgb shr 8, rgb).map { value ->
        val ratio = (value and 0xFF).toDouble() / 255
        val linear = (ratio + 0.055) / 1.055

        if (ratio <= 0.04045) ratio / 12.92 else linear.pow(2.4)
    }

    return channels.zip(luminanceWeights) { channel, weight -> channel * weight }.fold(0.0) { sum, part -> sum + part }
}
