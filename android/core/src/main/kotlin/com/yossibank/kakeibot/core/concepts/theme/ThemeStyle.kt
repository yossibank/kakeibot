package com.yossibank.kakeibot.core.concepts.theme

data class ThemeStyle(
    val corner: ThemeCorner,
    val displayFont: ThemeFont,
    val textFont: ThemeFont,
    val textSize: ThemeTextSize = ThemeTextSize.standard,
    val rowSpacing: ThemeRowSpacing = ThemeRowSpacing.standard,
    val stampShape: ThemeStampShape = ThemeStampShape.circle,
    val showsTabTitles: Boolean = true,
    val backdrop: ThemeBackdrop = ThemeBackdrop.plain,
    val haptics: Boolean = true,
    val decorations: Boolean = true,
) {
    companion object {
        val standard = ThemeStyle(
            corner = ThemeCorner.standard,
            displayFont = ThemeFont.mincho,
            textFont = ThemeFont.gothic,
        )
    }
}
