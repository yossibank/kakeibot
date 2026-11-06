package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryHistory
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.types.EntryHistory
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class EntryHistoryTest {
    @Test
    fun returnsCountAndOldestCreatedAt() = runTest {
        val database = AppDatabase.inMemory()
        val first = Instant.ofEpochSecond(1_791_000_000)
        val later = first.plusSeconds(86400)
        database.insertDefaultsIfEmpty(first)

        database.insertExpense(later)
        database.insertExpense(first)
        database.insertExpense(later)
        val history = database.entryHistory()

        assertEquals(
            EntryHistory(
                count = 3,
                firstCreatedAt = first,
            ),
            history,
        )

        database.close()
    }

    @Test
    fun returnsNothingWithoutEntries() = runTest {
        val database = AppDatabase.inMemory()
        database.insertDefaultsIfEmpty(Instant.ofEpochSecond(1_791_000_000))

        val history = database.entryHistory()

        assertEquals(0, history.count)
        assertNull(history.firstCreatedAt)

        database.close()
    }

    @Test
    fun countsSingleEntry() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)

        database.insertExpense(now)
        val history = database.entryHistory()

        assertEquals(
            EntryHistory(
                count = 1,
                firstCreatedAt = now,
            ),
            history,
        )

        database.close()
    }
}

private suspend fun AppDatabase.insertExpense(at: Instant): Entry {
    val options = entryOptions()

    return saveEntry(
        EntryDraft(
            type = Entry.Kind.expense,
            amount = 980,
            date = assertNotNull(LocalDate.parse("2026-10-03")),
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
        ),
        at = at,
    )
}
