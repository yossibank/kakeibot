package com.yossibank.kakeibot.store.database

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.protocols.unarchivedInOrder
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import com.yossibank.kakeibot.store.support.execute
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AppDatabaseDefaultsTest {
    @Test
    fun insertsWalletsAndCategoriesOnce() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)

        database.insertDefaultsIfEmpty(now)
        database.insertDefaultsIfEmpty(now)
        val wallets = database.walletDao().all().unarchivedInOrder()
        val categories = database.categoryDao().all().unarchivedInOrder()

        assertEquals(listOf("財布", "銀行"), wallets.map { it.name })
        assertEquals(12, categories.count { it.kind == EntryCategory.Kind.expense.rawValue })
        assertEquals(
            listOf("給料", "臨時収入", "その他"),
            categories.filter { it.kind == EntryCategory.Kind.income.rawValue }.map { it.name },
        )
        assertEquals(17, database.iconDao().all().size)

        database.close()
    }

    @Test
    fun addsStarterTemplatesOnlyWhenEmpty() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)

        database.insertTemplatesIfEmpty(now)
        database.insertTemplatesIfEmpty(now)
        val templates = database.templateDao().all()

        assertEquals(4, templates.size)

        database.close()
    }

    @Test
    fun skipsWhenWalletsExist() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)

        val icon = Icon(
            emoji = "🍙",
            text = null,
            color = "#C9A465",
            createdAt = now,
            updatedAt = now,
        )

        val wallet = Wallet(
            name = "財布",
            kind = Wallet.Kind.cash,
            iconId = icon.id,
            initialBalance = 0,
            sortOrder = 0,
            createdAt = now,
            updatedAt = now,
        )

        val category = EntryCategory(
            kind = EntryCategory.Kind.expense,
            name = "食費",
            iconId = icon.id,
            sortOrder = 0,
            createdAt = now,
            updatedAt = now,
        )

        database.write {
            database.iconDao().insert(icon.record())
            database.walletDao().insert(wallet.record())
            database.categoryDao().insert(category.record())
        }

        database.insertDefaultsIfEmpty(now)

        assertEquals(1, database.walletDao().count())
        assertEquals(1, database.categoryDao().countWithoutWallet())

        database.close()
    }

    @Test
    fun insertsShelfOnce() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)

        database.insertShelfIfEmpty(now)
        database.insertShelfIfEmpty(now)
        val shelfIcons = database.shelfIconDao().all().sortedBy { it.sortOrder }
        val icons = database.iconDao().all().associate { it.id to it.decoded(IconRecord::icon) }
        val glyphs = shelfIcons.map { icons[it.iconId]?.glyph }

        assertEquals((0 until 8).toList(), shelfIcons.map { it.sortOrder })
        assertEquals(Icon.Glyph.star, glyphs.first())
        assertTrue(glyphs.all { it != null })

        database.close()
    }

    @Test
    fun skipsShelfWhenAllAreHidden() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertShelfIfEmpty(now)

        database.execute(
            "UPDATE shelf_icon SET archived_at = ?, updated_at = ?",
            now.storedValue,
            now.storedValue,
        )

        database.insertShelfIfEmpty(now)
        val shelfIcons = database.shelfIconDao().all().map { it.decoded(ShelfIconRecord::shelfIcon) }

        assertEquals(8, shelfIcons.size)
        assertTrue(shelfIcons.all { it.archivedAt != null })

        database.close()
    }
}
