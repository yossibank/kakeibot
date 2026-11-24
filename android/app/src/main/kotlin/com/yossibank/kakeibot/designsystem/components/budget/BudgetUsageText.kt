package com.yossibank.kakeibot.designsystem.components.budget

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import kotlin.math.abs

val BudgetUsage.remainingText: String
    get() = if (isOver) {
        "オーバー ${AmountText.text(amount = (-remaining).clamped)}"
    } else {
        "残り ${AmountText.text(amount = remaining.clamped)}"
    }

val BudgetUsage.budgetText: String
    get() {
        val base = "予算 ${AmountText.text(amount = baseBudget)}"

        return when {
            carryover > 0 -> "$base ＋ 繰越 ${AmountText.text(amount = carryover.clamped)}"
            carryover < 0 -> "$base − 繰越 ${AmountText.text(amount = (-carryover).clamped)}"
            else -> base
        }
    }

val BudgetUsage.carryoverText: String
    get() {
        val sign = if (carryover < 0) "−" else "＋"
        return "繰越 $sign${AmountText.text(amount = abs(carryover).clamped)}"
    }

val BudgetUsage.tint: Color
    @Composable
    get() = when {
        isOver -> Palette.rose
        isNearLimit -> Palette.amber
        else -> Palette.accent
    }
