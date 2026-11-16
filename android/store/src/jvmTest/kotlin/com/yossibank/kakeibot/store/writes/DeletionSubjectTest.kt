package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.deleteWallet
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.saveWallet
import com.yossibank.kakeibot.store.writes.types.Deletion
import com.yossibank.kakeibot.store.writes.types.DeletionSubject
import com.yossibank.kakeibot.store.writes.types.subject
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class DeletionSubjectTest {
    @Test
    fun namesDeletedWallet() = runTest {
        val setup = WalletWriteTest.Setup.make()
        val card = setup.database.saveWallet(setup.draft, at = setup.now)

        val deletion = setup.database.deleteWallet(
            card.id,
            at = setup.now,
        )

        assertEquals(DeletionSubject.Kind.wallet, deletion.subject?.kind)
        assertEquals(1, deletion.subject?.count)
        assertEquals(listOf("楽天カード"), deletion.subject?.names)

        setup.database.close()
    }

    @Test
    fun namesRecurringByMemoOnly() = runTest {
        val setup = WalletWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val category = options.expenseCategories[0].id
        val bank = setup.wallet(named = "銀行")
        val day = assertNotNull(LocalDate.parse("2026-11-01"))

        val rentDraft = draft(
            memo = "家賃",
            categoryId = category,
            walletId = bank.id,
            on = day,
        )

        val otherDraft = draft(
            memo = "",
            categoryId = category,
            walletId = bank.id,
            on = day,
        )

        val rent = setup.database.saveRecurring(
            rentDraft,
            today = day,
            at = setup.now,
        )

        val other = setup.database.saveRecurring(
            otherDraft,
            today = day,
            at = setup.now,
        )

        val named = setup.database.deleteRecurring(
            rent.id,
            at = setup.now,
        )

        val unnamed = setup.database.deleteRecurring(
            other.id,
            at = setup.now,
        )

        assertEquals(DeletionSubject.Kind.recurring, named.subject?.kind)
        assertEquals(listOf("家賃"), named.subject?.names)
        assertEquals(1, unnamed.subject?.count)
        assertEquals(true, unnamed.subject?.names?.isEmpty())

        setup.database.close()
    }

    @Test
    fun countsMergedDeletions() = runTest {
        val setup = WalletWriteTest.Setup.make()
        val first = setup.database.saveWallet(setup.draft, at = setup.now)
        val second = setup.database.saveWallet(setup.draft, at = setup.now)

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

        assertEquals(2, merged.subject?.count)
        assertNull(Deletion.merging(emptyList()).subject)

        setup.database.close()
    }
}

private fun draft(
    memo: String,
    categoryId: Identifier<EntryCategory>,
    walletId: Identifier<Wallet>,
    on: LocalDate,
): RecurringDraft = RecurringDraft(
    type = Entry.Kind.expense,
    amount = 80000,
    categoryId = categoryId,
    walletId = walletId,
    memo = memo,
    frequency = Recurring.Frequency.monthly,
    month = 1,
    day = 27,
    startDate = on,
)
