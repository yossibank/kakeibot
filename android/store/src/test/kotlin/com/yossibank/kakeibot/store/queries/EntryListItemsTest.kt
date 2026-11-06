package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.fetchEntryList
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.support.insertEntry
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryListItemsTest {
    @Test
    fun readsItemsOnlyOfRequestedEntries() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val date = assertNotNull(LocalDate.parse("2026-10-03"))

        val shown = database.insertReceipt(
            name = "牛乳",
            date = date,
            options = options,
            at = now,
        )

        val hidden = database.insertReceipt(
            name = "食パン",
            date = date,
            options = options,
            at = now,
        )

        val (withItems, withoutItems) = database.read {
            val entries = listOf(shown)

            val withItems = database.fetchEntryList(
                entries = entries,
                includesItems = true,
            )

            withItems to database.fetchEntryList(entries = entries)
        }

        assertEquals(listOf("牛乳"), withItems.items[shown.id]?.map { it.name })
        assertNull(withItems.items[hidden.id])
        assertTrue(withoutItems.items.isEmpty())

        database.close()
    }
}

private suspend fun AppDatabase.insertReceipt(
    name: String,
    date: LocalDate,
    options: EntryOptions,
    at: Instant,
) = insertEntry(
    amount = 300,
    date = date,
    categoryId = options.expenseCategories[0].id,
    walletId = options.wallets[0].id,
    items = listOf(name to 300),
    at = at,
)
