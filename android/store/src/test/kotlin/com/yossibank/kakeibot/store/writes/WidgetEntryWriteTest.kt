package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.category.EntryTagDraft
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.recurring.billMonth
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.widgetEntry
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.support.insertCardBill
import com.yossibank.kakeibot.store.writes.methods.WidgetEntryError
import com.yossibank.kakeibot.store.writes.methods.WidgetEntryException
import com.yossibank.kakeibot.store.writes.methods.entryDraft
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import com.yossibank.kakeibot.store.writes.methods.recordFromWidget
import com.yossibank.kakeibot.store.writes.methods.saveTags
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import com.yossibank.kakeibot.store.writes.methods.undoWidgetEntry
import com.yossibank.kakeibot.store.writes.types.WidgetRecord
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WidgetEntryWriteTest {
    @Test
    fun recordsTemplateAndRemembersEntry() = runTest {
        val setup = Setup.make()

        val template = setup.database.saveTemplate(setup.draft, at = setup.now)

        val entry = setup.database.recordFromWidget(
            template.id,
            on = setup.today,
            at = setup.now,
        )

        val saved = setup.database.entry(entry.id)
        val remembered = setup.database.setting(SettingKey.widgetEntry)

        assertEquals(980, saved?.amount)
        assertEquals(setup.today, saved?.date)
        assertEquals(template.id, saved?.templateId)
        assertEquals(entry.id, remembered?.entryId)

        setup.database.close()
    }

    @Test
    fun undoDeletesEntryAndForgetsIt() = runTest {
        val setup = Setup.make()

        val template = setup.database.saveTemplate(setup.draft, at = setup.now)

        val entry = setup.database.recordFromWidget(
            template.id,
            on = setup.today,
            at = setup.now,
        )

        setup.database.undoWidgetEntry(entry.id)
        val deleted = setup.database.entry(entry.id)
        val remembered = setup.database.setting(SettingKey.widgetEntry)

        assertNull(deleted)
        assertNull(remembered)

        setup.database.close()
    }

    @Test
    fun dropsArchivedTagOfTemplate() = runTest {
        val setup = Setup.make()
        val food = assertNotNull(setup.draft.categoryId)

        val tag = setup.database.saveTags(
            listOf(EntryTagDraft(name = "朝ごはん")),
            categoryId = food,
            at = setup.now,
        )[0]

        val template = setup.database.saveTemplate(
            setup.draft.copy(tagId = tag.id),
            at = setup.now,
        )

        val kept = setup.database.recordFromWidget(
            template.id,
            on = setup.today,
            at = setup.now,
        )

        setup.database.saveTags(
            emptyList(),
            categoryId = food,
            at = setup.now,
        )

        val dropped = setup.database.recordFromWidget(
            template.id,
            on = setup.today,
            at = setup.now,
        )

        assertEquals(tag.id, kept.tagId)
        assertNull(dropped.tagId)

        setup.database.close()
    }

    @Test
    fun buildsDraftWithoutArchivedTag() = runTest {
        val setup = Setup.make()
        val food = assertNotNull(setup.draft.categoryId)

        val tag = setup.database.saveTags(
            listOf(EntryTagDraft(name = "朝ごはん")),
            categoryId = food,
            at = setup.now,
        )[0]

        val template = setup.database.saveTemplate(
            setup.draft.copy(tagId = tag.id),
            at = setup.now,
        )

        val before = setup.database.entryDraft(
            template,
            on = setup.today,
        )

        setup.database.saveTags(
            emptyList(),
            categoryId = food,
            at = setup.now,
        )

        val after = setup.database.entryDraft(
            template,
            on = setup.today,
        )

        assertEquals(tag.id, before?.tagId)
        assertNull(after?.tagId)
        assertEquals(template.id, after?.templateId)

        setup.database.close()
    }

    @Test
    fun buildsDraftWithShiftedBillMonth() = runTest {
        val setup = Setup.make()
        val bill = setup.database.insertCardBill(at = setup.now)

        val draft = setup.draft.copy(
            walletId = bill.toWalletId,
            billShift = 1,
        )

        val template = setup.database.saveTemplate(draft, at = setup.now)

        val entryDraft = setup.database.entryDraft(
            template,
            on = setup.today,
        )

        val expected = bill.billMonth(
            used = setup.today,
            shift = 1,
        )

        assertNotNull(entryDraft?.billMonth)
        assertEquals(expected, entryDraft?.billMonth)

        setup.database.close()
    }

    @Test
    fun buildsDraftWithoutBillMonthForUsualBill() = runTest {
        val setup = Setup.make()
        val bill = setup.database.insertCardBill(at = setup.now)
        val draft = setup.draft.copy(walletId = bill.toWalletId)

        val template = setup.database.saveTemplate(draft, at = setup.now)

        val entryDraft = setup.database.entryDraft(
            template,
            on = setup.today,
        )

        assertNotNull(entryDraft)
        assertNull(entryDraft.billMonth)

        setup.database.close()
    }

    @Test
    fun undoRestoresNoSpendDayClearedByWidget() = runTest {
        val setup = Setup.make()

        setup.database.markNoSpendDay(
            setup.today,
            at = setup.now,
        )

        val template = setup.database.saveTemplate(setup.draft, at = setup.now)

        val entry = setup.database.recordFromWidget(
            template.id,
            on = setup.today,
            at = setup.now,
        )

        val cleared = setup.database.snapshot().noSpendDays
        setup.database.undoWidgetEntry(entry.id)
        val restored = setup.database.snapshot().noSpendDays
        val remembered = setup.database.setting(SettingKey.widgetEntry)

        assertTrue(cleared.isEmpty())
        assertEquals(listOf(setup.today), restored.map { it.date })
        assertNull(remembered)

        setup.database.close()
    }

    @Test
    fun readsBothWidgetRecordForms() {
        val id = Identifier<Entry>()
        val date = assertNotNull(LocalDate.parse("2026-10-03"))

        val expected = WidgetRecord(
            entryId = id,
            clearedNoSpendDate = date,
        )

        val plain = WidgetRecord.parse(id.toString())
        val withDate = WidgetRecord.parse("$id,2026-10-03")

        assertEquals(WidgetRecord(entryId = id), plain)
        assertEquals(expected, withDate)
    }

    @Test
    fun rejectsTemplateWithoutAmount() = runTest {
        val setup = Setup.make()
        val draft = setup.draft.copy(amount = null)

        val template = setup.database.saveTemplate(draft, at = setup.now)

        val error = assertFailsWith<WidgetEntryException> {
            setup.database.recordFromWidget(
                template.id,
                on = setup.today,
                at = setup.now,
            )
        }

        assertEquals(WidgetEntryError.amountMissing, error.error)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val today: LocalDate,
        val draft: EntryTemplateDraft,
    ) {
        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)
                val today = assertNotNull(LocalDate.of(year = 2026, month = 10, day = 3))

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
                    today = today,
                    draft = draft,
                )
            }
        }
    }
}
