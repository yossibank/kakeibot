package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.balance
import com.yossibank.kakeibot.core.shared.Identifier

data class CardBill(
    val recurring: Recurring,
    val date: LocalDate,
    val amount: Long,
    val balanceBefore: Long,
    val isOpen: Boolean = false,
) {
    val balanceAfter: Long
        get() = balanceBefore - amount

    val shortage: Long
        get() = maxOf(-balanceAfter, 0L)

    val period: ClosedRange<LocalDate>?
        get() = recurring.billingPeriod(paidOn = date)

    val month: YearMonth
        get() = recurring.occurrenceMonth(of = date)

    companion object {
        fun upcoming(
            recurrings: List<Recurring>,
            wallets: List<Wallet>,
            entries: List<Entry>,
            valuations: List<Valuation>,
            adjustments: List<Adjustment>,
            after: LocalDate,
            count: Int = 1,
        ): List<CardBill> {
            val cards = wallets.filter { it.kind == Wallet.Kind.card }.map { it.id }.toSet()
            val tomorrow = after.adding(days = 1)
            val paid = mutableMapOf<Identifier<Wallet>, Long>()

            return recurrings
                .filter { recurring ->
                    recurring.type == Entry.Kind.transfer && recurring.toWalletId in cards
                }
                .flatMap { recurring ->
                    dates(of = recurring, from = tomorrow, count = count).map { recurring to it }
                }
                .sortedBy { it.second }
                .map { (recurring, date) ->
                    val source = recurring.walletId
                    val wallet = wallets.firstOrNull { it.id == source }

                    val recorded = wallet?.balance(
                        with = entries,
                        valuations = valuations,
                        adjustments = adjustments,
                        through = date.adding(days = -1),
                    ) ?: 0L

                    val before = recorded - (paid[source] ?: 0L)

                    val amount = recurring.amount(
                        paidOn = date,
                        entries = entries,
                    )

                    val closing = recurring.billingPeriod(paidOn = date)?.endInclusive
                    val isOpen = closing?.let { after <= it } ?: false

                    paid[source] = (paid[source] ?: 0L) + amount

                    CardBill(
                        recurring = recurring,
                        date = date,
                        amount = amount,
                        balanceBefore = before,
                        isOpen = isOpen,
                    )
                }
        }

        private fun dates(
            of: Recurring,
            from: LocalDate,
            count: Int,
        ): List<LocalDate> {
            val dates = mutableListOf<LocalDate>()
            var cursor = from

            while (dates.size < count) {
                val next = of.nextDate(onOrAfter = cursor) ?: break

                dates.add(next)
                cursor = next.adding(days = 1)
            }

            return dates
        }
    }
}
