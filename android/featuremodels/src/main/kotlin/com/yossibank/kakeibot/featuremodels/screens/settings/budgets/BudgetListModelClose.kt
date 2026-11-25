package com.yossibank.kakeibot.featuremodels.screens.settings.budgets

fun BudgetListModel.close() {
    if (output.isChanged) {
        state.isConfirmingDiscard = true
    } else {
        state.cancelEditing()
    }
}
