package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem

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
