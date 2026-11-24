package com.yossibank.kakeibot.features.support

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.WalletDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.save
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.types.WalletTable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.test.TestResult
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import java.time.Instant

class ModelTestSetup(
    val database: AppDatabase,
    val today: LocalDate,
    val scope: CoroutineScope,
) {
    val now: Instant = ModelTestDatabase.now

    suspend fun options(): EntryOptions = database.entryOptions()

    suspend fun save(
        type: Entry.Kind,
        amount: Int,
        on: LocalDate,
        memo: String = "",
        categoryId: Identifier<EntryCategory>? = null,
        walletId: Identifier<Wallet>? = null,
        toWalletId: Identifier<Wallet>? = null,
        billMonth: YearMonth? = null,
        items: List<EntryItem.Draft>? = null,
    ): Entry {
        val options = options()
        val categories = if (type ==
            Entry.Kind.income
        ) {
            options.incomeCategories
        } else {
            options.expenseCategories
        }
        val category = if (type ==
            Entry.Kind.transfer
        ) {
            null
        } else {
            categoryId ?: categories.first().id
        }
        val count = database.entryList().days.sumOf { it.entries.size }

        val draft = EntryDraft(
            type = type,
            amount = amount,
            date = on,
            categoryId = category,
            walletId = walletId ?: options.wallets[0].id,
            toWalletId = toWalletId,
            memo = memo,
            billMonth = billMonth,
            items = items,
        )

        return database.saveEntry(draft, at = now.plusSeconds(count.toLong()))
    }

    suspend fun save(
        type: Entry.Kind,
        amount: Int,
        daysAgo: Int,
        memo: String = "",
    ): Entry = save(
        type = type,
        amount = amount,
        on = today.adding(days = -daysAgo),
        memo = memo,
    )

    suspend fun saveRecurring(
        amount: Int,
        day: Int,
        start: LocalDate = date("2026-10-01"),
        memo: String = "",
    ): Recurring {
        val options = options()

        val draft = RecurringDraft(
            type = Entry.Kind.expense,
            amount = amount,
            categoryId = options.expenseCategories.first().id,
            walletId = options.wallets.first().id,
            memo = memo,
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = day,
            startDate = start,
        )

        return database.saveRecurring(draft, today = today, at = now)
    }

    suspend fun addWallet(
        kind: Wallet.Kind,
        name: String,
        initialBalance: Int = 0,
    ): Wallet {
        val draft = WalletDraft(
            kind = kind,
            name = name,
            mark = IconDraft.Mark.Text(name.take(1)),
            color = "#4A6FA5",
            initialBalance = initialBalance,
        )

        return database.save(WalletTable, draft, at = now)
    }

    companion object {
        fun date(text: String): LocalDate = checkNotNull(LocalDate.parse(text))

        fun month(text: String): YearMonth = checkNotNull(YearMonth.parse(text))
    }
}

fun modelTest(
    today: String,
    body: suspend TestScope.(ModelTestSetup) -> Unit,
): TestResult = runTest {
    val setup = ModelTestSetup(
        database = ModelTestDatabase.open(),
        today = ModelTestSetup.date(today),
        scope = backgroundScope,
    )

    try {
        body(setup)
    } finally {
        backgroundScope.coroutineContext[Job]?.cancelChildren()
        setup.database.close()
    }
}
