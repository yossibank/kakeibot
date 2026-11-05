package com.yossibank.kakeibot.core.concepts.review

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

@ConsistentCopyVisibility
data class ReviewSummary private constructor(
    val expense: Breakdown,
    val income: Breakdown,
) {
    @ConsistentCopyVisibility
    data class Breakdown internal constructor(
        val total: Int,
        val byCategory: Map<Identifier<EntryCategory>, Int>,
        val byWallet: Map<Identifier<Wallet>, Int>,
    ) {
        companion object {
            internal operator fun invoke(entries: List<Entry>): Breakdown {
                val total = entries.sumOf { it.amount }

                val byCategory = mutableMapOf<Identifier<EntryCategory>, Int>()
                val byWallet = mutableMapOf<Identifier<Wallet>, Int>()

                for (entry in entries) {
                    val categoryId = entry.categoryId

                    if (categoryId != null) {
                        byCategory[categoryId] = (byCategory[categoryId] ?: 0) + entry.amount
                    }

                    byWallet[entry.walletId] = (byWallet[entry.walletId] ?: 0) + entry.amount
                }

                return Breakdown(
                    total = total,
                    byCategory = byCategory,
                    byWallet = byWallet,
                )
            }
        }
    }

    val balance: Int
        get() = income.total - expense.total

    fun breakdown(of: Entry.Kind): Breakdown? = when (of) {
        Entry.Kind.expense -> expense
        Entry.Kind.income -> income
        Entry.Kind.transfer -> null
    }

    companion object {
        operator fun invoke(
            entries: List<Entry>,
            range: ClosedRange<LocalDate>,
        ): ReviewSummary {
            val inRange = entries.filter { it.date in range }
            val expenses = inRange.filter { it.type == Entry.Kind.expense }
            val incomes = inRange.filter { it.type == Entry.Kind.income }

            return ReviewSummary(
                expense = Breakdown(expenses),
                income = Breakdown(incomes),
            )
        }
    }
}
