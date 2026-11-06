package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.latestEntryList
import com.yossibank.kakeibot.store.queries.methods.recentMemos
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.support.insertCardBill
import com.yossibank.kakeibot.store.support.insertEntry
import kotlinx.coroutines.flow.produceIn
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryListTest {
    @Test
    fun publishesSavedEntries() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val category = options.expenseCategories[0]
        val date = assertNotNull(LocalDate.parse("2026-10-03"))

        val updates = database.entryListUpdates().produceIn(backgroundScope)
        val first = updates.receive()

        assertTrue(first.days.isEmpty())
        assertEquals(category, first.categories[category.id])

        val saved = database.insertEntry(
            amount = 980,
            date = date,
            categoryId = category.id,
            walletId = options.wallets[0].id,
            at = now,
        )

        val second = updates.receive()

        assertEquals(listOf(date), second.days.map { it.date })
        assertEquals(listOf(saved), second.days.first().entries)
        assertEquals(980L, second.days.first().expenseTotal)

        database.close()
    }

    @Test
    fun listsItemsByEntry() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val date = assertNotNull(LocalDate.parse("2026-10-03"))

        val saved = database.insertEntry(
            amount = 616,
            date = date,
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            items = listOf(
                "牛乳" to 396,
                "食パン" to 220,
            ),
            at = now,
        )

        val other = database.insertEntry(
            amount = 500,
            date = date,
            categoryId = options.expenseCategories[0].id,
            walletId = options.wallets[0].id,
            at = now,
        )

        val list = database.entryList()

        assertEquals(
            listOf(
                "牛乳",
                "食パン",
            ),
            list.items[saved.id]?.map { it.name },
        )
        assertNull(list.items[other.id])

        database.close()
    }

    @Test
    fun skipsUnchangedLists() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)

        val updates = database.entryListUpdates().produceIn(backgroundScope)
        updates.receive()

        database.execute(touchWallets)
        val saved = database.insertExpense(now)
        val next = updates.receive()

        assertEquals(listOf(saved), next.days.first().entries)

        database.close()
    }

    @Test
    fun skipsGeneratedDateWrites() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val bill = database.insertCardBill(now)
        val generated = assertNotNull(LocalDate.parse("2026-10-02"))

        val updates = database.entryListUpdates().produceIn(backgroundScope)
        val first = updates.receive()

        assertEquals(listOf(bill.id), first.cardBills.map { it.id })

        database.execute(
            generatedUpdate,
            generated.databaseValue,
        )

        val saved = database.insertExpense(now)
        val next = updates.receive()

        assertEquals(listOf(saved), next.days.first().entries)
        assertEquals(listOf(bill.id), next.cardBills.map { it.id })

        database.close()
    }

    @Test
    fun readsListOnce() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val date = assertNotNull(LocalDate.parse("2026-10-03"))

        val saved = database.insertEntry(
            type = Entry.Kind.income,
            amount = 250_000,
            date = date,
            categoryId = options.incomeCategories[0].id,
            walletId = options.wallets[1].id,
            at = now,
        )

        val list = database.entryList()

        assertEquals(listOf(saved), list.days.first().entries)
        assertEquals(250_000L, list.days.first().incomeTotal)
        assertEquals("銀行", list.wallets[saved.walletId]?.name)

        database.close()
    }

    @Test
    fun readsLatestSharedList() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)

        val saved = database.insertExpense(now)
        val latest = database.latestEntryList()
        val read = database.entryList()

        assertEquals(read, latest)
        assertEquals(listOf(saved), latest.days.first().entries)

        database.close()
    }

    @Test
    fun listsRecentMemosOnce() = runTest {
        val database = AppDatabase.inMemory()
        val start = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(start)
        val options = database.entryOptions()
        val date = assertNotNull(LocalDate.parse("2026-10-03"))

        val memos = listOf(
            "ランチ",
            "",
            "コーヒー",
            "ランチ",
            "スーパー",
        )

        for ((offset, memo) in memos.withIndex()) {
            database.insertEntry(
                amount = 500,
                date = date,
                categoryId = options.expenseCategories[0].id,
                walletId = options.wallets[0].id,
                memo = memo,
                at = start.plusSeconds(offset.toLong()),
            )
        }

        val recent = database.recentMemos(limit = 2)

        assertEquals(
            listOf(
                "スーパー",
                "ランチ",
            ),
            recent,
        )

        database.close()
    }

    @Test
    fun optionsSkipArchivedAndFollowSortOrder() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val defaults = database.entryOptions()
        val archived = defaults.expenseCategories[0]
        val moved = defaults.wallets[0]

        database.execute(
            "UPDATE category SET archived_at = ? WHERE id = ?",
            now.storedValue,
            archived.id.databaseValue,
        )

        database.execute(
            "UPDATE wallet SET sort_order = 9 WHERE id = ?",
            moved.id.databaseValue,
        )

        val options = database.entryOptions()
        val remaining = defaults.expenseCategories.drop(1)

        assertEquals(remaining, options.expenseCategories)
        assertEquals(
            listOf(
                "銀行",
                "財布",
            ),
            options.wallets.map { it.name },
        )

        database.close()
    }
}

private const val generatedUpdate = "UPDATE recurring SET generated_until = ?"

private const val touchWallets = "UPDATE wallet SET name = name"

private suspend fun AppDatabase.insertExpense(at: Instant): Entry {
    val options = entryOptions()

    return insertEntry(
        amount = 980,
        date = assertNotNull(LocalDate.parse("2026-10-03")),
        categoryId = options.expenseCategories[0].id,
        walletId = options.wallets[0].id,
        at = at,
    )
}
