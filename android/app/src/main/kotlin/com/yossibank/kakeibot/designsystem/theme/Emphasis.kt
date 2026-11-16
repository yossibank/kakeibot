package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.ui.graphics.Color

enum class Emphasis(
    val rawValue: Float,
) {
    Faint(0.06f),
    Subtle(0.12f),
    Soft(0.2f),
    Muted(0.35f),
    Medium(0.55f),
    Strong(0.8f),
}

fun Color.opacity(emphasis: Emphasis): Color = copy(alpha = alpha * emphasis.rawValue)
