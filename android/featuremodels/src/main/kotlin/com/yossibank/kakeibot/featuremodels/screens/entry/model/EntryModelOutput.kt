package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry

val EntryModel.Output.isEditing: Boolean
    get() = input.editingId != null

val EntryModel.Output.isBlank: Boolean
    get() = !isEditing && amount <= 0

val EntryModel.Output.amount: Int
    get() = state.calculator.amount

val EntryModel.Output.fee: Int
    get() = if (state.form.type == Entry.Kind.transfer) state.feeCalculator.amount else 0

val EntryModel.Output.activeCalculator: AmountCalculator
    get() = if (state.field == EntryModel.Field.Fee) state.feeCalculator else state.calculator
