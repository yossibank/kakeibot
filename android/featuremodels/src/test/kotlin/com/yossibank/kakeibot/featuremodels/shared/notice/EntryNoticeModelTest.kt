package com.yossibank.kakeibot.featuremodels.shared.notice

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.item
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loadedModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.press
import com.yossibank.kakeibot.featuremodels.screens.entry.model.transferModel
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.noSpendDayUpdates
import com.yossibank.kakeibot.store.writes.methods.entryItems
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import kotlinx.coroutines.flow.first
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryNoticeModelTest {
    @Test
    fun undoesNewEntry() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)
        val model = setup.loadedModel()
        model.press(5, 0, 0)

        model.save()
        val change = model.change
        notice.show(change)
        notice.undo()
        val entries = setup.database.entryList().entries

        assertEquals("食費 ¥500 を記録しました", change.message)
        assertTrue(entries.isEmpty())
        assertEquals(EntryNoticeModel.Notice.Undone, notice.state.notice)
        assertEquals("取り消しました", notice.state.notice?.message)
    }

    @Test
    fun undoesEdit() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)
        val saved = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel(editing = saved.id)
        model.state.press(AmountCalculator.Key.Delete)

        model.save()
        val change = model.change
        val edited = setup.database.entryList().entries
        notice.show(change)
        notice.undo()
        val entries = setup.database.entryList().entries

        assertEquals("食費 ¥98 を変えました", change.message)
        assertEquals(listOf(98), edited.map { it.amount })
        assertEquals(listOf(saved.id), entries.map { it.id })
        assertEquals(listOf(980), entries.map { it.amount })
    }

    @Test
    fun undoesDelete() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)
        val saved = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel(editing = saved.id)

        model.delete()
        val change = model.change
        val deleted = setup.database.entryList().entries
        notice.show(change)
        notice.undo()
        val entries = setup.database.entryList().entries

        assertEquals("食費 ¥980 を消しました", change.message)
        assertTrue(deleted.isEmpty())
        assertEquals(listOf(saved.id), entries.map { it.id })
        assertEquals(listOf(980), entries.map { it.amount })
    }

    @Test
    fun restoresItemsWhenUndoingDelete() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)

        val saved = setup.save(
            type = Entry.Kind.expense,
            amount = 980,
            on = setup.today,
            items = listOf(item("牛乳", 396), item("食パン", 220)),
        )

        val model = setup.loadedModel(editing = saved.id)

        model.delete()
        val change = model.change
        val deleted = setup.database.entryItems(of = saved.id)
        notice.show(change)
        notice.undo()
        val restored = setup.database.entryItems(of = saved.id)

        assertTrue(deleted.isEmpty())
        assertEquals(listOf("牛乳", "食パン"), restored.map { it.name })
        assertEquals(listOf(396, 220), restored.map { it.amount })
    }

    @Test
    fun namesDeletedEntryByMemo() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)

        val saved = setup.save(
            type = Entry.Kind.expense,
            amount = 980,
            on = setup.today,
            memo = "ランチ\n同僚と",
        )

        val model = setup.loadedModel(editing = saved.id)

        model.delete()
        notice.show(model.change)
        val change = notice.output.change

        assertEquals("ランチ", change?.subject)
        assertEquals("¥980", change?.amountText)
        assertEquals("を消しました", change?.predicate)
        assertEquals("ランチ ¥980 を消しました", change?.message)
    }

    @Test
    fun namesDeletedEntryWithoutCategoryAsRecord() = modelTest(today = "2026-10-12") { setup ->
        val saved = setup.save(
            type = Entry.Kind.expense,
            amount = 980,
            on = setup.today,
            memo = "  ",
        )

        val change = EntryChange(
            kind = EntryChange.Kind.Deleted,
            entry = saved,
            label = "",
        )

        assertEquals("記録", change.subject)
        assertEquals("記録 ¥980 を消しました", change.message)
    }

    @Test
    fun keepsDeletionNoticeOnScreenTap() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)
        val saved = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel(editing = saved.id)

        model.delete()
        notice.show(model.change)
        notice.clearOnTap()
        val shown = notice.state.notice

        assertEquals(4, shown?.seconds)
        assertEquals(false, shown?.dismissesOnTap)
        assertEquals(true, notice.output.change?.isDeletion)
    }

    @Test
    fun namesTransferByWallets() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.transferModel()
        model.press(3, 0, 0, 0)

        model.save()

        assertEquals("財布 → 銀行 ¥3,000 を振り替えました", model.change.message)
    }

    @Test
    fun clearsNotice() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)
        val model = setup.loadedModel()
        model.press(5)

        model.save()
        val change = model.change
        notice.show(change)
        val shown = notice.state.notice
        notice.clear()

        assertEquals(EntryNoticeModel.Notice.Changed(change), shown)
        assertNull(notice.state.notice)
    }

    @Test
    fun restoresNoSpendMarkWhenUndoingNewEntry() = modelTest(today = "2026-10-12") { setup ->
        val notice = EntryNoticeModel(setup.parts)
        setup.database.markNoSpendDay(date = setup.today, at = setup.now)
        val model = setup.loadedModel()
        model.press(5)

        model.save()
        val cleared = setup.database.noSpendDayUpdates().first()
        notice.show(model.change)
        notice.undo()
        val restored = setup.database.noSpendDayUpdates().first()

        assertTrue(cleared.isEmpty())
        assertEquals(setOf(setup.today), restored)
    }

    @Test
    fun doesNotMakeNoSpendMarkWhenUndoingEntryOnUnmarkedDay() =
        modelTest(today = "2026-10-12") { setup ->
            val notice = EntryNoticeModel(setup.parts)
            val model = setup.loadedModel()
            model.press(5)

            model.save()
            notice.show(model.change)
            notice.undo()
            val restored = setup.database.noSpendDayUpdates().first()

            assertTrue(restored.isEmpty())
        }
}

private val EntryModel.change: EntryChange
    get() = when (val outcome = state.outcome.value) {
        is EntryModel.Outcome.Closed -> outcome.change
        is EntryModel.Outcome.Continued -> outcome.change
        null -> error("記録の結果が無い")
    }
