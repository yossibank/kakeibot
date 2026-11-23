package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
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

val EntryModel.isWalletFromVoice: Boolean
    get() = voiceFilled?.walletId?.let { it == form.walletId } ?: false

val EntryModel.isDateFromVoice: Boolean
    get() = voiceFilled?.date?.let { it == form.date } ?: false

val EntryModel.isMemoFromVoice: Boolean
    get() = voiceFilled?.memo?.let { it.isNotEmpty() && it == store } ?: false

val EntryModel.showsVoice: Boolean
    get() = form.type != Entry.Kind.transfer && field == EntryModel.Field.Amount

val EntryModel.voiceHints: List<String>
    get() {
        val tags = allTags.filter { it.archivedAt == null }.map { it.name }
        val memos = recentMemos.mapNotNull { it.lines().firstOrNull() }

        return (
            categories.map { it.name } + tags + wallets.map { it.name } +
                templates.map { it.name } +
                memos
        )
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
    }

fun EntryModel.voiceReading(
    text: String,
    today: LocalDate,
): VoiceReading = VoiceReading.of(
    text = text,
    today = today,
    categories = categories,
    wallets = wallets,
)

fun EntryModel.apply(reading: VoiceReading): VoiceUndo {
    val undo = VoiceUndo(
        form = form,
        calculator = calculator,
    )

    val amount = reading.amount
    val isAmountValid = amount != null && amount in 1..AmountCalculator.maxValue
    val categoryId = reading.categoryId?.takeIf { id -> categories.any { it.id == id } }

    var next = form

    reading.walletId?.let { next = next.withWallet(it) }
    categoryId?.let { next = next.withCategory(it) }
    reading.date?.let { next = next.withDate(it) }
    reading.memo?.let { next = next.withStore(it) }

    fill(
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
        focus(EntryModel.Field.Amount)
    }

    return undo
}

fun EntryModel.undo(undo: VoiceUndo) {
    val restored = form.copy(
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
