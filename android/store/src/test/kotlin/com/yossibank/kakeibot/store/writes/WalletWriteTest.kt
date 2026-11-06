package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.concepts.wallet.WalletDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.writes.methods.WalletWriteError
import com.yossibank.kakeibot.store.writes.methods.WalletWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteWallet
import com.yossibank.kakeibot.store.writes.methods.reorderWallets
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.saveValuation
import com.yossibank.kakeibot.store.writes.methods.saveWallet
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import com.yossibank.kakeibot.store.writes.methods.setWalletHidden
import com.yossibank.kakeibot.store.writes.types.Deletion
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WalletWriteTest {
    @Test
    fun addsWalletAtTheEnd() = runTest {
        val setup = Setup.make()

        val saved = setup.database.saveWallet(setup.draft, at = setup.now)
        val list = setup.database.entryList()
        val icon = assertNotNull(list.icons[saved.iconId])

        assertEquals(2, saved.sortOrder)
        assertEquals("楽天カード", saved.name)
        assertEquals(-38000, saved.initialBalance)
        assertEquals("楽", icon.text)
        assertEquals(saved, list.wallets[saved.id])

        setup.database.close()
    }

    @Test
    fun updatesWalletAndIcon() = runTest {
        val setup = Setup.make()
        val later = setup.now.plusSeconds(60)
        val bank = setup.wallet(named = "銀行")

        val draft = setup.draft.copy(
            name = "ゆうちょ",
            kind = Wallet.Kind.bank,
            mark = IconDraft.Mark.Emoji("📮"),
            initialBalance = 120_000,
        )

        val updated = setup.database.saveWallet(
            draft,
            editing = bank.id,
            at = later,
        )

        val list = setup.database.entryList()
        val icon = assertNotNull(list.icons[updated.iconId])

        assertEquals(bank.id, updated.id)
        assertEquals("ゆうちょ", updated.name)
        assertEquals(120_000, updated.initialBalance)
        assertEquals(bank.sortOrder, updated.sortOrder)
        assertEquals(later, updated.updatedAt)
        assertEquals(bank.iconId, icon.id)
        assertEquals("📮", icon.emoji)

        setup.database.close()
    }

    @Test
    fun savesLoanAmountAndClearsItWhenKindChanges() = runTest {
        val setup = Setup.make()

        val draft = setup.draft.copy(
            kind = Wallet.Kind.loan,
            loanAmount = 300_000,
        )

        val saved = setup.database.saveWallet(draft, at = setup.now)
        val list = setup.database.entryList()

        val updated = setup.database.saveWallet(
            draft.copy(kind = Wallet.Kind.bank),
            editing = saved.id,
            at = setup.now,
        )

        val reloaded = setup.database.entryList()

        assertEquals(300_000, saved.loanAmount)
        assertEquals(300_000, list.wallets[saved.id]?.loanAmount)
        assertNull(updated.loanAmount)
        assertNull(reloaded.wallets[saved.id]?.loanAmount)

        setup.database.close()
    }

    @Test
    fun reordersWallets() = runTest {
        val setup = Setup.make()
        val cash = setup.wallet(named = "財布")
        val bank = setup.wallet(named = "銀行")

        setup.database.reorderWallets(
            listOf(bank.id, cash.id),
            at = setup.now,
        )

        val options = setup.database.entryOptions()

        assertEquals(listOf("銀行", "財布"), options.wallets.map { it.name })

        setup.database.close()
    }

    @Test
    fun hidesAndShowsWallet() = runTest {
        val setup = Setup.make()
        val bank = setup.wallet(named = "銀行")

        setup.database.setWalletHidden(
            bank.id,
            isHidden = true,
            at = setup.now,
        )

        val hidden = setup.database.entryOptions()

        setup.database.setWalletHidden(
            bank.id,
            isHidden = false,
            at = setup.now,
        )

        val shown = setup.database.entryOptions()

        assertEquals(listOf("財布"), hidden.wallets.map { it.name })
        assertEquals(listOf("財布", "銀行"), shown.wallets.map { it.name })

        setup.database.close()
    }

    @Test
    fun keepsTheLastShownWallet() = runTest {
        val setup = Setup.make()
        val cash = setup.wallet(named = "財布")
        val bank = setup.wallet(named = "銀行")

        setup.database.setWalletHidden(
            bank.id,
            isHidden = true,
            at = setup.now,
        )

        val error = assertFailsWith<WalletWriteException> {
            setup.database.setWalletHidden(
                cash.id,
                isHidden = true,
                at = setup.now,
            )
        }

        assertEquals(WalletWriteError.lastShownWallet, error.error)

        setup.database.close()
    }

    @Test
    fun deletesWalletWithItsRecurringsAndValuations() = runTest {
        val setup = Setup.make()
        val bank = setup.wallet(named = "銀行")
        val card = setup.database.saveWallet(setup.draft, at = setup.now)
        val day = assertNotNull(LocalDate.parse("2026-11-01"))

        val draft = RecurringDraft(
            type = Entry.Kind.transfer,
            amount = 0,
            categoryId = null,
            walletId = bank.id,
            toWalletId = card.id,
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = 27,
            closingDay = 31,
            startDate = day,
        )

        setup.database.saveRecurring(
            draft,
            today = day,
            at = setup.now,
        )

        setup.database.saveValuation(
            0,
            of = card.id,
            on = day,
            at = setup.now,
        )

        val deletion = setup.database.deleteWallet(
            card.id,
            at = setup.now,
        )

        val list = setup.database.entryList()
        val recurrings = setup.database.recurrings()
        setup.database.restore(deletion)
        val restored = setup.database.entryList()
        val restoredRecurrings = setup.database.recurrings()

        assertNull(list.wallets[card.id])
        assertTrue(list.valuations.isEmpty())
        assertTrue(recurrings.isEmpty())
        assertEquals(card, restored.wallets[card.id])
        assertEquals(1, restored.valuations.size)
        assertEquals(1, restoredRecurrings.size)

        setup.database.close()
    }

    @Test
    fun deletesWalletIconWithWallet() = runTest {
        val setup = Setup.make()
        val wallet = setup.database.saveWallet(setup.draft, at = setup.now)

        val deletion = setup.database.deleteWallet(
            wallet.id,
            at = setup.now,
        )

        val deleted = setup.database.snapshot().icons.map { it.id }
        setup.database.restore(deletion)
        val restored = setup.database.snapshot().icons.map { it.id }

        assertFalse(wallet.iconId in deleted)
        assertTrue(wallet.iconId in restored)

        setup.database.close()
    }

    @Test
    fun restoresMergedDeletions() = runTest {
        val setup = Setup.make()
        val first = setup.database.saveWallet(setup.draft, at = setup.now)
        val second = setup.database.saveWallet(setup.draft.copy(name = "PayPay"), at = setup.now)

        val deletions = listOf(
            setup.database.deleteWallet(
                first.id,
                at = setup.now,
            ),
            setup.database.deleteWallet(
                second.id,
                at = setup.now,
            ),
        )

        val merged = Deletion.merging(deletions)

        setup.database.restore(merged)
        val list = setup.database.entryList()

        assertEquals(first, list.wallets[first.id])
        assertEquals(second, list.wallets[second.id])

        setup.database.close()
    }

    @Test
    fun keepsWalletWithEntries() = runTest {
        val setup = Setup.make()
        val cash = setup.wallet(named = "財布")
        val options = setup.database.entryOptions()
        val food = options.expenseCategories[0]
        val day = assertNotNull(LocalDate.parse("2026-11-01"))

        val entry = EntryDraft(
            type = Entry.Kind.expense,
            amount = 500,
            date = day,
            categoryId = food.id,
            walletId = cash.id,
        )

        setup.database.saveEntry(entry, at = setup.now)

        val error = assertFailsWith<WalletWriteException> {
            setup.database.deleteWallet(
                cash.id,
                at = setup.now,
            )
        }

        assertEquals(WalletWriteError.hasEntries, error.error)

        setup.database.close()
    }

    @Test
    fun rejectsUnknownWallet() = runTest {
        val setup = Setup.make()

        val error = assertFailsWith<WalletWriteException> {
            setup.database.saveWallet(
                setup.draft,
                editing = Identifier(),
                at = setup.now,
            )
        }

        assertEquals(WalletWriteError.walletNotFound, error.error)

        setup.database.close()
    }

    @Test
    fun refusesDebtChangeWhenWalletHasEntries() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()
        val bank = setup.wallet(named = "銀行")
        val day = assertNotNull(LocalDate.parse("2026-10-10"))

        val entry = EntryDraft(
            type = Entry.Kind.expense,
            amount = 500,
            date = day,
            categoryId = options.expenseCategories[0].id,
            walletId = bank.id,
        )

        setup.database.saveEntry(entry, at = setup.now)

        val error = assertFailsWith<DraftProblemException> {
            setup.database.saveWallet(
                setup.draft.copy(kind = Wallet.Kind.card),
                editing = bank.id,
                at = setup.now,
            )
        }

        val stored = setup.wallet(named = "銀行")

        assertEquals(DraftProblem.kindLocked, error.problem)
        assertEquals(Wallet.Kind.bank, stored.kind)

        setup.database.close()
    }

    @Test
    fun refusesDebtChangeWhenOnlyHiddenRecurringUsesWallet() = runTest {
        val setup = Setup.make()
        val bank = setup.wallet(named = "銀行")
        val cash = setup.wallet(named = "財布")
        val day = assertNotNull(LocalDate.parse("2026-10-10"))
        val start = day.adding(days = 30)

        val recurring = RecurringDraft(
            type = Entry.Kind.transfer,
            amount = 1000,
            categoryId = null,
            walletId = bank.id,
            toWalletId = cash.id,
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = 27,
            startDate = start,
        )

        val saved = setup.database.saveRecurring(
            recurring,
            today = day,
            at = setup.now,
        )

        setup.database.setRecurringHidden(
            saved.id,
            isHidden = true,
            today = day,
            at = setup.now,
        )

        val error = assertFailsWith<DraftProblemException> {
            setup.database.saveWallet(
                setup.draft.copy(kind = Wallet.Kind.card),
                editing = cash.id,
                at = setup.now,
            )
        }

        assertEquals(DraftProblem.kindLocked, error.problem)

        setup.database.close()
    }

    @Test
    fun refusesLeavingInvestmentWhenValued() = runTest {
        val setup = Setup.make()
        val day = assertNotNull(LocalDate.parse("2026-10-10"))
        val investment = setup.draft.copy(kind = Wallet.Kind.investment)
        val saved = setup.database.saveWallet(investment, at = setup.now)

        setup.database.saveValuation(
            150_000,
            of = saved.id,
            on = day,
            at = setup.now,
        )

        val error = assertFailsWith<DraftProblemException> {
            setup.database.saveWallet(
                investment.copy(kind = Wallet.Kind.bank),
                editing = saved.id,
                at = setup.now,
            )
        }

        assertEquals(DraftProblem.valuedKindLocked, error.problem)

        setup.database.close()
    }

    @Test
    fun changesKindFreelyWithoutRecords() = runTest {
        val setup = Setup.make()
        val saved = setup.database.saveWallet(setup.draft, at = setup.now)

        val updated = setup.database.saveWallet(
            setup.draft.copy(kind = Wallet.Kind.cash),
            editing = saved.id,
            at = setup.now,
        )

        assertEquals(Wallet.Kind.cash, updated.kind)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val draft: WalletDraft,
    ) {
        suspend fun wallet(named: String): Wallet {
            val options = database.entryOptions()

            return assertNotNull(options.wallets.firstOrNull { it.name == named })
        }

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)

                database.insertDefaultsIfEmpty(now)

                val draft = WalletDraft(
                    kind = Wallet.Kind.card,
                    name = "楽天カード",
                    mark = IconDraft.Mark.Text("楽"),
                    color = "#BF4040",
                    initialBalance = -38000,
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
