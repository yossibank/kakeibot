package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry

data class Holdings(
    val onHand: Int,
    val cards: Int,
    val investments: Int,
    val loans: Int,
) {
    constructor(
        wallets: List<Wallet>,
        entries: List<Entry>,
        valuations: List<Valuation> = emptyList(),
        adjustments: List<Adjustment> = emptyList(),
        through: LocalDate? = null,
    ) : this(
        onHand = total(
            wallets = wallets,
            entries = entries,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.onHand,
        ),
        cards = total(
            wallets = wallets,
            entries = entries,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.card,
        ),
        investments = total(
            wallets = wallets,
            entries = entries,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.investment,
        ),
        loans = total(
            wallets = wallets,
            entries = entries,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.loan,
        ),
    )

    val available: Int
        get() = onHand + cards

    val netWorth: Int
        get() = available + investments + loans

    val unpaid: Int
        get() = maxOf(-cards, 0)

    val refund: Int
        get() = maxOf(cards, 0)

    private companion object {
        fun total(
            wallets: List<Wallet>,
            entries: List<Entry>,
            valuations: List<Valuation>,
            adjustments: List<Adjustment>,
            through: LocalDate?,
            role: Wallet.Kind.Role,
        ): Int = Wallet.totalBalance(
            of = wallets.filter { it.kind.role == role },
            with = entries,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
        )
    }
}

val Wallet.Kind.role: Wallet.Kind.Role
    get() = when (this) {
        Wallet.Kind.cash,
        Wallet.Kind.bank,
        Wallet.Kind.emoney,
        Wallet.Kind.point,
        Wallet.Kind.other,
        -> Wallet.Kind.Role.onHand

        Wallet.Kind.card -> Wallet.Kind.Role.card

        Wallet.Kind.investment -> Wallet.Kind.Role.investment

        Wallet.Kind.loan -> Wallet.Kind.Role.loan
    }

val Wallet.Kind.isDebt: Boolean
    get() = this == Wallet.Kind.card || this == Wallet.Kind.loan
