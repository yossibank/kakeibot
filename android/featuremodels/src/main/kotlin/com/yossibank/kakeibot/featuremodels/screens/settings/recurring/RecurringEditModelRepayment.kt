package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.endDate
import com.yossibank.kakeibot.core.concepts.recurring.maxCount

fun RecurringEditModel.open(panel: RecurringPanel) {
    if (panel == RecurringPanel.Count) {
        prepareCount()
    }

    state.panel = panel
}

fun RecurringEditModel.prepareCount() {
    state.updateLoan { copy(count = AmountCalculator(amount = output.repaymentCount ?: 0)) }
}

fun RecurringEditModel.pressCount(key: AmountCalculator.Key) {
    val pressed = state.loan.count.press(key)
    val isOver = pressed.amount > Recurring.maxCount
    val count = if (isOver) AmountCalculator(amount = Recurring.maxCount) else pressed

    state.updateLoan { copy(count = count) }

    val end = output.recurring(
        endDate = null,
        finalAmount = null,
    ).endDate(
        afterCount = count.amount,
        from = output.repaymentStart,
    )

    setEnd(end)
}

fun RecurringEditModel.setEnd(date: LocalDate?) {
    state.update { copy(endDate = date) }

    val manualFinal = output.manualFinalAmount(through = date)

    state.updateLoan {
        copy(
            isCountAuto = false,
            manualFinal = manualFinal,
        )
    }
}
