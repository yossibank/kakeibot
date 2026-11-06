package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.templates
import com.yossibank.kakeibot.store.writes.methods.TemplateWriteError
import com.yossibank.kakeibot.store.writes.methods.TemplateWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.deleteTemplate
import com.yossibank.kakeibot.store.writes.methods.reorderTemplates
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.restoreEntry
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import com.yossibank.kakeibot.store.writes.methods.setTemplateHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryTemplateWriteTest {
    @Test
    fun addsTemplatesInOrder() = runTest {
        val setup = Setup.make()
        val coffee = setup.draft.copy(name = "コーヒー")

        val lunch = setup.database.saveTemplate(setup.draft, at = setup.now)
        val saved = setup.database.saveTemplate(coffee, at = setup.now)
        val templates = setup.database.templates()

        assertEquals(0, lunch.sortOrder)
        assertEquals(1, saved.sortOrder)
        assertEquals(listOf("ランチ", "コーヒー"), templates.map { it.name })

        setup.database.close()
    }

    @Test
    fun hidesAndShowsTemplate() = runTest {
        val setup = Setup.make()

        val saved = setup.database.saveTemplate(setup.draft, at = setup.now)

        setup.database.setTemplateHidden(
            saved.id,
            isHidden = true,
            at = setup.now,
        )

        val shown = setup.database.templates()
        val all = setup.database.templates(includingHidden = true)

        setup.database.setTemplateHidden(
            saved.id,
            isHidden = false,
            at = setup.now,
        )

        val restored = setup.database.templates()

        assertTrue(shown.isEmpty())
        assertEquals(setup.now, all.firstOrNull()?.archivedAt)
        assertEquals(listOf(saved.id), restored.map { it.id })

        setup.database.close()
    }

    @Test
    fun updatesAndDeletesTemplate() = runTest {
        val setup = Setup.make()
        val later = setup.now.plusSeconds(60)
        val edited = setup.draft.copy(amount = null)

        val saved = setup.database.saveTemplate(setup.draft, at = setup.now)

        val updated = setup.database.saveTemplate(
            edited,
            editing = saved.id,
            at = later,
        )

        val afterUpdate = setup.database.templates()
        setup.database.deleteTemplate(saved.id)
        val afterDelete = setup.database.templates()

        assertEquals(saved.id, updated.id)
        assertNull(afterUpdate.firstOrNull()?.amount)
        assertTrue(afterDelete.isEmpty())

        setup.database.close()
    }

    @Test
    fun reordersTemplates() = runTest {
        val setup = Setup.make()
        val names = listOf("ランチ", "コーヒー", "定期")

        for (name in names) {
            setup.database.saveTemplate(setup.draft.copy(name = name), at = setup.now)
        }

        val reversed = setup.database.templates().map { it.id }.reversed()

        setup.database.reorderTemplates(
            reversed,
            at = setup.now,
        )

        val reordered = setup.database.templates()

        assertEquals(names.reversed(), reordered.map { it.name })

        setup.database.close()
    }

    @Test
    fun clearsTemplateOfEntriesWhenDeleted() = runTest {
        val setup = Setup.make()
        val today = assertNotNull(LocalDate.of(year = 2026, month = 10, day = 3))

        val template = setup.database.saveTemplate(setup.draft, at = setup.now)
        val draft = assertNotNull(template.entryDraft(on = today))
        val entry = setup.database.saveEntry(draft, at = setup.now)

        setup.database.deleteTemplate(template.id)
        val kept = setup.database.entry(entry.id)
        setup.database.deleteEntry(entry.id)
        setup.database.restoreEntry(entry)
        val restored = setup.database.entry(entry.id)

        assertEquals(template.id, entry.templateId)
        assertEquals(980, kept?.amount)
        assertNull(kept?.templateId)
        assertNull(restored?.templateId)

        setup.database.close()
    }

    @Test
    fun restoresDeletedTemplateWithItsEntries() = runTest {
        val setup = Setup.make()
        val today = assertNotNull(LocalDate.of(year = 2026, month = 10, day = 3))

        val template = setup.database.saveTemplate(setup.draft, at = setup.now)
        val draft = assertNotNull(template.entryDraft(on = today))
        val entry = setup.database.saveEntry(draft, at = setup.now)

        val deletion = setup.database.deleteTemplate(template.id)
        setup.database.restore(deletion)
        val templates = setup.database.templates()
        val restored = setup.database.entry(entry.id)

        assertEquals(listOf(template.id), templates.map { it.id })
        assertEquals(template.id, restored?.templateId)

        setup.database.close()
    }

    @Test
    fun rejectsUnknownTemplate() = runTest {
        val setup = Setup.make()

        val error = assertFailsWith<TemplateWriteException> {
            setup.database.saveTemplate(
                setup.draft,
                editing = Identifier(),
                at = setup.now,
            )
        }

        assertEquals(TemplateWriteError.templateNotFound, error.error)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val draft: EntryTemplateDraft,
    ) {
        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)

                database.insertDefaultsIfEmpty(now)

                val options = database.entryOptions()

                val draft = EntryTemplateDraft(
                    name = "ランチ",
                    type = Entry.Kind.expense,
                    amount = 980,
                    categoryId = options.expenseCategories[0].id,
                    walletId = options.wallets[0].id,
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
