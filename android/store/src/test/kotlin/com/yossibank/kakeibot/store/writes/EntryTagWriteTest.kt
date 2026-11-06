package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryCategoryDraft
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.category.EntryTagDraft
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.categoryList
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.types.detailParts
import com.yossibank.kakeibot.store.writes.methods.CategoryWriteError
import com.yossibank.kakeibot.store.writes.methods.CategoryWriteException
import com.yossibank.kakeibot.store.writes.methods.TemplateWriteError
import com.yossibank.kakeibot.store.writes.methods.TemplateWriteException
import com.yossibank.kakeibot.store.writes.methods.WriteError
import com.yossibank.kakeibot.store.writes.methods.WriteException
import com.yossibank.kakeibot.store.writes.methods.saveCategory
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveTags
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class EntryTagWriteTest {
    @Test
    fun savesTagsInOrder() = runTest {
        val setup = Setup.make()

        setup.saveFood(names = listOf("朝ごはん", " 昼ごはん "))
        val tags = setup.foodTags()

        assertEquals(listOf("朝ごはん", "昼ごはん"), tags.map { it.name })
        assertEquals(listOf(0, 1), tags.map { it.sortOrder })

        setup.database.close()
    }

    @Test
    fun renamesKeptTagsAndArchivesRemovedOnes() = runTest {
        val setup = Setup.make()
        setup.saveFood(names = listOf("朝ごはん", "昼ごはん"))
        val before = setup.foodTags()

        val drafts = listOf(
            EntryTagDraft(
                id = before[1].id,
                name = "ランチ",
            ),
            EntryTagDraft(name = "おやつ"),
        )

        setup.saveFood(drafts)
        val after = setup.foodTags()
        val options = setup.database.entryOptions()
        val removed = options.tags.firstOrNull { it.id == before[0].id }

        assertEquals(listOf("ランチ", "おやつ"), after.map { it.name })
        assertEquals(before[1].id, after[0].id)
        assertEquals(setup.now, removed?.archivedAt)

        setup.database.close()
    }

    @Test
    fun savesOnlyTagsOfCategory() = runTest {
        val setup = Setup.make()
        val food = setup.category(named = "食費")
        val drafts = listOf(EntryTagDraft(name = "朝ごはん"))

        val saved = setup.database.saveTags(
            drafts,
            categoryId = food.id,
            at = setup.now,
        )

        val tags = setup.foodTags()
        val category = setup.category(named = "食費")

        assertEquals(tags.map { it.id }, saved.map { it.id })
        assertEquals(listOf("朝ごはん"), tags.map { it.name })
        assertEquals(food, category)

        setup.database.close()
    }

    @Test
    fun rejectsUnknownTag() = runTest {
        val setup = Setup.make()

        val drafts = listOf(
            EntryTagDraft(
                id = Identifier(),
                name = "朝ごはん",
            ),
        )

        val error = assertFailsWith<CategoryWriteException> {
            setup.saveFood(drafts)
        }

        assertEquals(CategoryWriteError.tagNotFound, error.error)

        setup.database.close()
    }

    @Test
    fun rejectsBlankTagName() = runTest {
        val setup = Setup.make()

        val error = assertFailsWith<EntryTagDraft.ProblemException> {
            setup.saveFood(names = listOf("  "))
        }

        assertEquals(EntryTagDraft.Problem.emptyName, error.problem)

        setup.database.close()
    }

    @Test
    fun restoresArchivedTagWithSameName() = runTest {
        val setup = Setup.make()
        setup.saveFood(names = listOf("朝ごはん", "昼ごはん"))
        val before = setup.foodTags()
        val kept = EntryTagDraft(before[1])
        val restored = EntryTagDraft(name = " 朝ごはん ")

        setup.saveFood(listOf(kept))
        setup.saveFood(listOf(kept, restored))
        val after = setup.foodTags()
        val options = setup.database.entryOptions()
        val all = options.tags.filter { it.categoryId == before[0].categoryId }

        assertEquals(listOf(before[1].id, before[0].id), after.map { it.id })
        assertEquals(listOf(0, 1), after.map { it.sortOrder })
        assertEquals(2, all.size)

        setup.database.close()
    }

    @Test
    fun rejectsDuplicateTagName() = runTest {
        val setup = Setup.make()

        val error = assertFailsWith<EntryTagDraft.ProblemException> {
            setup.saveFood(names = listOf("朝ごはん", "朝ごはん "))
        }

        assertEquals(EntryTagDraft.Problem.duplicateName, error.problem)

        setup.database.close()
    }

    @Test
    fun hidesArchivedTagFromTemplateDetail() = runTest {
        val setup = Setup.make()
        setup.saveFood(names = listOf("朝ごはん"))
        val tag = setup.foodTags()[0]
        val entry = setup.entryDraft()

        val draft = EntryTemplateDraft(
            name = "朝",
            type = Entry.Kind.expense,
            amount = 500,
            categoryId = entry.categoryId,
            tagId = tag.id,
            walletId = entry.walletId,
        )

        val template = setup.database.saveTemplate(draft, at = setup.now)
        val before = setup.database.entryList().detailParts(of = template)
        setup.saveFood(tags = emptyList())
        val after = setup.database.entryList().detailParts(of = template)

        assertTrue("朝ごはん" in before)
        assertFalse("朝ごはん" in after)

        setup.database.close()
    }

    @Test
    fun savesEntryWithTagOfItsCategory() = runTest {
        val setup = Setup.make()
        setup.saveFood(names = listOf("昼ごはん"))
        val tag = setup.foodTags()[0]
        val draft = setup.entryDraft().copy(tagId = tag.id)

        val entry = setup.database.saveEntry(draft, at = setup.now)

        assertEquals(tag.id, entry.tagId)

        setup.database.close()
    }

    @Test
    fun rejectsEntryWithTagOfOtherCategory() = runTest {
        val setup = Setup.make()
        setup.saveFood(names = listOf("昼ごはん"))
        val tag = setup.foodTags()[0]
        val other = setup.category(named = "日用品")

        val draft = setup.entryDraft().copy(
            categoryId = other.id,
            tagId = tag.id,
        )

        val error = assertFailsWith<WriteException> {
            setup.database.saveEntry(draft, at = setup.now)
        }

        assertEquals(WriteError.tagMismatch, error.error)

        setup.database.close()
    }

    @Test
    fun rejectsTemplateWithTagOfOtherCategory() = runTest {
        val setup = Setup.make()
        setup.saveFood(names = listOf("昼ごはん"))
        val tag = setup.foodTags()[0]
        val other = setup.category(named = "日用品")
        val entry = setup.entryDraft()

        val draft = EntryTemplateDraft(
            name = "ランチ",
            type = Entry.Kind.expense,
            amount = 980,
            categoryId = other.id,
            tagId = tag.id,
            walletId = entry.walletId,
        )

        val error = assertFailsWith<TemplateWriteException> {
            setup.database.saveTemplate(draft, at = setup.now)
        }

        assertEquals(TemplateWriteError.tagMismatch, error.error)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
    ) {
        suspend fun category(named: String): EntryCategory {
            val list = database.categoryList()

            return assertNotNull(list.categories.firstOrNull { it.name == named })
        }

        @JvmName("saveFoodNames")
        suspend fun saveFood(names: List<String>) {
            saveFood(names.map { EntryTagDraft(name = it) })
        }

        suspend fun saveFood(tags: List<EntryTagDraft>) {
            val food = category(named = "食費")
            val list = database.categoryList()
            val icon = assertNotNull(list.icons[food.iconId])

            val draft = EntryCategoryDraft(
                category = food,
                icon = icon,
            )

            database.saveCategory(
                draft,
                tags = tags,
                editing = food.id,
                at = now,
            )
        }

        suspend fun foodTags(): List<EntryTag> {
            val food = category(named = "食費")
            val list = database.categoryList()

            return list.tags.filter { it.categoryId == food.id }
        }

        suspend fun entryDraft(): EntryDraft {
            val food = category(named = "食費")
            val options = database.entryOptions()
            val date = assertNotNull(LocalDate.parse("2026-10-03"))

            return EntryDraft(
                type = Entry.Kind.expense,
                amount = 980,
                date = date,
                categoryId = food.id,
                walletId = options.wallets[0].id,
            )
        }

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)

                database.insertDefaultsIfEmpty(now)

                return Setup(
                    database = database,
                    now = now,
                )
            }
        }
    }
}
