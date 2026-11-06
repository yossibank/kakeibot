package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.monthOverview
import com.yossibank.kakeibot.store.queries.methods.monthOverviewUpdates
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import com.yossibank.kakeibot.store.queries.types.PeriodRecurring
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.budgetCarryoverFrom
import com.yossibank.kakeibot.store.support.insertCardBill
import com.yossibank.kakeibot.store.support.insertEntry
import com.yossibank.kakeibot.store.support.setBudget
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.flow.produceIn
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class MonthOverviewTest {
    @Test
    fun sumsMonthAndBudget() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val today = assertNotNull(LocalDate.parse("2026-10-23"))
        val month = assertNotNull(YearMonth.parse("2026-10"))
        val tomorrowDate = today.adding(days = 1)
        val nextMonthDate = today.adding(days = 9)

        val amounts = listOf(
            "2026-09-30" to 999,
            "2026-10-01" to 3000,
            "2026-10-23" to 1200,
        )

        for ((text, amount) in amounts) {
            database.insertEntry(
                amount = amount,
                date = assertNotNull(LocalDate.parse(text)),
                categoryId = options.expenseCategories[0].id,
                walletId = options.wallets[0].id,
                at = now,
            )
        }

        database.setBudget(
            amount = 50000,
            from = month,
        )

        val overview = database.monthOverview(on = today)
        val tomorrow = overview.moved(to = tomorrowDate)
        val nextMonth = overview.moved(to = nextMonthDate)

        assertEquals(4200L, overview.monthExpense)
        assertEquals(1200L, overview.todayExpense)
        assertEquals(45800L, overview.budgetUsage?.remaining)
        assertEquals(0L, tomorrow.todayExpense)
        assertEquals(1200L, tomorrow.yesterdayExpense)
        assertEquals(0L, nextMonth.monthExpense)

        database.close()
    }

    @Test
    fun addsCarryoverToBudgetUsage() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val today = assertNotNull(LocalDate.parse("2026-10-23"))
        val month = assertNotNull(YearMonth.parse("2026-09"))
        val start = assertNotNull(YearMonth.parse("2026-09"))

        database.insertEntry(
            amount = 12000,
            date = assertNotNull(LocalDate.parse("2026-09-10")),
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            at = now,
        )

        database.setBudget(
            amount = 50000,
            from = month,
        )

        database.setSetting(
            key = SettingKey.budgetCarryoverFrom,
            to = start,
        )

        val overview = database.monthOverview(on = today)
        val usage = assertNotNull(overview.budgetUsage)

        assertEquals(38000L, usage.carryover)
        assertEquals(50000, usage.baseBudget)
        assertEquals(88000L, usage.budget)
        assertEquals(88000L, usage.remaining)

        database.close()
    }

    @Test
    fun hasNoCarryoverWithoutStart() = runTest {
        val database = AppDatabase.inMemory()
        val today = assertNotNull(LocalDate.parse("2026-10-23"))
        val month = assertNotNull(YearMonth.parse("2026-09"))

        database.setBudget(
            amount = 50000,
            from = month,
        )

        val overview = database.monthOverview(on = today)
        val usage = assertNotNull(overview.budgetUsage)

        assertEquals(0L, usage.carryover)
        assertEquals(50000L, usage.budget)

        database.close()
    }

    @Test
    fun publishesSameOverviewAsOneRead() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val today = assertNotNull(LocalDate.parse("2026-10-23"))
        val month = assertNotNull(YearMonth.parse("2026-10"))

        database.insertEntry(
            amount = 1200,
            date = today,
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            at = now,
        )

        database.setBudget(
            amount = 50000,
            from = month,
        )

        val updates = database.monthOverviewUpdates(on = today).produceIn(backgroundScope)
        val first = updates.receive()
        val read = database.monthOverview(on = today)

        assertEquals(read, first)
        assertEquals(48800L, first.budgetUsage?.remaining)

        database.setBudget(
            amount = 60000,
            from = month,
        )

        val next = updates.receive()

        assertEquals(58800L, next.budgetUsage?.remaining)

        database.close()
    }

    @Test
    fun treatsUngeneratedRecurringOfTodayAsUpcoming() {
        val today = assertNotNull(LocalDate.parse("2026-10-23"))
        val yesterday = today.adding(days = -1)

        val ungenerated = overview(
            generatedUntil = yesterday,
            today = today,
        )

        val neverGenerated = overview(
            generatedUntil = null,
            today = today,
        )

        val deleted = overview(
            generatedUntil = today,
            today = today,
        )

        assertEquals(listOf(PeriodRecurring.Status.upcoming), ungenerated.periodRecurrings.map { it.status })
        assertEquals(today, ungenerated.nextRecurringExpense?.date)
        assertEquals(listOf(PeriodRecurring.Status.upcoming), neverGenerated.periodRecurrings.map { it.status })
        assertEquals(listOf(PeriodRecurring.Status.missing), deleted.periodRecurrings.map { it.status })
        assertNull(deleted.nextRecurringExpense)
    }

    @Test
    fun billsCardUsageAndKeepsRecordedAmounts() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val bill = database.insertCardBill(now)
        val card = assertNotNull(bill.toWalletId)
        val used = assertNotNull(LocalDate.parse("2026-10-10"))
        val today = assertNotNull(LocalDate.parse("2026-10-17"))
        val billDate = assertNotNull(LocalDate.parse("2026-10-27"))

        database.insertEntry(
            amount = 5000,
            date = used,
            categoryId = options.expenseCategories[0].id,
            walletId = card,
            at = now,
        )

        val overview = database.monthOverview(on = today)
        val moved = overview.moved(to = billDate.adding(days = 1))

        assertEquals(listOf(billDate), overview.periodRecurrings.map { it.date })
        assertEquals(listOf(5000L), overview.periodRecurrings.map { it.amount })
        assertEquals(listOf(PeriodRecurring.Status.upcoming), overview.periodRecurrings.map { it.status })
        assertEquals(listOf(PeriodRecurring.Status.missing), moved.periodRecurrings.map { it.status })

        database.close()
    }
}

private fun overview(
    generatedUntil: LocalDate?,
    today: LocalDate,
): MonthOverview {
    val now = Instant.ofEpochSecond(1_791_000_000)

    val recurring = Recurring(
        type = Entry.Kind.expense,
        amount = 5000,
        categoryId = Identifier(),
        walletId = Identifier(),
        frequency = Recurring.Frequency.monthly,
        day = 23,
        startDate = assertNotNull(LocalDate.parse("2026-01-01")),
        generatedUntil = generatedUntil,
        createdAt = now,
        updatedAt = now,
    )

    return MonthOverview(
        list = null,
        budgets = emptyList(),
        recurrings = listOf(recurring),
        monthStartDay = MonthStartDay.first,
        today = today,
    )
}
