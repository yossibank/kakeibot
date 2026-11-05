package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.balance
import com.yossibank.kakeibot.core.shared.Identifier

data class CardBill(
    val recurring: Recurring,
    val date: LocalDate,
    val amount: Int,
    val balanceBefore: Int,
) {
    val balanceAfter: Int
        get() = balanceBefore - amount

    val shortage: Int
        get() = maxOf(-balanceAfter, 0)

    val period: ClosedRange<LocalDate>?
        get() = recurring.billingPeriod(paidOn = date)

    companion object {
        fun upcoming(
            recurrings: List<Recurring>,
            wallets: List<Wallet>,
            entries: List<Entry>,
            valuations: List<Valuation>,
            adjustments: List<Adjustment>,
            after: LocalDate,
        ): List<CardBill> {
            val cards = wallets.filter { it.kind == Wallet.Kind.card }.map { it.id }.toSet()
            val tomorrow = after.adding(days = 1)
            val balances = mutableMapOf<Identifier<Wallet>, Int>()

            return recurrings
                .filter { recurring ->
                    recurring.type == Entry.Kind.transfer && recurring.toWalletId in cards
                }
                .mapNotNull { recurring ->
                    recurring.nextDate(onOrAfter = tomorrow)?.let { recurring to it }
                }
                .sortedBy { it.second }
                .map { (recurring, date) ->
                    val source = recurring.walletId
                    val wallet = wallets.firstOrNull { it.id == source }

                    val current = wallet?.balance(
                        with = entries,
                        valuations = valuations,
                        adjustments = adjustments,
                    ) ?: 0

                    val before = balances[source] ?: current

                    val amount = recurring.amount(
                        paidOn = date,
                        entries = entries,
                    )

                    balances[source] = before - amount

                    CardBill(
                        recurring = recurring,
                        date = date,
                        amount = amount,
                        balanceBefore = before,
                    )
                }
        }
    }
}
