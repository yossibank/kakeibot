package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator

data class RecurringRepayment(
    val count: AmountCalculator = AmountCalculator(),
    val isCountAuto: Boolean = true,
    val manualFinal: Int? = null,
) {
    fun counted(count: AmountCalculator): RecurringRepayment = copy(count = count)

    fun usingAutoCount(): RecurringRepayment = copy(
        isCountAuto = true,
        manualFinal = null,
    )

    fun usingManualCount(final: Int?): RecurringRepayment = copy(
        isCountAuto = false,
        manualFinal = final,
    )

    fun countAuto(isAuto: Boolean): RecurringRepayment = copy(isCountAuto = isAuto)

    fun loaded(final: Int?): RecurringRepayment = copy(manualFinal = final)
}
