package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryBatchChange
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.snapshot.replace
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.writes.methods.changeEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.fee
import com.yossibank.kakeibot.store.writes.methods.restoreEntries
import com.yossibank.kakeibot.store.writes.methods.restoreEntry
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class TransferFeeWriteTest {
    @Test
    fun savesFeeAsExpenseOfSourceWallet() = runTest {
        val setup = Setup.make()

        val transfer = setup.database.saveEntry(setup.draft, at = setup.now)
        val fee = assertNotNull(setup.database.fee(of = transfer.id))
        val options = setup.database.entryOptions()
        val category = options.expenseCategories.firstOrNull { it.id == fee.categoryId }

        assertEquals(Entry.Kind.expense, fee.type)
        assertEquals(110, fee.amount)
        assertEquals(transfer.date, fee.date)
        assertEquals(transfer.walletId, fee.walletId)
        assertEquals(transfer.id, fee.transferId)
        assertEquals("手数料", category?.name)

        setup.database.close()
    }

    @Test
    fun reusesFeeCategory() = runTest {
        val setup = Setup.make()

        val first = setup.database.saveEntry(setup.draft, at = setup.now)
        val second = setup.database.saveEntry(setup.draft, at = setup.now)
        val firstFee = setup.database.fee(of = first.id)
        val secondFee = setup.database.fee(of = second.id)
        val options = setup.database.entryOptions()
        val names = options.expenseCategories.map { it.name }.filter { it == "手数料" }

        assertEquals(firstFee?.categoryId, secondFee?.categoryId)
        assertEquals(1, names.size)

        setup.database.close()
    }

    @Test
    fun followsEditedTransfer() = runTest {
        val setup = Setup.make()
        val date = assertNotNull(LocalDate.parse("2026-10-05"))

        val edited = setup.draft.copy(
            fee = 220,
            date = date,
        )

        val transfer = setup.database.saveEntry(setup.draft, at = setup.now)
        val before = setup.database.fee(of = transfer.id)

        setup.database.saveEntry(
            edited,
            editing = transfer.id,
            at = setup.now,
        )

        val after = setup.database.fee(of = transfer.id)

        assertEquals(before?.id, after?.id)
        assertEquals(220, after?.amount)
        assertEquals(date, after?.date)

        setup.database.close()
    }

    @Test
    fun removesFeeWhenCleared() = runTest {
        val setup = Setup.make()
        val edited = setup.draft.copy(fee = 0)

        val transfer = setup.database.saveEntry(setup.draft, at = setup.now)

        setup.database.saveEntry(
            edited,
            editing = transfer.id,
            at = setup.now,
        )

        val snapshot = setup.database.snapshot()

        assertEquals(listOf(transfer.id), snapshot.entries.map { it.id })

        setup.database.close()
    }

    @Test
    fun keepsFeeWalletOnBatchChange() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()

        val transfer = setup.database.saveEntry(setup.draft, at = setup.now)
        val fee = assertNotNull(setup.database.fee(of = transfer.id))

        val changed = setup.database.changeEntries(
            listOf(fee.id),
            to = EntryBatchChange.Wallet(options.wallets[0].id),
            at = setup.now,
        )

        val after = setup.database.fee(of = transfer.id)

        assertTrue(changed.isEmpty())
        assertEquals(transfer.walletId, after?.walletId)

        setup.database.close()
    }

    @Test
    fun recordsFeeWithRecurringTransfer() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()
        val start = assertNotNull(LocalDate.parse("2026-10-03"))

        val draft = RecurringDraft(
            type = Entry.Kind.transfer,
            amount = 10000,
            categoryId = null,
            walletId = options.wallets[1].id,
            toWalletId = options.wallets[0].id,
            frequency = Recurring.Frequency.monthly,
            month = 10,
            day = 3,
            fee = 110,
            startDate = start,
        )

        setup.database.saveRecurring(
            draft,
            today = start,
            at = setup.now,
        )

        val entries = setup.database.snapshot().entries
        val transfer = assertNotNull(entries.firstOrNull { it.type == Entry.Kind.transfer })
        val fee = setup.database.fee(of = transfer.id)

        assertEquals(110, fee?.amount)
        assertEquals(transfer.walletId, fee?.walletId)

        setup.database.close()
    }

    @Test
    fun deletesFeeWithTransfer() = runTest {
        val setup = Setup.make()

        val transfer = setup.database.saveEntry(setup.draft, at = setup.now)
        setup.database.deleteEntry(transfer.id)
        val snapshot = setup.database.snapshot()

        assertTrue(snapshot.entries.isEmpty())

        setup.database.close()
    }

    @Test
    fun restoresDeletedTransferWithFee() = runTest {
        val setup = Setup.make()

        val transfer = setup.database.saveEntry(setup.draft, at = setup.now)
        val fee = setup.database.fee(of = transfer.id)
        setup.database.deleteEntry(transfer.id)

        setup.database.restoreEntry(
            transfer,
            fee = fee,
        )

        val snapshot = setup.database.snapshot()
        val expected = listOfNotNull(transfer, fee).toSet()

        assertEquals(expected, snapshot.entries.toSet())

        setup.database.close()
    }

    @Test
    fun restoringTransferWithoutFeeRemovesAddedFee() = runTest {
        val setup = Setup.make()
        val draft = setup.draft.copy(fee = 0)

        val transfer = setup.database.saveEntry(draft, at = setup.now)

        setup.database.saveEntry(
            setup.draft,
            editing = transfer.id,
            at = setup.now,
        )

        setup.database.restoreEntry(
            transfer,
            fee = null,
        )

        val snapshot = setup.database.snapshot()

        assertEquals(listOf(transfer), snapshot.entries)

        setup.database.close()
    }

    @Test
    fun deletesAndRestoresEntriesWithFees() = runTest {
        val setup = Setup.make()

        val transfer = setup.database.saveEntry(setup.draft, at = setup.now)
        val fee = setup.database.fee(of = transfer.id)
        val deleted = setup.database.deleteEntries(listOf(transfer.id))
        setup.database.restoreEntries(deleted.reversed())
        val snapshot = setup.database.snapshot()
        val expected = listOfNotNull(transfer, fee).toSet()

        assertEquals(expected, deleted.toSet())
        assertEquals(deleted.toSet(), snapshot.entries.toSet())

        setup.database.close()
    }

    @Test
    fun replacesTablesWithFeeBeforeTransfer() = runTest {
        val setup = Setup.make()
        setup.database.saveEntry(setup.draft, at = setup.now)

        val saved = setup.database.snapshot()
        val tables = saved.copy(entries = saved.entries.reversed())
        setup.database.replace(with = tables)
        val snapshot = setup.database.snapshot()

        assertEquals(tables.entries.toSet(), snapshot.entries.toSet())

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val draft: EntryDraft,
    ) {
        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)
                val date = assertNotNull(LocalDate.parse("2026-10-03"))

                database.insertDefaultsIfEmpty(now)

                val options = database.entryOptions()

                val draft = EntryDraft(
                    type = Entry.Kind.transfer,
                    amount = 10000,
                    date = date,
                    categoryId = null,
                    walletId = options.wallets[1].id,
                    toWalletId = options.wallets[0].id,
                    fee = 110,
                )

                return Setup(
                    database = database,
                    now = now,
                    draft = draft,
                )
            }
        }
    }
}
