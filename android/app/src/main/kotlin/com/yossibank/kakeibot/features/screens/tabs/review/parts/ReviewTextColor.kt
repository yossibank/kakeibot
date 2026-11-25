package com.yossibank.kakeibot.features.screens.tabs.review.parts

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.yossibank.kakeibot.designsystem.theme.Palette

object ReviewText {
    fun balanceTitle(amount: Long): String = when {
        amount > 0 -> "収支 · 黒字"
        amount < 0 -> "収支 · 赤字"
        else -> "収支"
    }

    @Composable
    fun balanceColor(amount: Long): Color = when {
        amount > 0 -> Palette.accent
        amount < 0 -> Palette.rose
        else -> Palette.accentStrong
    }
}
