package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.voice.VoiceReading
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

const val RECENT_MEMO_LIMIT = 6

data class VoiceUndo(
    val form: EntryForm,
    val calculator: AmountCalculator,
)

data class VoiceFilled(
    val walletId: Identifier<Wallet>?,
    val date: LocalDate?,
    val memo: String?,
)

fun EntryModel.apply(reading: VoiceReading): VoiceUndo {
    val calculator = state.submodels.calculator

    val undo = VoiceUndo(
        form = state.fields.form,
        calculator = calculator,
    )

    val amount = reading.amount
    val isAmountValid = amount != null && amount in 1..AmountCalculator.maxValue

    reading.walletId?.let { setWallet(it) }

    val categoryId = reading.categoryId?.takeIf { id -> output.categories.any { it.id == id } }
    var next = state.fields.form

    categoryId?.let { next = next.withCategory(it) }
    reading.date?.let { next = next.withDate(it) }
    reading.memo?.let { next = next.withStore(it) }

    state.fill(
        form = next,
        calculator = if (amount != null &&
            isAmountValid
        ) {
            AmountCalculator(amount = amount)
        } else {
            calculator
        },
        voiceFilled = VoiceFilled(
            walletId = reading.walletId,
            date = reading.date,
            memo = reading.memo,
        ),
    )

    if (isAmountValid) {
        state.focus(EntryModel.Field.Amount)
    }

    return undo
}

fun EntryModel.State.undo(undo: VoiceUndo) {
    val restored = fields.form.copy(
        date = undo.form.date,
        categoryId = undo.form.categoryId,
        tagId = undo.form.tagId,
        walletId = undo.form.walletId,
        memo = undo.form.memo,
        billMonth = undo.form.billMonth,
    )

    fill(
        form = restored,
        calculator = undo.calculator,
        voiceFilled = null,
    )
}
