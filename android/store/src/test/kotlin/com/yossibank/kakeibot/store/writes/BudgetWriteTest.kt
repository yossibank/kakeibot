package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.budget.amount
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.budgets
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.writes.methods.BudgetWriteError
import com.yossibank.kakeibot.store.writes.methods.BudgetWriteException
import com.yossibank.kakeibot.store.writes.methods.setBudget
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class BudgetWriteTest {
    @Test
    fun keepsEarlierMonthsWhenChanged() = runTest {
        val database = AppDatabase.inMemory()
        val january = assertNotNull(YearMonth.of(year = 2026, month = 1))
        val april = assertNotNull(YearMonth.of(year = 2026, month = 4))
        val march = assertNotNull(YearMonth.of(year = 2026, month = 3))

        database.setBudget(
            100_000,
            categoryId = null,
            from = january,
        )

        database.setBudget(
            120_000,
            categoryId = null,
            from = april,
        )

        val budgets = database.budgets()
        val marchAmount = budgets.amount(categoryId = null, month = march)
        val aprilAmount = budgets.amount(categoryId = null, month = april)

        assertEquals(2, budgets.size)
        assertEquals(100_000, marchAmount)
        assertEquals(120_000, aprilAmount)

        database.close()
    }

    @Test
    fun updatesSameMonthAndDropsRedundantRow() = runTest {
        val database = AppDatabase.inMemory()
        val january = assertNotNull(YearMonth.of(year = 2026, month = 1))
        val april = assertNotNull(YearMonth.of(year = 2026, month = 4))

        database.setBudget(
            100_000,
            categoryId = null,
            from = january,
        )

        database.setBudget(
            120_000,
            categoryId = null,
            from = april,
        )

        database.setBudget(
            130_000,
            categoryId = null,
            from = april,
        )

        val updated = database.budgets()

        database.setBudget(
            100_000,
            categoryId = null,
            from = april,
        )

        val restored = database.budgets()
        val updatedAmount = updated.amount(categoryId = null, month = april)
        val restoredAmount = restored.amount(categoryId = null, month = april)

        assertEquals(2, updated.size)
        assertEquals(130_000, updatedAmount)
        assertEquals(1, restored.size)
        assertEquals(100_000, restoredAmount)

        database.close()
    }

    @Test
    fun stopsBudgetFromMonthAndSkipsNoChange() = runTest {
        val database = AppDatabase.inMemory()
        database.insertDefaultsIfEmpty(Instant.now())
        val options = database.entryOptions()
        val category = options.expenseCategories[0].id
        val january = assertNotNull(YearMonth.of(year = 2026, month = 1))
        val july = assertNotNull(YearMonth.of(year = 2026, month = 7))

        database.setBudget(
            null,
            categoryId = null,
            from = january,
        )

        val none = database.budgets()

        database.setBudget(
            30000,
            categoryId = category,
            from = january,
        )

        database.setBudget(
            null,
            categoryId = category,
            from = july,
        )

        val stopped = database.budgets()
        val januaryAmount = stopped.amount(categoryId = category, month = january)
        val julyAmount = stopped.amount(categoryId = category, month = july)
        val totalJulyAmount = stopped.amount(categoryId = null, month = july)

        assertTrue(none.isEmpty())
        assertEquals(30000, januaryAmount)
        assertNull(julyAmount)
        assertNull(totalJulyAmount)

        database.close()
    }

    @Test
    fun rejectsZero() = runTest {
        val database = AppDatabase.inMemory()
        val january = assertNotNull(YearMonth.of(year = 2026, month = 1))

        val error = assertFailsWith<BudgetWriteException> {
            database.setBudget(
                0,
                categoryId = null,
                from = january,
            )
        }

        assertEquals(BudgetWriteError.amountNotPositive, error.error)

        database.close()
    }
}
