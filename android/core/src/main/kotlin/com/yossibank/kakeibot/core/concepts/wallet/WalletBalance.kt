package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry

fun Wallet.Companion.totalBalance(
    of: List<Wallet>,
    with: List<Entry>,
    valuations: List<Valuation> = emptyList(),
    adjustments: List<Adjustment> = emptyList(),
    through: LocalDate? = null,
): Int = of.fold(0) { total, wallet ->
    val balance = wallet.balance(
        with = with,
        valuations = valuations,
        adjustments = adjustments,
        through = through,
    )

    total + balance
}

fun Wallet.balance(
    with: List<Entry>,
    valuations: List<Valuation> = emptyList(),
    adjustments: List<Adjustment> = emptyList(),
    through: LocalDate? = null,
): Int {
    val valuation = if (kind == Wallet.Kind.investment) {
        latestValuation(
            valuations = valuations,
            through = through,
        )
    } else {
        null
    }

    val start = valuation?.amount ?: initialBalance

    val recorded = with.fold(start) { balance, entry ->
        when {
            through != null && through < entry.date -> balance
            valuation != null && valuation.includes(entry) -> balance
            else -> balance + change(entry)
        }
    }

    return adjustments.fold(recorded) { balance, adjustment ->
        when {
            adjustment.walletId != id -> balance
            through != null && through < adjustment.date -> balance
            valuation != null && valuation.includes(adjustment) -> balance
            else -> balance + adjustment.amount
        }
    }
}

private fun Wallet.latestValuation(
    valuations: List<Valuation>,
    through: LocalDate?,
): Valuation? = valuations
    .filter { valuation ->
        valuation.walletId == id && (through == null || valuation.date <= through)
    }
    .maxByOrNull { it.date }

private fun Wallet.change(entry: Entry): Int = when (entry.type) {
    Entry.Kind.expense -> if (entry.walletId == id) -entry.amount else 0
    Entry.Kind.income -> if (entry.walletId == id) entry.amount else 0
    Entry.Kind.transfer -> transferChange(entry)
}

private fun Wallet.transferChange(entry: Entry): Int {
    val outgoing = if (entry.walletId == id) -entry.amount else 0
    val incoming = if (entry.toWalletId == id) entry.amount else 0

    return outgoing + incoming
}
