package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class RecurringRestoreTest {
    @Test
    fun restoresDeletedRecurring() = runTest {
        val setup = WalletWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val bank = setup.wallet(named = "銀行")
        val day = assertNotNull(LocalDate.parse("2026-11-01"))

        val draft = RecurringDraft(
            type = Entry.Kind.expense,
            amount = 80000,
            categoryId = options.expenseCategories[0].id,
            walletId = bank.id,
            memo = "家賃",
            frequency = Recurring.Frequency.monthly,
            month = 1,
            day = 27,
            startDate = day,
        )

        val rent = setup.database.saveRecurring(
            draft,
            today = day,
            at = setup.now,
        )

        val deletion = setup.database.deleteRecurring(
            rent.id,
            at = setup.now,
        )

        setup.database.restore(deletion)

        assertEquals(listOf(rent.id), setup.database.recurrings().map { it.id })

        setup.database.close()
    }
}
