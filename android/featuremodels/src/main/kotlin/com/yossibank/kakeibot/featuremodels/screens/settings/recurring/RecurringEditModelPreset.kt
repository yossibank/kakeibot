package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier

fun RecurringEditModel.select(type: Entry.Kind) {
    if (type == state.form.type) {
        return
    }

    state.update { copy(type = type) }
    state.update { copy(categoryId = output.categories.firstOrNull()?.id) }
    presetDestination()
    suggestHolidayShift()
}

fun RecurringEditModel.select(category: Identifier<EntryCategory>) {
    state.update { copy(categoryId = category) }
    suggestHolidayShift()
}

internal fun RecurringEditModel.chooseCountMode() {
    if (!output.isEditing) {
        state.updateLoan { copy(isCountAuto = true) }
        return
    }

    val plan = output.autoPlan
    val end = state.form.endDate

    if (plan == null || end == null) {
        state.updateLoan { copy(isCountAuto = false) }
        return
    }

    val isAuto = output.autoEndDate(plan) == end && plan.finalAmount == state.loan.manualFinal

    state.updateLoan { copy(isCountAuto = isAuto) }
}

internal fun RecurringEditModel.presetDestination() {
    val form = state.form

    if (form.type != Entry.Kind.transfer || form.toWalletId != null) {
        return
    }

    state.update {
        copy(toWalletId = output.wallets.firstOrNull { it.id != form.walletId }?.id)
    }
}

internal fun RecurringEditModel.suggestHolidayShift() {
    if (output.isEditing || state.isHolidayShiftChosen) {
        return
    }

    state.update { copy(holidayShift = output.suggestedHolidayShift) }
}
