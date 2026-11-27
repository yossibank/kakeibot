package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry

data class FieldFocus(
    val field: EntryModel.Field = EntryModel.Field.Category,
    val isForward: Boolean = true,
) {
    fun moved(
        to: EntryModel.Field,
        type: Entry.Kind,
    ): FieldFocus {
        val isTransferOnly = to == EntryModel.Field.Fee || to == EntryModel.Field.Transfer
        val isSkipped = isTransferOnly && type != Entry.Kind.transfer
        val next = if (isSkipped) EntryModel.Field.Amount else to

        return FieldFocus(
            field = next,
            isForward = next.order(of = type) >= field.order(of = type),
        )
    }
}
