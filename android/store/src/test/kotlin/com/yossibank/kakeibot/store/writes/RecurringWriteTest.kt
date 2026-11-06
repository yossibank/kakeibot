package com.yossibank.kakeibot.store.writes

import androidx.room.useWriterConnection
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.billMonth
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.support.insertCardBill
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import com.yossibank.kakeibot.store.writes.methods.recordRecurring
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecurringWriteTest {
    @Test
    fun generatesMissingEntriesOnce() = runTest {
        val setup = Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-04-30"))

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val snapshot = setup.database.snapshot()
        val dates = snapshot.entries.mapNotNull { it.recurringDate }
        val generated = snapshot.recurrings.firstOrNull()?.generatedUntil

        assertEquals(
            listOf(
                "2026-01-25",
                "2026-02-25",
                "2026-03-25",
                "2026-04-25",
            ),
            dates.sorted().map { it.toString() },
        )

        assertTrue(snapshot.entries.all { it.amount == 78000 })
        assertEquals(today, generated)

        setup.database.close()
    }

    @Test
    fun skipsWritingWhenNothingChanged() = runTest {
        val setup = Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-04-30"))

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val before = setup.database.totalChanges()

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val after = setup.database.totalChanges()

        assertEquals(before, after)

        setup.database.close()
    }

    @Test
    fun paysCardUsageUntilClosingDay() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()
        val bank = options.wallets[0].id
        val card = options.wallets[1].id
        val category = options.expenseCategories[0].id
        val paidOn = assertNotNull(LocalDate.parse("2026-11-10"))

        val usage = listOf(
            "2026-09-15" to 7000,
            "2026-09-16" to 30000,
            "2026-10-15" to 12000,
            "2026-10-16" to 9000,
        )

        val entries = usage.map { (date, amount) ->
            Entry(
                type = Entry.Kind.expense,
                amount = amount,
                date = assertNotNull(LocalDate.parse(date)),
                categoryId = category,
                walletId = card,
                createdAt = setup.now,
                updatedAt = setup.now,
            )
        }

        val late = Entry(
            type = Entry.Kind.expense,
            amount = 500,
            date = assertNotNull(LocalDate.parse("2026-08-20")),
            categoryId = category,
            walletId = card,
            billMonth = paidOn.yearMonth,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        val bill = Recurring(
            type = Entry.Kind.transfer,
            amount = 0,
            categoryId = null,
            walletId = bank,
            toWalletId = card,
            frequency = Recurring.Frequency.monthly,
            day = 10,
            closingDay = 15,
            startDate = assertNotNull(LocalDate.parse("2026-11-01")),
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.write {
            for (entry in entries + late) {
                setup.database.entryDao().insert(entry.record())
            }

            setup.database.recurringDao().insert(bill.record())
        }

        setup.database.generateRecurringEntries(
            through = paidOn,
            at = setup.now,
        )

        val payment = setup.database.snapshot().entries.firstOrNull { it.recurringId == bill.id }

        assertEquals(42500, payment?.amount)
        assertEquals(paidOn, payment?.date)

        setup.database.close()
    }

    @Test
    fun recordsOneEntryOnRequestedDate() = runTest {
        val setup = Setup.make()
        val recurring = assertNotNull(setup.database.recurrings().firstOrNull())
        val date = assertNotNull(LocalDate.parse("2026-03-25"))

        val first = setup.database.recordRecurring(
            recurring.id,
            on = date,
            at = setup.now,
        )

        val second = setup.database.recordRecurring(
            recurring.id,
            on = date,
            at = setup.now,
        )

        assertEquals(date, first?.recurringDate)
        assertNull(second)
        assertEquals(1, setup.database.snapshot().entries.size)

        setup.database.close()
    }

    @Test
    fun continuesFromGeneratedDate() = runTest {
        val setup = Setup.make()
        val march = assertNotNull(LocalDate.parse("2026-03-01"))
        val may = assertNotNull(LocalDate.parse("2026-05-31"))

        setup.database.generateRecurringEntries(
            through = march,
            at = setup.now,
        )

        val first = setup.database.snapshot().entries.size

        setup.database.generateRecurringEntries(
            through = may,
            at = setup.now,
        )

        val second = setup.database.snapshot().entries.size

        assertEquals(2, first)
        assertEquals(5, second)

        setup.database.close()
    }

    @Test
    fun clearsNoSpendDayOfExpense() = runTest {
        val setup = Setup.make()
        val payday = assertNotNull(LocalDate.parse("2026-01-25"))

        setup.database.markNoSpendDay(
            payday,
            at = setup.now,
        )

        setup.database.generateRecurringEntries(
            through = payday,
            at = setup.now,
        )

        val snapshot = setup.database.snapshot()

        assertTrue(snapshot.noSpendDays.isEmpty())
        assertEquals(1, snapshot.entries.size)

        setup.database.close()
    }

    @Test
    fun recordsShiftedBillMonthOfCardRecurring() = runTest {
        val setup = Setup.make()
        val bill = setup.database.insertCardBill(at = setup.now)
        val options = setup.database.entryOptions()
        val start = assertNotNull(LocalDate.parse("2026-01-01"))
        val today = assertNotNull(LocalDate.parse("2026-02-28"))

        val subscription = Recurring(
            type = Entry.Kind.expense,
            amount = 1200,
            categoryId = options.expenseCategories[0].id,
            walletId = assertNotNull(bill.toWalletId),
            frequency = Recurring.Frequency.monthly,
            day = 20,
            billShift = 1,
            startDate = start,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.recurringDao().insert(subscription.record())

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val all = setup.database.snapshot().entries
        val entries = all.filter { it.recurringId == subscription.id }

        assertFalse(entries.isEmpty())
        assertTrue(entries.all { it.billMonth != null })

        assertTrue(
            entries.all {
                it.billMonth == bill.billMonth(
                    used = it.date,
                    shift = 1,
                )
            },
        )

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
    ) {
        suspend fun changeDay(to: Int) {
            update { it.copy(day = to, generatedUntil = null) }
        }

        suspend fun change(
            day: Int,
            shift: HolidayShift,
        ) {
            update { it.copy(day = day, holidayShift = shift) }
        }

        suspend fun shiftHoliday(to: HolidayShift) {
            update { it.copy(holidayShift = to) }
        }

        private suspend fun update(change: (Recurring) -> Recurring) {
            database.write {
                val recurrings = database.recurringDao().all().map { it.decoded(RecurringRecord::recurring) }

                for (recurring in recurrings) {
                    database.recurringDao().update(change(recurring).record())
                }
            }
        }

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)
                val start = assertNotNull(LocalDate.parse("2026-01-01"))

                database.insertDefaultsIfEmpty(now)

                val options = database.entryOptions()

                val recurring = Recurring(
                    type = Entry.Kind.expense,
                    amount = 78000,
                    categoryId = options.expenseCategories[0].id,
                    walletId = options.wallets[0].id,
                    frequency = Recurring.Frequency.monthly,
                    day = 25,
                    startDate = start,
                    createdAt = now,
                    updatedAt = now,
                )

                database.recurringDao().insert(recurring.record())

                return Setup(
                    database = database,
                    now = now,
                )
            }
        }
    }
}

private suspend fun AppDatabase.totalChanges(): Long = useWriterConnection { connection ->
    connection.usePrepared("SELECT total_changes()") { statement ->
        statement.step()
        statement.getLong(0)
    }
}
