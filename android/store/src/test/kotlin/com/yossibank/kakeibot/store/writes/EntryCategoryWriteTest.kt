package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryCategoryDraft
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.categoryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.writes.methods.CategoryWriteError
import com.yossibank.kakeibot.store.writes.methods.CategoryWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteCategory
import com.yossibank.kakeibot.store.writes.methods.reorderCategories
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveCategory
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.setCategoryHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryCategoryWriteTest {
    @Test
    fun addsCategoryAfterSameKind() = runTest {
        val setup = Setup.make()

        val saved = setup.database.saveCategory(
            setup.draft,
            tags = emptyList(),
            at = setup.now,
        )

        val list = setup.database.categoryList()
        val icon = assertNotNull(list.icons[saved.iconId])

        assertEquals(12, saved.sortOrder)
        assertEquals("外食", saved.name)
        assertEquals(Icon.Glyph.cafe, icon.glyph)
        assertEquals("#E07A5F", icon.color)
        assertTrue(saved in list.categories)

        setup.database.close()
    }

    @Test
    fun updatesNameAndIcon() = runTest {
        val setup = Setup.make()
        val later = setup.now.plusSeconds(60)
        val food = setup.category(named = "食費")

        val draft = setup.draft.copy(
            name = "ごはん",
            mark = IconDraft.Mark.Emoji("🍙"),
        )

        val updated = setup.database.saveCategory(
            draft,
            tags = emptyList(),
            editing = food.id,
            at = later,
        )

        val list = setup.database.categoryList()
        val icon = assertNotNull(list.icons[updated.iconId])

        assertEquals(food.id, updated.id)
        assertEquals("ごはん", updated.name)
        assertEquals(food.sortOrder, updated.sortOrder)
        assertEquals(later, updated.updatedAt)
        assertEquals(food.iconId, icon.id)
        assertEquals("🍙", icon.emoji)
        assertNull(icon.glyph)

        setup.database.close()
    }

    @Test
    fun rejectsUnknownCategory() = runTest {
        val setup = Setup.make()

        val error = assertFailsWith<CategoryWriteException> {
            setup.database.saveCategory(
                setup.draft,
                tags = emptyList(),
                editing = Identifier(),
                at = setup.now,
            )
        }

        assertEquals(CategoryWriteError.categoryNotFound, error.error)

        setup.database.close()
    }

    @Test
    fun reordersCategories() = runTest {
        val setup = Setup.make()
        val before = setup.expenseCategories()
        val reversed = before.map { it.id }.reversed()

        setup.database.reorderCategories(
            reversed,
            at = setup.now,
        )

        val after = setup.expenseCategories()

        assertEquals(reversed, after.map { it.id })
        assertEquals((0 until before.size).toList(), after.map { it.sortOrder })

        setup.database.close()
    }

    @Test
    fun deletesUnusedCategory() = runTest {
        val setup = Setup.make()
        val food = setup.category(named = "食費")

        val deletion = setup.database.deleteCategory(
            food.id,
            at = setup.now,
        )

        val categories = setup.expenseCategories()
        setup.database.restore(deletion)
        val restored = setup.category(named = "食費")

        assertFalse(categories.any { it.id == food.id })
        assertEquals(food, restored)

        setup.database.close()
    }

    @Test
    fun keepsCategoryWithEntries() = runTest {
        val setup = Setup.make()
        val food = setup.category(named = "食費")
        val options = setup.database.entryOptions()
        val wallet = options.wallets[0]
        val day = assertNotNull(LocalDate.parse("2026-11-01"))

        val entry = EntryDraft(
            type = Entry.Kind.expense,
            amount = 500,
            date = day,
            categoryId = food.id,
            walletId = wallet.id,
        )

        setup.database.saveEntry(entry, at = setup.now)

        val error = assertFailsWith<CategoryWriteException> {
            setup.database.deleteCategory(
                food.id,
                at = setup.now,
            )
        }

        assertEquals(CategoryWriteError.hasEntries, error.error)

        setup.database.close()
    }

    @Test
    fun hidesAndShowsCategory() = runTest {
        val setup = Setup.make()
        val food = setup.category(named = "食費")

        setup.database.setCategoryHidden(
            food.id,
            isHidden = true,
            at = setup.now,
        )

        val hiddenOptions = setup.database.entryOptions()

        setup.database.setCategoryHidden(
            food.id,
            isHidden = false,
            at = setup.now,
        )

        val shownOptions = setup.database.entryOptions()

        assertFalse(hiddenOptions.expenseCategories.any { it.id == food.id })
        assertTrue(shownOptions.expenseCategories.any { it.id == food.id })

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val draft: EntryCategoryDraft,
    ) {
        suspend fun category(named: String): EntryCategory {
            val list = database.categoryList()

            return assertNotNull(list.categories.firstOrNull { it.name == named })
        }

        suspend fun expenseCategories(): List<EntryCategory> {
            val list = database.categoryList()

            return list.categories.filter { it.kind == EntryCategory.Kind.expense }
        }

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)

                val draft = EntryCategoryDraft(
                    kind = EntryCategory.Kind.expense,
                    name = "外食",
                    mark = IconDraft.Mark.Glyph(Icon.Glyph.cafe),
                    color = "#E07A5F",
                )

                database.insertDefaultsIfEmpty(now)

                return Setup(
                    database = database,
                    now = now,
                    draft = draft,
                )
            }
        }
    }
}
