package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier

fun RecurringEditModel.select(type: Entry.Kind) {
    if (type == state.fields.form.type) {
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
        state.setCountAuto(true)
        return
    }

    val plan = output.autoPlan
    val end = state.fields.form.endDate

    if (plan == null || end == null) {
        state.setCountAuto(false)
        return
    }

    val isAuto = output.autoEndDate(plan) == end && plan.finalAmount == state.repayment.manualFinal

    state.setCountAuto(isAuto)
}

internal fun RecurringEditModel.presetDestination() {
    val form = state.fields.form

    if (form.type != Entry.Kind.transfer || form.toWalletId != null) {
        return
    }

    state.update {
        copy(toWalletId = output.wallets.firstOrNull { it.id != form.walletId }?.id)
    }
}

internal fun RecurringEditModel.suggestHolidayShift() {
    if (output.isEditing || state.fields.isHolidayShiftChosen) {
        return
    }

    state.update { copy(holidayShift = output.suggestedHolidayShift) }
}
