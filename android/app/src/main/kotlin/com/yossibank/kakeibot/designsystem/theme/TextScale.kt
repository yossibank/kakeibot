package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.runtime.compositionLocalOf
import kotlin.math.floor

object TextScale {
    const val FLOOR = 0.8
    const val AMOUNT_FLOOR = 0.5

    fun fitting(
        available: Float,
        needed: Float,
        floor: Double = FLOOR,
    ): Double {
        if (needed <= 0 || !available.isFinite()) {
            return 1.0
        }

        val ratio = floor(available.toDouble() / needed * 100) / 100

        return ratio.coerceIn(floor, 1.0)
    }
}

val LocalSharedTextScale = compositionLocalOf { 1.0 }
