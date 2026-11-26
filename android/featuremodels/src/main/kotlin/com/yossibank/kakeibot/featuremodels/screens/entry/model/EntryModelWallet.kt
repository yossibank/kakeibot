package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

fun EntryModel.select(wallet: Wallet) {
    setWallet(wallet.id)
    val isTransfer = state.form.type == Entry.Kind.transfer
    state.focus(if (isTransfer) EntryModel.Field.Transfer else EntryModel.Field.Amount)
}

internal fun EntryModel.setWallet(id: Identifier<Wallet>?) {
    val form = state.form

    val moved = form.withWallet(
        id = id,
        offering = output.categories(of = form.type, walletId = id),
        allCategories = output.allCategories,
        allTags = output.allTags,
    )

    state.update { moved }
}
