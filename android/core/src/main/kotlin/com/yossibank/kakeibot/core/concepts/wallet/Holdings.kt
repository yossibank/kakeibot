package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier

data class Holdings(
    val onHand: Long,
    val cards: Long,
    val investments: Long,
    val loans: Long,
) {
    constructor(
        wallets: List<Wallet>,
        entries: List<Entry>,
        valuations: List<Valuation> = emptyList(),
        adjustments: List<Adjustment> = emptyList(),
        through: LocalDate? = null,
    ) : this(
        wallets = wallets,
        entriesByWallet = Wallet.entriesByWallet(entries),
        valuations = valuations,
        adjustments = adjustments,
        through = through,
    )

    constructor(
        wallets: List<Wallet>,
        entriesByWallet: Map<Identifier<Wallet>, List<Entry>>,
        valuations: List<Valuation> = emptyList(),
        adjustments: List<Adjustment> = emptyList(),
        through: LocalDate? = null,
    ) : this(
        onHand = total(
            wallets = wallets,
            entriesByWallet = entriesByWallet,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.onHand,
        ),
        cards = total(
            wallets = wallets,
            entriesByWallet = entriesByWallet,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.card,
        ),
        investments = total(
            wallets = wallets,
            entriesByWallet = entriesByWallet,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.investment,
        ),
        loans = total(
            wallets = wallets,
            entriesByWallet = entriesByWallet,
            valuations = valuations,
            adjustments = adjustments,
            through = through,
            role = Wallet.Kind.Role.loan,
        ),
    )

    val available: Long
        get() = onHand + cards

    val netWorth: Long
        get() = available + investments + loans

    val unpaid: Long
        get() = maxOf(-cards, 0L)

    val refund: Long
        get() = maxOf(cards, 0L)

    private companion object {
        fun total(
            wallets: List<Wallet>,
            entriesByWallet: Map<Identifier<Wallet>, List<Entry>>,
            valuations: List<Valuation>,
            adjustments: List<Adjustment>,
            through: LocalDate?,
            role: Wallet.Kind.Role,
        ): Long = wallets
            .filter { it.kind.role == role }
            .fold(0L) { total, wallet ->
                val balance = wallet.balance(
                    with = entriesByWallet[wallet.id].orEmpty(),
                    valuations = valuations,
                    adjustments = adjustments,
                    through = through,
                )

                total + balance
            }
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
