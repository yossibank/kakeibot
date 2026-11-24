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

    if (remaining <= AmountCalculator.maxValue) {
        state.setAmount(remaining.toInt())
    }
}

fun EntryModel.State.applyRoute(route: TransferRoute) {
    update { withWallet(route.walletId).copy(toWalletId = route.toWalletId) }
}
