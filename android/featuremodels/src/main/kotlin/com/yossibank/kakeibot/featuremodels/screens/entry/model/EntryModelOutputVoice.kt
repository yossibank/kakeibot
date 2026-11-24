package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.voice.VoiceReading

val EntryModel.Output.isWalletFromVoice: Boolean
    get() = state.voiceFilled?.walletId?.let { it == state.form.walletId } ?: false

val EntryModel.Output.isDateFromVoice: Boolean
    get() = state.voiceFilled?.date?.let { it == state.form.date } ?: false

val EntryModel.Output.isMemoFromVoice: Boolean
    get() = state.voiceFilled?.memo?.let { it.isNotEmpty() && it == state.store } ?: false

val EntryModel.Output.showsVoice: Boolean
    get() = state.form.type != Entry.Kind.transfer && state.field == EntryModel.Field.Amount

val EntryModel.Output.voiceHints: List<String>
    get() {
        val tags = allTags.filter { it.archivedAt == null }.map { it.name }
        val memos = input.recentMemos.mapNotNull { it.lines().firstOrNull() }

        return (
            categories.map { it.name } + tags + wallets.map { it.name } +
                templates.map { it.name } +
                memos
        )
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
    }

fun EntryModel.Output.voiceReading(
    text: String,
    today: LocalDate,
): VoiceReading = VoiceReading.of(
    text = text,
    today = today,
    categories = categories,
    wallets = wallets,
)
