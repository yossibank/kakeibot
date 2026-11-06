package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.noSpendDayUpdates
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.writes.methods.NoSpendDayError
import com.yossibank.kakeibot.store.writes.methods.NoSpendDayException
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDays
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.unmarkNoSpendDay
import kotlinx.coroutines.flow.produceIn
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull

class NoSpendDayWriteTest {
    @Test
    fun marksAndUnmarksDay() = runTest {
        val setup = Setup.make()
        val updates = setup.database.noSpendDayUpdates().produceIn(backgroundScope)

        val initial = updates.receive()

        setup.database.markNoSpendDay(
            setup.date,
            at = setup.now,
        )

        val marked = updates.receive()
        setup.database.unmarkNoSpendDay(setup.date)
        val unmarked = updates.receive()

        assertEquals(emptySet(), initial)
        assertEquals(setOf(setup.date), marked)
        assertEquals(emptySet(), unmarked)

        setup.database.close()
    }

    @Test
    fun marksSeveralDays() = runTest {
        val setup = Setup.make()
        val next = setup.date.adding(days = 1)

        setup.database.markNoSpendDays(
            listOf(setup.date, next),
            at = setup.now,
        )

        val snapshot = setup.database.snapshot()

        assertEquals(listOf(setup.date, next), snapshot.noSpendDays.map { it.date })

        setup.database.close()
    }

    @Test
    fun rejectsDayWithExpense() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()

        val draft = EntryDraft(
            type = Entry.Kind.expense,
            amount = 980,
            date = setup.date,
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            memo = "",
        )

        setup.database.saveEntry(draft, at = setup.now)

        val error = assertFailsWith<NoSpendDayException> {
            setup.database.markNoSpendDay(
                setup.date,
                at = setup.now,
            )
        }

        assertEquals(NoSpendDayError.hasExpense, error.error)

        setup.database.close()
    }

    @Test
    fun marksDayWithOnlyIncome() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()

        val draft = EntryDraft(
            type = Entry.Kind.income,
            amount = 3000,
            date = setup.date,
            categoryId = options.incomeCategories[0].id,
            walletId = options.wallets[0].id,
            memo = "",
        )

        setup.database.saveEntry(draft, at = setup.now)

        setup.database.markNoSpendDay(
            setup.date,
            at = setup.now,
        )

        val snapshot = setup.database.snapshot()

        assertEquals(listOf(setup.date), snapshot.noSpendDays.map { it.date })

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val date: LocalDate,
    ) {
        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)
                val date = assertNotNull(LocalDate.parse("2026-10-03"))

                database.insertDefaultsIfEmpty(now)

                return Setup(
                    database = database,
                    now = now,
                    date = date,
                )
            }
        }
    }
}
