package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.WalletDraft
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.restoreEntries
import com.yossibank.kakeibot.store.writes.methods.save
import com.yossibank.kakeibot.store.writes.types.WalletTable
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class CardBillRecalcWriteRecurringTest {
    @Test
    fun countsGeneratedTransferAndFeeInBill() = runTest {
        val setup = CardBillRecalcWriteTest.Setup.make(usage = emptyList())
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
        val setup = CardBillRecalcWriteTest.Setup.make(usage = listOf(10000))
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
        val setup = CardBillRecalcWriteTest.Setup.make(usage = listOf(10000))
        val bill = assertNotNull(setup.bill())
        val movedDate = assertNotNull(LocalDate.parse("2026-11-12"))

        setup.database.deleteEntry(bill.id, at = Instant.now())

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

        setup.database.restoreEntries(listOf(moved), at = Instant.now())
        setup.database.restoreEntries(listOf(bill), at = Instant.now())
        val bills = setup.bills()

        assertEquals(1, bills.size)
        assertEquals(bill.id, bills.firstOrNull()?.id)

        setup.database.close()
    }

    @Test
    fun recalculatesBillOfCardPayingAnotherCard() = runTest {
        val setup = CardBillRecalcWriteTest.Setup.make(usage = emptyList())
        val startDate = assertNotNull(LocalDate.parse("2026-11-01"))
        val through = assertNotNull(LocalDate.parse("2026-11-30"))

        val draft = WalletDraft(
            kind = Wallet.Kind.card,
            name = "払う側のカード",
            mark = IconDraft.Mark.Glyph(Icon.Glyph.bank),
            color = "#4A6FA5",
            initialBalance = 0,
        )

        val payer = setup.database.save(WalletTable, draft, at = setup.now)

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
}
