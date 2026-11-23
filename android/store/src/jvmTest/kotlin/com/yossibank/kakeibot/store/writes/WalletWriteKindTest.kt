package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.saveValuation
import com.yossibank.kakeibot.store.writes.methods.saveWallet
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull

class WalletWriteKindTest {
    @Test
    fun refusesDebtChangeWhenWalletHasEntries() = runTest {
        val setup = WalletWriteTest.Setup.make()
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
        val setup = WalletWriteTest.Setup.make()
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
        val setup = WalletWriteTest.Setup.make()
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
        val setup = WalletWriteTest.Setup.make()
        val saved = setup.database.saveWallet(setup.draft, at = setup.now)

        val updated = setup.database.saveWallet(
            setup.draft.copy(kind = Wallet.Kind.cash),
            editing = saved.id,
            at = setup.now,
        )

        assertEquals(Wallet.Kind.cash, updated.kind)

        setup.database.close()
    }
}
