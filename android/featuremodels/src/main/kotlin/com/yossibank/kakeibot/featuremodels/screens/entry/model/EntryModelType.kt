package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry

fun EntryModel.select(type: Entry.Kind) {
    if (state.form.type == type) {
        return
    }

    val isUntouched = !output.isEditing && !output.isChanged

    state.update { withType(type) }

    if (isUntouched && type != Entry.Kind.transfer) {
        setWallet(output.usualWalletId)
    }

    val form = state.form
    val categories = output.categories
    val remembered = form.categoryByType[type]

    val categoryId = when {
        categories.any { it.id == remembered } -> remembered
        categories.any { it.id == form.categoryId } -> form.categoryId
        else -> categories.firstOrNull()?.id
    }

    state.update { withCategory(categoryId) }

    if (type == Entry.Kind.transfer) {
        chooseDestination()
    }

    state.focus(output.startField)

    if (isUntouched) {
        input.baseline = output.snapshot
    }
}
