package com.yossibank.kakeibot.core.concepts.theme

import kotlin.math.roundToLong

operator fun ThemePalette.Companion.invoke(
    background: Int,
    surface: Int,
    text: Int,
    subtext: Int,
    accent: Int,
): ThemePalette {
    val onBlack = contrast(background, 0x000000)
    val onWhite = contrast(background, 0xFFFFFF)
    val mixes = if (onBlack > onWhite) Mixes.light else Mixes.dark
    val (cardTarget, cardRatio) = mixes.cardBottom
    val cardBottomMix = (cardTarget ?: background) to cardRatio
    val backgroundBottom = mix(background, mixes.backgroundBottom)
    val panel = mix(background, mixes.panel)
    val cardBottom = mix(surface, cardBottomMix)
    val line = mix(surface, text to 0.12)
    val accentDeep = mix(accent, mixes.accentDeep)
    val accentStrong = mix(accent, mixes.accentStrong)
    val hint = mix(subtext, background to 0.12)

    return ThemePalette(
        backgroundTop = background,
        backgroundBottom = backgroundBottom,
        panel = panel,
        cardTop = surface,
        cardBottom = cardBottom,
        line = line,
        accent = accent,
        accentDeep = accentDeep,
        accentStrong = accentStrong,
        text = text,
        subtext = subtext,
        hint = hint,
    )
}

private class Mixes(
    val backgroundBottom: Pair<Int, Double>,
    val panel: Pair<Int, Double>,
    val cardBottom: Pair<Int?, Double>,
    val accentDeep: Pair<Int, Double>,
    val accentStrong: Pair<Int, Double>,
) {
    companion object {
        val dark = Mixes(
            backgroundBottom = 0x000000 to 0.6,
            panel = 0x000000 to 0.35,
            cardBottom = 0x000000 to 0.55,
            accentDeep = 0x000000 to 0.35,
            accentStrong = 0xFFFFFF to 0.6,
        )

        val light = Mixes(
            backgroundBottom = 0x000000 to 0.04,
            panel = 0x000000 to 0.02,
            cardBottom = null to 0.5,
            accentDeep = 0xFFFFFF to 0.35,
            accentStrong = 0x000000 to 0.45,
        )
    }
}

private fun mix(
    color: Int,
    target: Pair<Int, Double>,
): Int {
    val (other, ratio) = target

    val channels = listOf(16, 8, 0).map { shift ->
        val from = ((color shr shift) and 0xFF).toDouble()
        val to = ((other shr shift) and 0xFF).toDouble()
        val mixed = (from + (to - from) * ratio).roundToLong()

        mixed.toInt() shl shift
    }

    return channels.fold(0) { result, channel -> result or channel }
}
