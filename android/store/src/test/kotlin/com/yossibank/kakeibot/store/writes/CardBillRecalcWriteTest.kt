package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryBatchChange
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.WalletDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.writes.methods.changeEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import com.yossibank.kakeibot.store.writes.methods.recordFromWidget
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.restoreEntries
import com.yossibank.kakeibot.store.writes.methods.restoreEntry
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import com.yossibank.kakeibot.store.writes.methods.saveWallet
import com.yossibank.kakeibot.store.writes.methods.undoWidgetEntry
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class CardBillRecalcWriteTest {
    @Test
    fun raisesAndRestoresBillWhenUsageChanges() = runTest {
        val setup = Setup.make(usage = listOf(10000))

        val added = setup.spend(3000, on = "2026-10-05")
        assertEquals(13000, setup.bill()?.amount)

        setup.database.deleteEntry(added.id)
        assertEquals(10000, setup.bill()?.amount)

        setup.database.close()
    }

    @Test
    fun removesBillWhenUsageBecomesZero() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val entry = assertNotNull(setup.database.snapshot().entries.firstOrNull { it.recurringId == null })

        setup.database.deleteEntry(entry.id)

        assertNull(setup.bill())
        assertTrue(setup.database.snapshot().entries.isEmpty())

        setup.database.close()
    }

    @Test
    fun createsBillSkippedAsZero() = runTest {
        val setup = Setup.make(usage = emptyList())
        assertNull(setup.bill())

        setup.spend(4000, on = "2026-10-05")
        val bill = setup.bill()

        assertEquals(4000, bill?.amount)
        assertEquals(LocalDate.parse("2026-11-10"), bill?.date)

        setup.database.close()
    }

    @Test
    fun keepsBillEditedByHand() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val bill = assertNotNull(setup.bill())

        val edited = bill.copy(
            amount = 777,
            updatedAt = bill.updatedAt.plusSeconds(60),
        )

        setup.database.entryDao().update(edited.record())

        setup.spend(3000, on = "2026-10-05")

        assertEquals(777, setup.bill()?.amount)

        setup.database.close()
    }

    @Test
    fun ignoresUsageOutsidePeriodAndOtherWallets() = runTest {
        val setup = Setup.make(usage = listOf(10000))

        setup.spend(3000, on = "2026-10-16")
        setup.spend(3000, on = "2026-09-15")

        setup.spend(
            3000,
            on = "2026-10-05",
            wallet = setup.bank,
        )

        val bill = setup.bill()

        assertEquals(10000, bill?.amount)
        assertEquals(bill?.createdAt, bill?.updatedAt)

        setup.database.close()
    }

    @Test
    fun recalculatesWhenEntryMovesAcrossPeriods() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val entry = setup.spend(3000, on = "2026-10-05")
        assertEquals(13000, setup.bill()?.amount)

        val later = setup.now.plusSeconds(1)
        val draft = EntryDraft(entry).copy(date = assertNotNull(LocalDate.parse("2026-10-20")))

        setup.database.saveEntry(
            draft,
            editing = entry.id,
            at = later,
        )

        assertEquals(10000, setup.bill()?.amount)

        setup.database.close()
    }

    @Test
    fun recalculatesWhenDeletionIsRestored() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val entry = setup.spend(3000, on = "2026-10-05")

        setup.database.deleteEntry(entry.id)
        assertEquals(10000, setup.bill()?.amount)

        setup.database.restoreEntry(entry)
        assertEquals(13000, setup.bill()?.amount)

        setup.database.close()
    }

    @Test
    fun recalculatesForWidgetEntryAndUndo() = runTest {
        val setup = Setup.make(usage = listOf(10000))

        val draft = EntryTemplateDraft(
            name = "カード",
            type = Entry.Kind.expense,
            amount = 2000,
            categoryId = setup.category,
            walletId = setup.card,
        )

        val template = setup.database.saveTemplate(draft, at = setup.now)
        val date = assertNotNull(LocalDate.parse("2026-10-05"))

        val entry = setup.database.recordFromWidget(
            template.id,
            on = date,
            at = setup.now,
        )

        assertEquals(12000, setup.bill()?.amount)

        setup.database.undoWidgetEntry(entry.id)
        assertEquals(10000, setup.bill()?.amount)

        setup.database.close()
    }

    @Test
    fun restoresOneBillAfterBulkDeleteOfUsageAndBill() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val added = setup.spend(3000, on = "2026-10-05")
        val bill = assertNotNull(setup.bill())

        val deleted = setup.database.deleteEntries(listOf(added.id, bill.id))
        assertTrue(setup.bills().isEmpty())

        setup.database.restoreEntries(deleted)
        val bills = setup.bills()

        assertEquals(1, bills.size)
        assertEquals(13000, bills.firstOrNull()?.amount)

        setup.database.close()
    }

    @Test
    fun doesNotRecreateBillDeletedByHand() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val bill = assertNotNull(setup.bill())
        val added = setup.spend(3000, on = "2026-10-05")
        val later = setup.now.plusSeconds(1)

        setup.database.deleteEntry(bill.id)

        setup.database.saveEntry(
            EntryDraft(added).copy(amount = 5000),
            editing = added.id,
            at = later,
        )

        assertTrue(setup.bills().isEmpty())

        setup.database.close()
    }

    @Test
    fun restoresBillRemovedWithAllUsage() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val usage = assertNotNull(setup.database.snapshot().entries.firstOrNull { it.recurringId == null })

        val deleted = setup.database.deleteEntries(listOf(usage.id))
        assertTrue(setup.bills().isEmpty())

        setup.database.restoreEntries(deleted)
        val bills = setup.bills()

        assertEquals(1, bills.size)
        assertEquals(10000, bills.firstOrNull()?.amount)

        setup.database.close()
    }

    @Test
    fun restoresBillOfPreviousWalletOnUndo() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val startDate = assertNotNull(LocalDate.parse("2026-11-01"))
        val through = assertNotNull(LocalDate.parse("2026-11-10"))
        val later = setup.now.plusSeconds(1)

        val other = Recurring(
            type = Entry.Kind.transfer,
            amount = 0,
            categoryId = null,
            walletId = setup.card,
            toWalletId = setup.bank,
            frequency = Recurring.Frequency.monthly,
            day = 10,
            closingDay = 15,
            startDate = startDate,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.recurringDao().insert(other.record())

        setup.database.generateRecurringEntries(
            through = through,
            at = setup.now,
        )

        val usage = assertNotNull(setup.database.snapshot().entries.firstOrNull { it.recurringId == null })

        val previous = setup.database.changeEntries(
            listOf(usage.id),
            to = EntryBatchChange.Wallet(setup.bank),
            at = later,
        )

        assertNull(setup.bill())
        assertEquals(10000, setup.bill(of = other.id)?.amount)

        setup.database.restoreEntries(previous)

        assertEquals(10000, setup.bill()?.amount)
        assertNull(setup.bill(of = other.id))

        setup.database.close()
    }

    @Test
    fun countsGeneratedTransferAndFeeInBill() = runTest {
        val setup = Setup.make(usage = emptyList())
        val startDate = assertNotNull(LocalDate.parse("2026-10-05"))
        val through = assertNotNull(LocalDate.parse("2026-11-10"))

        val transfer = Recurring(
            type = Entry.Kind.transfer,
            amount = 5000,
            categoryId = null,
            walletId = setup.card,
            toWalletId = setup.bank,
            frequency = Recurring.Frequency.monthly,
            day = 5,
            fee = 110,
            startDate = startDate,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.recurringDao().insert(transfer.record())

        setup.database.generateRecurringEntries(
            through = through,
            at = setup.now,
        )

        assertEquals(5110, setup.bill()?.amount)

        setup.database.close()
    }

    @Test
    fun keepsBillWhenDeletedRecurringIsRestored() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val startDate = assertNotNull(LocalDate.parse("2026-10-01"))
        val through = assertNotNull(LocalDate.parse("2026-11-10"))

        val expense = Recurring(
            type = Entry.Kind.expense,
            amount = 2000,
            categoryId = setup.category,
            walletId = setup.card,
            frequency = Recurring.Frequency.monthly,
            day = 1,
            startDate = startDate,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.recurringDao().insert(expense.record())

        setup.database.generateRecurringEntries(
            through = through,
            at = setup.now,
        )

        assertEquals(12000, setup.bill()?.amount)

        val deletion = setup.database.deleteRecurring(
            expense.id,
            at = setup.now,
        )

        setup.updateBill { it.copy(closingDay = 1) }

        setup.database.restore(deletion)

        assertEquals(12000, setup.bill()?.amount)

        setup.database.close()
    }

    @Test
    fun replacesBillRecordedOnAnotherDayOfSameMonth() = runTest {
        val setup = Setup.make(usage = listOf(10000))
        val bill = assertNotNull(setup.bill())
        val movedDate = assertNotNull(LocalDate.parse("2026-11-12"))

        setup.database.deleteEntry(bill.id)

        val moved = Entry(
            type = Entry.Kind.transfer,
            amount = 999,
            date = movedDate,
            categoryId = null,
            walletId = setup.bank,
            toWalletId = setup.card,
            recurringId = setup.recurringId,
            recurringDate = movedDate,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.restoreEntries(listOf(moved))
        setup.database.restoreEntries(listOf(bill))
        val bills = setup.bills()

        assertEquals(1, bills.size)
        assertEquals(bill.id, bills.firstOrNull()?.id)

        setup.database.close()
    }

    @Test
    fun recalculatesBillOfCardPayingAnotherCard() = runTest {
        val setup = Setup.make(usage = emptyList())
        val startDate = assertNotNull(LocalDate.parse("2026-11-01"))
        val through = assertNotNull(LocalDate.parse("2026-11-30"))

        val draft = WalletDraft(
            kind = Wallet.Kind.card,
            name = "払う側のカード",
            mark = IconDraft.Mark.Glyph(Icon.Glyph.bank),
            color = "#4A6FA5",
            initialBalance = 0,
        )

        val payer = setup.database.saveWallet(draft, at = setup.now)

        val payerBill = Recurring(
            type = Entry.Kind.transfer,
            amount = 0,
            categoryId = null,
            walletId = setup.bank,
            toWalletId = payer.id,
            frequency = Recurring.Frequency.monthly,
            day = 25,
            closingDay = 10,
            startDate = startDate,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.write {
            setup.updateBill { it.copy(walletId = payer.id) }
            setup.database.recurringDao().insert(payerBill.record())
        }

        setup.spend(10000, on = "2026-10-01")

        setup.database.generateRecurringEntries(
            through = through,
            at = setup.now,
        )

        assertEquals(10000, setup.bill()?.amount)
        assertEquals(10000, setup.bill(of = payerBill.id)?.amount)

        setup.spend(3000, on = "2026-10-05")
        assertEquals(13000, setup.bill()?.amount)
        assertEquals(13000, setup.bill(of = payerBill.id)?.amount)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val bank: Identifier<Wallet>,
        val card: Identifier<Wallet>,
        val category: Identifier<EntryCategory>,
        val recurringId: Identifier<Recurring>,
    ) {
        suspend fun updateBill(change: (Recurring) -> Recurring) {
            val stored = database.recurringDao().find(recurringId.databaseValue)
            val bill = assertNotNull(stored).decoded(RecurringRecord::recurring)

            database.recurringDao().update(change(bill).record())
        }

        companion object
    }
}
