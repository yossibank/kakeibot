package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.balance
import com.yossibank.kakeibot.core.concepts.wallet.entriesByWallet
import com.yossibank.kakeibot.core.concepts.wallet.role

const val FREQUENT_ROUTE_LIMIT = 6

val EntryModel.Output.frequentRoutes: List<TransferRoute>
    get() {
        val shown = wallets.map { it.id }.toSet()

        val routes = (input.history?.entries ?: emptyList())
            .filter { entry ->
                entry.type == Entry.Kind.transfer &&
                    entry.recurringId == null &&
                    entry.id != input.editingId &&
                    entry.walletId in shown &&
                    entry.toWalletId in shown
            }.sortedByDescending { it.createdAt }
            .mapNotNull { entry -> entry.toWalletId?.let { TransferRoute(entry.walletId, it) } }

        val counts = routes.groupingBy { it }.eachCount()

        return routes
            .distinct()
            .withIndex()
            .sortedWith(
                compareByDescending<IndexedValue<TransferRoute>> {
                    counts[it.value] ?: 0
                }.thenBy { it.index },
            )
            .take(FREQUENT_ROUTE_LIMIT)
            .map { it.value }
    }

fun EntryModel.Output.balance(of: Wallet): Long? {
    val list = input.history ?: return null
    val editing = input.editingId

    val entries = list.entries.filter { entry ->
        entry.id != editing && (editing == null || entry.transferId != editing)
    }

    return of.balance(
        with = Wallet.entriesByWallet(entries)[of.id].orEmpty(),
        valuations = list.valuations,
        adjustments = list.adjustments,
        through = state.today,
    )
}

val EntryModel.Output.isOverSourceBalance: Boolean
    get() {
        if (state.form.type != Entry.Kind.transfer || amount <= 0) {
            return false
        }

        val balance = wallet?.let { balance(of = it) } ?: return false

        return amount + fee > balance
    }

val EntryModel.Output.loanRemaining: Long?
    get() {
        val wallet = toWallet ?: return null
        val balance = balance(of = wallet) ?: return null

        if (state.form.type != Entry.Kind.transfer || wallet.kind != Wallet.Kind.loan ||
            balance >= 0
        ) {
            return null
        }

        return -balance
    }

fun EntryModel.Output.currentLine(of: Wallet): BalanceLine? {
    val balance = balance(of = of) ?: return null

    return when (of.kind.role) {
        Wallet.Kind.Role.loan -> BalanceLine("今の残り", maxOf(-balance, 0))
        Wallet.Kind.Role.investment -> BalanceLine("今の評価額", balance)
        else -> BalanceLine("残高", balance)
    }
}

fun EntryModel.Output.afterLine(
    of: Wallet,
    isSource: Boolean,
): BalanceLine? {
    if (state.form.type != Entry.Kind.transfer || amount <= 0) {
        return null
    }

    val balance = balance(of = of) ?: return null
    val after = if (isSource) balance - amount - fee else balance + amount
    val shown = if (of.kind.role == Wallet.Kind.Role.loan) maxOf(-after, 0) else after

    return BalanceLine(afterTitle(of = of, isSource = isSource), shown)
}

fun EntryModel.Output.idleAfterLine(
    of: Wallet,
    isSource: Boolean,
): BalanceLine? = currentLine(of = of)?.let { current ->
    BalanceLine(afterTitle(of = of, isSource = isSource), current.amount)
}

private fun afterTitle(
    of: Wallet,
    isSource: Boolean,
): String = when {
    !isSource && of.kind.role == Wallet.Kind.Role.loan -> "返済後"
    !isSource && of.kind.role == Wallet.Kind.Role.investment -> "積立後"
    else -> "振替後"
}
