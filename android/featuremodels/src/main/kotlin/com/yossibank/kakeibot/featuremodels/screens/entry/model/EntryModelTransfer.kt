package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

data class TransferRoute(
    val walletId: Identifier<Wallet>,
    val toWalletId: Identifier<Wallet>,
)

fun EntryModel.payOffLoan() {
    val remaining = output.loanRemaining ?: return

    state.setAmount(minOf(remaining, AmountCalculator.maxValue.toLong()).toInt())
}

fun EntryModel.State.applyRoute(route: TransferRoute) {
    update { withWallet(route.walletId).copy(toWalletId = route.toWalletId) }
}

fun EntryModel.State.selectDestination(wallet: Wallet) {
    update { copy(toWalletId = wallet.id) }
    focus(EntryModel.Field.Transfer)
}

fun EntryModel.State.swapWallets() {
    update {
        copy(
            walletId = toWalletId,
            toWalletId = walletId,
            billMonth = null,
        )
    }
}

internal fun EntryModel.chooseDestination() {
    val form = state.form

    if (form.toWalletId != null && form.toWalletId != form.walletId) {
        return
    }

    state.update { copy(toWalletId = output.wallets.firstOrNull { it.id != form.walletId }?.id) }
}
