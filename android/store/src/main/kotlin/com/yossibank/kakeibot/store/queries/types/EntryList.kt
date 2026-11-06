package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.budget.carryover
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.expenseTotal
import com.yossibank.kakeibot.core.concepts.entry.within
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.balance
import com.yossibank.kakeibot.core.concepts.wallet.entriesByWallet
import com.yossibank.kakeibot.core.shared.Identifier

data class EntryList(
    val days: List<EntryDay>,
    val categories: Map<Identifier<EntryCategory>, EntryCategory>,
    val tags: Map<Identifier<EntryTag>, EntryTag>,
    val wallets: Map<Identifier<Wallet>, Wallet>,
    val valuations: List<Valuation> = emptyList(),
    val adjustments: List<Adjustment> = emptyList(),
    val icons: Map<Identifier<Icon>, Icon>,
    val cardBills: List<Recurring> = emptyList(),
    val items: Map<Identifier<Entry>, List<EntryItem>> = emptyMap(),
) {
    val entries: List<Entry> = days.flatMap { it.entries }

    val entriesByWallet: Map<Identifier<Wallet>, List<Entry>> = Wallet.entriesByWallet(entries)

    fun balance(
        of: Wallet,
        through: LocalDate? = null,
    ): Long = of.balance(
        with = entriesByWallet[of.id].orEmpty(),
        valuations = valuations,
        adjustments = adjustments,
        through = through,
    )

    fun budgetCarryover(
        budgets: List<Budget>,
        from: YearMonth?,
        into: YearMonth,
        startingOn: MonthStartDay,
    ): Long = budgets.carryover(
        into = into,
        from = from,
    ) { month ->
        val period = month.period(startingOn = startingOn)

        days.within(period).expenseTotal
    }
}

data class EntryOptions(
    val expenseCategories: List<EntryCategory>,
    val incomeCategories: List<EntryCategory>,
    val tags: List<EntryTag>,
    val wallets: List<Wallet>,
    val icons: Map<Identifier<Icon>, Icon>,
    val sharedCategories: List<EntryCategory> = emptyList(),
    val sharedTags: List<EntryTag> = emptyList(),
)
