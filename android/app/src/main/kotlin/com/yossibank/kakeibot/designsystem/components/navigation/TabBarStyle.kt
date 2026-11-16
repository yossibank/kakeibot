package com.yossibank.kakeibot.designsystem.components.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity

internal object TabBarStyle {
    val sheen: Brush
        get() = Brush.verticalGradient(
            0f to Color.White.copy(alpha = 0.07f),
            0.5f to Color.Transparent,
        )

    val rim: Brush
        @Composable
        @ReadOnlyComposable
        get() = Brush.verticalGradient(
            colors = listOf(
                Palette.accent.opacity(Emphasis.Strong),
                Palette.accent.opacity(Emphasis.Muted),
            ),
        )

    val indicatorRim: Brush
        @Composable
        @ReadOnlyComposable
        get() = Brush.verticalGradient(
            colors = listOf(
                Palette.accentStrong.opacity(Emphasis.Strong),
                Palette.accent.opacity(Emphasis.Soft),
            ),
        )

    val goldRing: Brush
        @Composable
        @ReadOnlyComposable
        get() = Brush.sweepGradient(
            colors = listOf(
                Palette.accentStrong,
                Palette.accent,
                Palette.accentDeep,
                Palette.accent,
                Palette.accentStrong,
            ),
        )

    @Composable
    @ReadOnlyComposable
    fun ring(hasDecorations: Boolean): Brush = if (hasDecorations) goldRing else SolidColor(Palette.outline)
}
