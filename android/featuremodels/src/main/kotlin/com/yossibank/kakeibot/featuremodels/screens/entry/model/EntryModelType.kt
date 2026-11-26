package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry

fun EntryModel.Field.field(of: Entry.Kind): EntryModel.Field {
    val isWallet = this == EntryModel.Field.Wallet || this == EntryModel.Field.ToWallet
    return if (isWallet && of == Entry.Kind.transfer) EntryModel.Field.Transfer else this
}

val EntryModel.Output.startField: EntryModel.Field
    get() {
        val isTransfer = state.form.type == Entry.Kind.transfer
        return if (isTransfer) EntryModel.Field.Transfer else EntryModel.Field.Category
    }

val EntryModel.Output.showsRecent: Boolean
    get() = isBlank && state.field == startField

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

internal fun EntryModel.Field.order(of: Entry.Kind): Int {
    val fields = if (of == Entry.Kind.transfer) transferFields else paymentFields
    return fields.indexOf(field(of)).coerceAtLeast(0)
}

private val transferFields = listOf(
    EntryModel.Field.Transfer,
    EntryModel.Field.Fee,
    EntryModel.Field.Date,
    EntryModel.Field.Amount,
)

private val paymentFields = listOf(
    EntryModel.Field.Category,
    EntryModel.Field.Wallet,
    EntryModel.Field.Date,
    EntryModel.Field.Amount,
)
