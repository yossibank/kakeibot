package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import com.yossibank.kakeibot.core.concepts.theme.ThemePalette
import com.yossibank.kakeibot.core.concepts.theme.color
import com.yossibank.kakeibot.core.concepts.theme.isLight

object Palette {
    val backgroundTop: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { backgroundTop }

    val backgroundBottom: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { backgroundBottom }

    val panel: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { panel }

    val cardTop: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { cardTop }

    val cardBottom: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { cardBottom }

    val line: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { line }

    val accent: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { accent }

    val accentDeep: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { accentDeep }

    val accentStrong: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { accentStrong }

    val text: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { text }

    val subtext: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { subtext }

    val hint: Color
        @Composable
        @ReadOnlyComposable
        get() = themed { hint }

    val rose: Color
        @Composable
        @ReadOnlyComposable
        get() = semantic(ThemePalette.Semantic.rose)

    val amber: Color
        @Composable
        @ReadOnlyComposable
        get() = semantic(ThemePalette.Semantic.amber)

    val holiday: Color
        @Composable
        @ReadOnlyComposable
        get() = semantic(ThemePalette.Semantic.holiday)

    val saturday: Color
        @Composable
        @ReadOnlyComposable
        get() = semantic(ThemePalette.Semantic.saturday)

    val shadow: Color
        @Composable
        @ReadOnlyComposable
        get() = black(lightOpacity = 0.18f)

    val scrim: Color
        @Composable
        @ReadOnlyComposable
        get() = black(lightOpacity = 0.4f)

    val glow: Color
        @Composable
        @ReadOnlyComposable
        get() = themed(lightOpacity = 0.4f) { accent }

    val paper: Color
        @Composable
        @ReadOnlyComposable
        get() = colorOf(rgb = LocalPalette.current.paper)

    val paperEdge: Color
        @Composable
        @ReadOnlyComposable
        get() = colorOf(rgb = LocalPalette.current.paperEdge)

    val hairline: Color
        @Composable
        @ReadOnlyComposable
        get() = accent.opacity(Emphasis.Subtle)

    val outline: Color
        @Composable
        @ReadOnlyComposable
        get() = accent.opacity(Emphasis.Medium)

    val faint: Color
        @Composable
        @ReadOnlyComposable
        get() = accent.opacity(Emphasis.Faint)

    val background: Brush
        @Composable
        @ReadOnlyComposable
        get() = background(of = LocalPalette.current)

    val card: Brush
        @Composable
        @ReadOnlyComposable
        get() = Brush.linearGradient(
            colors = listOf(cardTop, cardBottom),
            start = Offset.Zero,
            end = Offset.Infinite,
        )

    fun background(of: ThemePalette): Brush = Brush.verticalGradient(
        colors = listOf(
            colorOf(rgb = of.backgroundTop),
            colorOf(rgb = of.backgroundBottom),
        ),
    )

    @Composable
    @ReadOnlyComposable
    private fun themed(
        lightOpacity: Float = 1f,
        role: ThemePalette.() -> Int,
    ): Color {
        val palette = LocalPalette.current

        return colorOf(
            rgb = palette.role(),
            isLight = palette.isLight,
            lightOpacity = lightOpacity,
        )
    }

    @Composable
    @ReadOnlyComposable
    private fun semantic(semantic: ThemePalette.Semantic): Color =
        colorOf(rgb = LocalPalette.current.color(semantic))

    @Composable
    @ReadOnlyComposable
    private fun black(lightOpacity: Float): Color = colorOf(
        rgb = 0x000000,
        isLight = LocalPalette.current.isLight,
        lightOpacity = lightOpacity,
    )
}
