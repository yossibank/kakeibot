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
    val calculator: AmountCalculator,
    val date: LocalDate,
    val categoryId: Identifier<EntryCategory>?,
    val tagId: Identifier<EntryTag>?,
    val walletId: Identifier<Wallet>?,
    val billMonth: YearMonth?,
    val memo: String,
)

data class VoiceFilled(
    val walletId: Identifier<Wallet>?,
    val date: LocalDate?,
    val memo: String?,
)

val EntryModel.isWalletFromVoice: Boolean
    get() = voiceFilled?.walletId?.let { it == walletId } ?: false

val EntryModel.isDateFromVoice: Boolean
    get() = voiceFilled?.date?.let { it == date } ?: false

val EntryModel.isMemoFromVoice: Boolean
    get() = voiceFilled?.memo?.let { it.isNotEmpty() && it == store } ?: false

val EntryModel.showsVoice: Boolean
    get() = type != Entry.Kind.transfer && field == EntryModel.Field.Amount

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
        calculator = calculator,
        date = date,
        categoryId = categoryId,
        tagId = tagId,
        walletId = walletId,
        billMonth = billMonth,
        memo = memo,
    )

    val amount = reading.amount

    if (amount != null && amount in 1..AmountCalculator.maxValue) {
        calculator = AmountCalculator(amount = amount)
        focus(EntryModel.Field.Amount)
    }

    reading.walletId?.let { id ->
        if (id != walletId) {
            billMonth = null
        }

        walletId = id
    }

    reading.categoryId?.let { id ->
        if (categories.any { it.id == id }) {
            if (id != categoryId) {
                tagId = null
            }

            categoryId = id
        }
    }

    reading.date?.let { date ->
        if (date != this.date) {
            billMonth = null
        }

        this.date = date
    }

    reading.memo?.let { store = it }

    voiceFilled = VoiceFilled(
        walletId = reading.walletId,
        date = reading.date,
        memo = reading.memo,
    )

    return undo
}

fun EntryModel.undo(undo: VoiceUndo) {
    walletId = undo.walletId
    categoryId = undo.categoryId
    tagId = undo.tagId
    calculator = undo.calculator
    date = undo.date
    billMonth = undo.billMonth
    memo = undo.memo
    voiceFilled = null
}
