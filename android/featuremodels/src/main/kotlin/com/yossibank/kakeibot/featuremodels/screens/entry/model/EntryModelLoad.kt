package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.store.writes.methods.EntryWriteError
import com.yossibank.kakeibot.store.writes.methods.EntryWriteException

fun EntryModel.close(): Boolean {
    if (output.isChanged) {
        state.present(EntryModel.Presented.Discard)
        return false
    }

    return true
}

internal fun EntryModel.startNew() {
    state.update { withCategory(output.categories.firstOrNull()?.id) }
    setWallet(output.usualWalletId)
}

internal fun EntryModel.fill(
    entry: Entry,
    items: List<EntryItem.Draft>,
    fee: Int,
) {
    val form = EntryForm.of(
        entry = entry,
        items = items,
        offering = output.offeredCategories(of = entry.type, walletId = entry.walletId),
        allCategories = output.allCategories,
        allTags = output.allTags,
    )

    state.load(
        form = form,
        amount = entry.amount,
        fee = fee,
    )
}

internal fun EntryModel.describe(error: Exception): String {
    val isMissing = (error as? EntryWriteException)?.error == EntryWriteError.entryNotFound
    return if (isMissing) "記録が見つかりませんでした" else ModelTask.saveFailed
}
