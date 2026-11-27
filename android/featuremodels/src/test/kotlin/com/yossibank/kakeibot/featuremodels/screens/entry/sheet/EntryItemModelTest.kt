package com.yossibank.kakeibot.featuremodels.screens.entry.sheet

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.addItem
import com.yossibank.kakeibot.featuremodels.screens.entry.model.item
import com.yossibank.kakeibot.featuremodels.screens.entry.model.loadedModel
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
import com.yossibank.kakeibot.featuremodels.support.ManualWait
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotSame
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class EntryItemModelTest {
    @Test
    fun startsNextDraftWithLastTaxRate() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        items.open(entry)
        entry.addItem(item("牛乳", amount = 200, taxRate = AmountCalculator.TaxRate.reduced))
        items.state.setName("パン")

        items.reset(entry)

        val draft = items.state.fields.draft
        assertTrue(items.state.presented.isSlipOpen)
        assertTrue(draft.name.isEmpty())
        assertEquals(AmountCalculator.TaxRate.reduced, draft.taxRate)
        assertNull(draft.editing)
    }

    @Test
    fun fillsDraftFromEditedItem() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        val reduced = AmountCalculator.TaxRate.reduced
        entry.addItem(item("卵", amount = 600, quantity = 3, taxRate = reduced))

        items.edit(index = 0, item = entry.state.fields.form.items[0])

        val draft = items.state.fields.draft
        assertEquals("卵", draft.name)
        assertEquals(200, draft.unit.amount)
        assertEquals(3, draft.quantityValue)
        assertEquals(reduced, draft.taxRate)
        assertEquals(0, draft.editing?.index)
        assertTrue(draft.canSubmit)
        assertTrue(items.state.presented.isSlipOpen)
    }

    @Test
    fun keepsReadAmountUntilPriceChanges() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        entry.addItem(item("割引セット", amount = 100, quantity = 3))

        items.edit(index = 0, item = entry.state.fields.form.items[0])
        val keptQuantity = items.state.fields.draft.lineQuantity
        val keptAmount = items.state.fields.draft.lineAmount
        items.state.press(AmountCalculator.Key.Digit(5))

        assertEquals(3, keptQuantity)
        assertEquals(100L, keptAmount)
        assertEquals(1, items.state.fields.draft.lineQuantity)
        assertEquals(5L, items.state.fields.draft.lineAmount)
    }

    @Test
    fun addsItemFromDraft() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        items.state.setName(" パン ")
        items.state.select(taxRate = AmountCalculator.TaxRate.standard)
        items.state.press(AmountCalculator.Key.Digit(2))
        items.state.press(AmountCalculator.Key.DoubleZero)

        items.submit(entry)

        val expected = item("パン", amount = 200, taxRate = AmountCalculator.TaxRate.standard)

        assertEquals(listOf(expected), entry.state.fields.form.items)
        assertTrue(items.state.fields.draft.name.isEmpty())
    }

    @Test
    fun turnsDiscountNegativeAndHalvesUnit() {
        val items = EntryItemModel(ManualWait().wait)
        items.state.setName("値引")
        items.state.press(AmountCalculator.Key.Digit(5))
        items.state.press(AmountCalculator.Key.DoubleZero)
        items.state.enter(EntryItemModel.Target.Quantity)

        items.state.toggleDiscount()
        items.state.halveUnit()

        val draft = items.state.fields.draft
        assertTrue(draft.isDiscount)
        assertEquals(EntryItemModel.Target.Unit, draft.target)
        assertEquals(250, draft.unit.amount)
        assertEquals(-250L, draft.lineAmount)
    }

    @Test
    fun refusesDraftWithoutNameOrPrice() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)

        items.state.setName("  ")
        items.state.press(AmountCalculator.Key.Digit(5))
        val unnamed = items.state.fields.draft.canSubmit
        items.reset(entry)
        items.state.setName("パン")
        val unpriced = items.state.fields.draft.canSubmit
        items.state.press(AmountCalculator.Key.Digit(5))

        assertFalse(unnamed)
        assertFalse(unpriced)
        assertTrue(items.state.fields.draft.canSubmit)
    }

    @Test
    fun updatesEditedItem() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))
        entry.addItem(item("パン", amount = 300))
        items.edit(index = 1, item = entry.state.fields.form.items[1])
        items.state.setName("食パン")
        items.state.halveUnit()

        items.submit(entry)

        assertEquals(listOf("牛乳", "食パン"), entry.state.fields.form.items.map { it.name })
        assertEquals(listOf(200, 150), entry.state.fields.form.items.map { it.amount })
        assertFalse(items.state.presented.isSlipOpen)
        assertNull(items.state.fields.draft.editing)
    }

    @Test
    fun followsEditedRowWhenRowsAreRemovedAndRestored() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))
        entry.addItem(item("パン", amount = 300))
        items.edit(index = 1, item = entry.state.fields.form.items[1])

        items.remove(entry, index = 0)
        val removed = items.state.notices.removed.current
        val shifted = items.state.fields.draft.editing?.index
        items.restore(entry)

        assertEquals("牛乳", removed?.item?.name)
        assertEquals(0, shifted)
        assertEquals(1, items.state.fields.draft.editing?.index)
        assertEquals(listOf("牛乳", "パン"), entry.state.fields.form.items.map { it.name })
    }

    @Test
    fun clearsRemovedItemNoticeAfterDuration() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))

        items.remove(entry, index = 0)
        setup.wait.advance(by = UndoNotice.duration - 1.seconds)
        val kept = items.state.notices.removed.current
        setup.wait.advance(by = 1.seconds)

        assertEquals("牛乳", kept?.item?.name)
        assertNull(items.state.notices.removed.current)
        assertTrue(entry.state.fields.form.items.isEmpty())
    }

    @Test
    fun restoresRemovedItemBeforeDurationEnds() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemModel(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))
        entry.addItem(item("パン", amount = 300))

        items.remove(entry, index = 0)
        setup.wait.advance(by = UndoNotice.duration - 1.seconds)
        items.restore(entry)
        setup.wait.advance(by = 1.seconds)

        assertNull(items.state.notices.removed.current)
        assertEquals(listOf("牛乳", "パン"), entry.state.fields.form.items.map { it.name })
    }

    @Test
    fun keepsDraftWhenSlipCloses() {
        val items = EntryItemModel(ManualWait().wait)
        items.edit(index = 0, item = item("牛乳", amount = 200))
        items.state.setName("豆乳")

        items.state.close()

        assertFalse(items.state.presented.isSlipOpen)
        assertNull(items.state.fields.draft.editing)
        assertEquals("豆乳", items.state.fields.draft.name)
    }

    @Test
    fun startsFreshEachTimeItemsOpen() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        entry.state.openItems()
        val first = entry.state.submodels.items
        first.open(entry)
        first.state.setName("パン")
        entry.state.presented.overlay.closeAll()

        entry.state.openItems()

        val second = entry.state.submodels.items
        assertEquals(EntryModel.Overlay.Items, entry.state.presented.overlay.current)
        assertNotSame(first, second)
        assertFalse(second.state.presented.isSlipOpen)
        assertTrue(second.state.fields.draft.name.isEmpty())
    }
}
