package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.ui.text.font.FontFamily
import com.yossibank.kakeibot.core.concepts.theme.ThemeFont
import kotlin.math.max

enum class FontSize(
    val rawValue: Float,
) {
    Micro(9f),
    Caption(11f),
    Small(13f),
    Body(16f),
    Headline(20f),
    Title(28f),
    LargeTitle(32f),
    Display(40f),
    ;

    companion object {
        const val MINIMUM_POINTS = 10f

        fun points(
            base: Float,
            scale: Double,
            shared: Double,
        ): Float = (max(base * scale, MINIMUM_POINTS.toDouble()) * shared).toFloat()
    }
}

enum class FontTextStyle(
    val baseSize: Float,
) {
    LargeTitle(34f),
    Title(28f),
    Title2(22f),
    Title3(20f),
    Body(17f),
    Callout(16f),
    Subheadline(15f),
    Footnote(13f),
    Caption(12f),
    Caption2(11f),
}

internal val ThemeFont.family: FontFamily
    get() = when (this) {
        ThemeFont.mincho -> FontFamily.Serif

        ThemeFont.gothic,
        ThemeFont.rounded,
        ThemeFont.handwriting,
        ThemeFont.dot,
        ThemeFont.pop,
        -> FontFamily.Default
    }
