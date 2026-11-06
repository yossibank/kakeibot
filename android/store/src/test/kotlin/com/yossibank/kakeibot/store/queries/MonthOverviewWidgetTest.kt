package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.setting.TemplateOrder
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.monthOverview
import com.yossibank.kakeibot.store.queries.methods.widgetOverview
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import com.yossibank.kakeibot.store.queries.types.PeriodRecurring
import com.yossibank.kakeibot.store.support.insertCardBill
import com.yossibank.kakeibot.store.support.insertEntry
import com.yossibank.kakeibot.store.support.setBudget
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class MonthOverviewWidgetTest {
    @Test
    fun matchesFullOverviewForTodayAndTomorrow() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val bill = database.insertCardBill(now)
        val card = assertNotNull(bill.toWalletId)
        val today = assertNotNull(LocalDate.parse("2026-10-17"))
        val month = assertNotNull(YearMonth.parse("2026-10"))
        val longAgo = assertNotNull(LocalDate.parse("2025-01-05"))

        val wallets = listOf(
            options.wallets[0].id,
            card,
        )

        for (index in 0 until 120) {
            database.insertEntry(
                amount = 100 + index,
                date = today.adding(days = -index * 6),
                categoryId = options.expenseCategories[0].id,
                walletId = wallets[index % wallets.size],
                at = now,
            )
        }

        database.insertEntry(
            amount = 7000,
            date = longAgo,
            categoryId = options.expenseCategories[0].id,
            walletId = card,
            billMonth = month,
            at = now,
        )

        val recorded = database.insertEntry(
            amount = 300,
            date = longAgo,
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            at = now,
        )

        database.setBudget(
            amount = 50000,
            from = month,
        )

        val full = database.monthOverview(on = today)
        val widget = database.widgetOverview(on = today)

        val including = database.widgetOverview(
            on = today,
            including = recorded.id,
        )

        val days = listOf(
            today,
            today.adding(days = 1),
            today.adding(days = 15),
        )

        for (day in days) {
            val expected = Summary(full.moved(to = day))
            val actual = Summary(widget.moved(to = day))

            assertEquals(expected, actual)
        }

        assertFalse(widget.list?.days.orEmpty().flatMap { it.entries }.contains(recorded))
        assertTrue(including.list?.days.orEmpty().flatMap { it.entries }.contains(recorded))
        assertTrue(widget.list?.days.orEmpty().size < full.list?.days.orEmpty().size)

        database.close()
    }
}

private data class Summary(
    val monthExpense: Long,
    val todayExpense: Long,
    val yesterdayExpense: Long,
    val weekExpense: Long,
    val budgetUsage: BudgetUsage?,
    val periodRecurrings: List<PeriodRecurring>,
    val recentDays: List<EntryDay>,
) {
    constructor(overview: MonthOverview) : this(
        monthExpense = overview.monthExpense,
        todayExpense = overview.todayExpense,
        yesterdayExpense = overview.yesterdayExpense,
        weekExpense = overview.expense(overview.today.week(startingOn = Weekday.sunday)),
        budgetUsage = overview.budgetUsage,
        periodRecurrings = overview.periodRecurrings,
        recentDays = overview.list?.days.orEmpty().filter {
            it.date >= overview.today.adding(days = -TemplateOrder.frequentDays)
        },
    )
}
