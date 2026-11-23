package com.yossibank.kakeibot.features.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator

data class RecurringLoanInput(
    val count: AmountCalculator = AmountCalculator(),
    val isCountAuto: Boolean = true,
    val manualFinal: Int? = null,
)
