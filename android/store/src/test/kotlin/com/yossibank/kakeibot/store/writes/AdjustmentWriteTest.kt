package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.WalletDraft
import com.yossibank.kakeibot.core.concepts.wallet.balance
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.monthOverview
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.writes.methods.deleteAdjustment
import com.yossibank.kakeibot.store.writes.methods.deleteWallet
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveAdjustment
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveWallet
import com.yossibank.kakeibot.store.writes.types.DeletionSubject
import com.yossibank.kakeibot.store.writes.types.subject
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AdjustmentWriteTest {
    @Test
    fun movesBalanceWithoutEntries() = runTest {
        val setup = Setup.make()

        setup.addExpense(3000)
        setup.adjust(-1200)
        val list = setup.database.entryList()
        val entries = setup.entries(list)

        val balance = setup.wallet.balance(
            with = entries,
            adjustments = list.adjustments,
        )

        assertEquals(listOf(-1200L), list.adjustments.map { it.amount })
        assertEquals(1, entries.size)
        assertEquals(listOf(3000L), list.days.map { it.expenseTotal })
        assertEquals(setup.wallet.initialBalance - 4200L, balance)

        setup.database.close()
    }

    @Test
    fun savesNothingForZero() = runTest {
        val setup = Setup.make()

        val adjustment = setup.adjust(0)
        val list = setup.database.entryList()

        assertNull(adjustment)
        assertTrue(list.adjustments.isEmpty())

        setup.database.close()
    }

    @Test
    fun restoresDeletedAdjustment() = runTest {
        val setup = Setup.make()
        setup.adjust(500)
        val saved = setup.database.entryList().adjustments
        val id = saved[0].id

        val deletion = assertNotNull(setup.database.deleteAdjustment(id))
        val deleted = setup.database.entryList().adjustments
        setup.database.restore(deletion)
        val restored = setup.database.entryList().adjustments

        assertEquals(DeletionSubject.Kind.adjustment, deletion.subject?.kind)
        assertTrue(deleted.isEmpty())
        assertEquals(saved, restored)

        setup.database.close()
    }

    @Test
    fun returnsNoDeletionForMissingAdjustment() = runTest {
        val setup = Setup.make()

        val deletion = setup.database.deleteAdjustment(Identifier<Adjustment>())

        assertNull(deletion)

        setup.database.close()
    }

    @Test
    fun keepsMonthTotals() = runTest {
        val setup = Setup.make()
        setup.addExpense(3000)
        val before = setup.database.monthOverview(on = setup.day)

        setup.adjust(-5000)
        setup.adjust(8000)
        val after = setup.database.monthOverview(on = setup.day)

        assertEquals(before.monthExpense, after.monthExpense)
        assertEquals(before.monthIncome, after.monthIncome)
        assertEquals(before.todayExpense, after.todayExpense)
        assertEquals(before.list?.days, after.list?.days)

        setup.database.close()
    }

    @Test
    fun deletesAndRestoresWithWallet() = runTest {
        val setup = Setup.make()

        val draft = WalletDraft(
            kind = Wallet.Kind.cash,
            name = "封筒",
            mark = IconDraft.Mark.Text("封"),
            color = "#BF4040",
            initialBalance = 0,
        )

        val wallet = setup.database.saveWallet(draft, at = setup.now)

        setup.database.saveAdjustment(
            700,
            of = wallet.id,
            on = setup.day,
            at = setup.now,
        )

        val deletion = setup.database.deleteWallet(
            wallet.id,
            at = setup.now,
        )

        val deleted = setup.database.entryList().adjustments
        setup.database.restore(deletion)
        val restored = setup.database.entryList().adjustments

        assertTrue(deleted.isEmpty())
        assertEquals(listOf(wallet.id), restored.map { it.walletId })

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val wallet: Wallet,
        val category: Identifier<EntryCategory>,
        val day: LocalDate,
    ) {
        val now: Instant = Instant.ofEpochSecond(1_791_000_000)

        suspend fun addExpense(amount: Int) {
            val draft = EntryDraft(
                type = Entry.Kind.expense,
                amount = amount,
                date = day,
                categoryId = category,
                walletId = wallet.id,
            )

            database.saveEntry(draft, at = now)
        }

        suspend fun adjust(amount: Long): Adjustment? = database.saveAdjustment(
            amount,
            of = wallet.id,
            on = day,
            at = now,
        )

        fun entries(list: EntryList): List<Entry> = list.entries

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                database.insertDefaultsIfEmpty(Instant.ofEpochSecond(1_791_000_000))
                val options = database.entryOptions()

                return Setup(
                    database = database,
                    wallet = options.wallets[0],
                    category = options.expenseCategories[0].id,
                    day = assertNotNull(LocalDate.parse("2026-10-23")),
                )
            }
        }
    }
}
