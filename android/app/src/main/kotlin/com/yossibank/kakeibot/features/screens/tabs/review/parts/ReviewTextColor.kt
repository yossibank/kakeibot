package com.yossibank.kakeibot.features.screens.tabs.review.parts

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts.ReviewText

@Suppress("UnusedReceiverParameter")
@Composable
fun ReviewText.balanceColor(amount: Long): Color = when {
    amount > 0 -> Palette.accent
    amount < 0 -> Palette.rose
    else -> Palette.accentStrong
}
