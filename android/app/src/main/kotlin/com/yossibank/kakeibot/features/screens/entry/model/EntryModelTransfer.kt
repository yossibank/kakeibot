package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.balance
import com.yossibank.kakeibot.core.concepts.wallet.entriesByWallet
import com.yossibank.kakeibot.core.concepts.wallet.role
import com.yossibank.kakeibot.core.shared.Identifier

const val FREQUENT_ROUTE_LIMIT = 6
const val DESTINATION_TITLE = "振替先"

data class TransferRoute(
    val walletId: Identifier<Wallet>,
    val toWalletId: Identifier<Wallet>,
)

data class BalanceLine(
    val title: String,
    val amount: Long,
)

val EntryModel.frequentRoutes: List<TransferRoute>
    get() {
        val shown = wallets.map { it.id }.toSet()

        val routes = (history?.entries ?: emptyList())
            .filter { entry ->
                entry.type == Entry.Kind.transfer &&
                    entry.recurringId == null &&
                    entry.id != editingId &&
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

fun EntryModel.balance(of: Wallet): Long? {
    val list = history ?: return null
    val editing = editingId

    val entries = list.entries.filter { entry ->
        entry.id != editing && (editing == null || entry.transferId != editing)
    }

    return of.balance(
        with = Wallet.entriesByWallet(entries)[of.id].orEmpty(),
        valuations = list.valuations,
        adjustments = list.adjustments,
        through = today,
    )
}

val EntryModel.isOverSourceBalance: Boolean
    get() {
        if (type != Entry.Kind.transfer || amount <= 0) {
            return false
        }

        val balance = wallet?.let(::balance) ?: return false

        return amount + fee > balance
    }

val EntryModel.loanRemaining: Long?
    get() {
        val wallet = toWallet ?: return null
        val balance = balance(of = wallet) ?: return null

        if (type != Entry.Kind.transfer || wallet.kind != Wallet.Kind.loan || balance >= 0) {
            return null
        }

        return -balance
    }

fun EntryModel.currentLine(of: Wallet): BalanceLine? {
    val balance = balance(of = of) ?: return null

    return when (of.kind.role) {
        Wallet.Kind.Role.loan -> BalanceLine("今の残り", maxOf(-balance, 0))
        Wallet.Kind.Role.investment -> BalanceLine("今の評価額", balance)
        else -> BalanceLine("残高", balance)
    }
}

fun EntryModel.afterLine(
    of: Wallet,
    isSource: Boolean,
): BalanceLine? {
    if (type != Entry.Kind.transfer || amount <= 0) {
        return null
    }

    val balance = balance(of = of) ?: return null
    val after = if (isSource) balance - amount - fee else balance + amount
    val shown = if (of.kind.role == Wallet.Kind.Role.loan) maxOf(-after, 0) else after

    return BalanceLine(afterTitle(of = of, isSource = isSource), shown)
}

fun EntryModel.idleAfterLine(
    of: Wallet,
    isSource: Boolean,
): BalanceLine? = currentLine(of = of)?.let { current ->
    BalanceLine(afterTitle(of = of, isSource = isSource), current.amount)
}

fun EntryModel.payOffLoan() {
    val remaining = loanRemaining ?: return

    if (remaining <= AmountCalculator.maxValue) {
        calculator = AmountCalculator(amount = remaining.toInt())
    }
}

fun EntryModel.applyRoute(route: TransferRoute) {
    if (route.walletId != walletId) {
        billMonth = null
    }

    walletId = route.walletId
    toWalletId = route.toWalletId
}

private fun EntryModel.afterTitle(
    of: Wallet,
    isSource: Boolean,
): String = when {
    !isSource && of.kind.role == Wallet.Kind.Role.loan -> "返済後"
    !isSource && of.kind.role == Wallet.Kind.Role.investment -> "積立後"
    else -> "振替後"
}
