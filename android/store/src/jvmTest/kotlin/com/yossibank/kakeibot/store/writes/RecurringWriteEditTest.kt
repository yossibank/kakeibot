package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.writes.methods.RecurringWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import com.yossibank.kakeibot.store.writes.methods.reorderRecurrings
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RecurringWriteEditTest {
    @Test
    fun savesAndGeneratesUpToToday() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val start = assertNotNull(LocalDate.parse("2026-02-01"))
        val today = assertNotNull(LocalDate.parse("2026-03-31"))

        val draft = RecurringDraft(
            type = Entry.Kind.income,
            amount = 280_000,
            categoryId = options.incomeCategories[0].id,
            walletId = options.wallets[1].id,
            memo = "給料",
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = 25,
            startDate = start,
        )

        val saved = setup.database.saveRecurring(
            draft,
            today = today,
            at = setup.now,
        )

        val incomes = setup.database.snapshot().entries.filter { it.recurringId == saved.id }

        assertEquals(2, incomes.size)
        assertEquals(today, saved.generatedUntil)

        setup.database.close()
    }

    @Test
    fun generatesTransferBetweenWallets() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val today = assertNotNull(LocalDate.parse("2026-01-26"))

        setup.database.markNoSpendDay(
            today,
            at = setup.now,
        )

        val draft = RecurringDraft(
            type = Entry.Kind.transfer,
            amount = 30000,
            categoryId = null,
            walletId = options.wallets[1].id,
            toWalletId = options.wallets[0].id,
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = 26,
            startDate = today,
        )

        val saved = setup.database.saveRecurring(
            draft,
            today = today,
            at = setup.now,
        )

        val snapshot = setup.database.snapshot()
        val transfers = snapshot.entries.filter { it.recurringId == saved.id }

        assertEquals(listOf(Entry.Kind.transfer), transfers.map { it.type })
        assertEquals(options.wallets[0].id, transfers.firstOrNull()?.toWalletId)
        assertEquals(null, transfers.firstOrNull()?.categoryId)
        assertEquals(listOf(today), snapshot.noSpendDays.map { it.date })

        setup.database.close()
    }

    @Test
    fun addsAtEndAndReorders() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val start = assertNotNull(LocalDate.parse("2026-02-01"))

        val draft = RecurringDraft(
            type = Entry.Kind.expense,
            amount = 4800,
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = 1,
            startDate = start,
        )

        val added = setup.database.saveRecurring(
            draft,
            today = start,
            at = setup.now,
        )

        val before = setup.database.recurrings().map { it.id }

        setup.database.reorderRecurrings(
            before.reversed(),
            at = setup.now,
        )

        val after = setup.database.recurrings().map { it.id }

        assertEquals(1, added.sortOrder)
        assertEquals(added.id, before.last())
        assertEquals(before.reversed(), after)

        setup.database.close()
    }

    @Test
    fun deletesRecurringButKeepsEntries() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-02-28"))

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val id = assertNotNull(setup.database.snapshot().recurrings.firstOrNull()?.id)

        val deletion = setup.database.deleteRecurring(
            id,
            at = setup.now,
        )

        val snapshot = setup.database.snapshot()
        setup.database.restore(deletion)
        val restored = setup.database.snapshot()

        assertTrue(snapshot.recurrings.isEmpty())
        assertEquals(2, snapshot.entries.size)
        assertTrue(snapshot.entries.all { it.recurringId == null })
        assertEquals(listOf(id), restored.recurrings.map { it.id })
        assertTrue(restored.entries.all { it.recurringId == id })

        setup.database.close()
    }

    @Test
    fun touchesUpdatedAtOfLinkedEntriesOnDelete() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-02-28"))
        val later = setup.now.plusSeconds(60)

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val id = assertNotNull(setup.database.snapshot().recurrings.firstOrNull()?.id)

        setup.database.deleteRecurring(
            id,
            at = later,
        )

        val entries = setup.database.snapshot().entries

        assertFalse(entries.isEmpty())
        assertTrue(entries.all { it.updatedAt == later })

        setup.database.close()
    }

    @Test
    fun restoresRemainingEntriesWhenOneIsGone() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val today = assertNotNull(LocalDate.parse("2026-02-28"))

        setup.database.generateRecurringEntries(
            through = today,
            at = setup.now,
        )

        val id = assertNotNull(setup.database.snapshot().recurrings.firstOrNull()?.id)
        val ids = setup.database.snapshot().entries.map { it.id }
        val gone = ids.first()
        val kept = ids.last()

        val deletion = setup.database.deleteRecurring(
            id,
            at = setup.now,
        )

        setup.database.deleteEntry(gone)
        setup.database.restore(deletion)
        val restored = setup.database.snapshot()

        assertEquals(listOf(id), restored.recurrings.map { it.id })
        assertEquals(listOf(kept), restored.entries.map { it.id })
        assertTrue(restored.entries.all { it.recurringId == id })

        setup.database.close()
    }

    @Test
    fun rejectsUnknownRecurring() = runTest {
        val setup = RecurringWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val start = assertNotNull(LocalDate.parse("2026-02-01"))

        val draft = RecurringDraft(
            type = Entry.Kind.expense,
            amount = 4800,
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = 10,
            startDate = start,
        )

        assertFailsWith<RecurringWriteException> {
            setup.database.saveRecurring(
                draft,
                editing = Identifier(),
                today = start,
                at = setup.now,
            )
        }

        setup.database.close()
    }
}
