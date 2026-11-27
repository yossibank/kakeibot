package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
import com.yossibank.kakeibot.featuremodels.support.ManualWait
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class EntryItemModelTest {
    @Test
    fun startsNextDraftWithLastTaxRate() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        items.isOpen = true
        entry.addItem(item("牛乳", amount = 200, taxRate = AmountCalculator.TaxRate.reduced))
        items.name = "パン"

        items.reset(entry)

        assertTrue(items.isOpen)
        assertTrue(items.name.isEmpty())
        assertEquals(AmountCalculator.TaxRate.reduced, items.taxRate)
        assertNull(items.editingIndex)
    }

    @Test
    fun fillsDraftFromEditedItem() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        val reduced = AmountCalculator.TaxRate.reduced
        entry.addItem(item("卵", amount = 600, quantity = 3, taxRate = reduced))

        items.edit(index = 0, item = entry.state.form.items[0])

        assertEquals("卵", items.name)
        assertEquals(200, items.unit.amount)
        assertEquals(3, items.quantityValue)
        assertEquals(reduced, items.taxRate)
        assertEquals(0, items.editingIndex)
        assertTrue(items.canSubmit)
    }

    @Test
    fun keepsReadAmountUntilPriceChanges() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        entry.addItem(item("割引セット", amount = 100, quantity = 3))

        items.edit(index = 0, item = entry.state.form.items[0])
        val keptQuantity = items.lineQuantity
        val keptAmount = items.lineAmount
        items.press(AmountCalculator.Key.Digit(5))

        assertEquals(3, keptQuantity)
        assertEquals(100L, keptAmount)
        assertEquals(1, items.lineQuantity)
        assertEquals(5L, items.lineAmount)
    }

    @Test
    fun addsItemFromDraft() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        items.name = " パン "
        items.taxRate = AmountCalculator.TaxRate.standard
        items.press(AmountCalculator.Key.Digit(2))
        items.press(AmountCalculator.Key.DoubleZero)

        items.submit(entry)

        val expected = item("パン", amount = 200, taxRate = AmountCalculator.TaxRate.standard)

        assertEquals(listOf(expected), entry.state.form.items)
        assertTrue(items.name.isEmpty())
    }

    @Test
    fun turnsDiscountNegativeAndHalvesUnit() {
        val items = EntryItemEditor(ManualWait().wait)
        items.name = "値引"
        items.press(AmountCalculator.Key.Digit(5))
        items.press(AmountCalculator.Key.DoubleZero)
        items.target = EntryItemEditor.Target.Quantity

        items.isDiscount = !items.isDiscount
        items.halveUnit()

        assertTrue(items.isDiscount)
        assertEquals(EntryItemEditor.Target.Unit, items.target)
        assertEquals(250, items.unit.amount)
        assertEquals(-250L, items.lineAmount)
    }

    @Test
    fun refusesDraftWithoutNameOrPrice() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)

        items.name = "  "
        items.press(AmountCalculator.Key.Digit(5))
        val unnamed = items.canSubmit
        items.reset(entry)
        items.name = "パン"
        val unpriced = items.canSubmit
        items.press(AmountCalculator.Key.Digit(5))

        assertFalse(unnamed)
        assertFalse(unpriced)
        assertTrue(items.canSubmit)
    }

    @Test
    fun updatesEditedItem() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))
        entry.addItem(item("パン", amount = 300))
        items.edit(index = 1, item = entry.state.form.items[1])
        items.name = "食パン"
        items.halveUnit()

        items.submit(entry)

        assertEquals(listOf("牛乳", "食パン"), entry.state.form.items.map { it.name })
        assertEquals(listOf(200, 150), entry.state.form.items.map { it.amount })
        assertFalse(items.isOpen)
    }

    @Test
    fun followsEditedRowWhenRowsAreRemovedAndRestored() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))
        entry.addItem(item("パン", amount = 300))
        items.edit(index = 1, item = entry.state.form.items[1])

        items.remove(entry, index = 0)
        val removed = items.removed.current
        val shifted = items.editingIndex
        items.restore(entry)

        assertEquals("牛乳", removed?.item?.name)
        assertEquals(0, shifted)
        assertEquals(1, items.editingIndex)
        assertEquals(listOf("牛乳", "パン"), entry.state.form.items.map { it.name })
    }

    @Test
    fun clearsRemovedItemNoticeAfterDuration() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))

        items.remove(entry, index = 0)
        setup.wait.advance(by = UndoNotice.duration - 1.seconds)
        val kept = items.removed.current
        setup.wait.advance(by = 1.seconds)

        assertEquals("牛乳", kept?.item?.name)
        assertNull(items.removed.current)
        assertTrue(entry.state.form.items.isEmpty())
    }

    @Test
    fun restoresRemovedItemBeforeDurationEnds() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.loadedModel()
        val items = EntryItemEditor(setup.wait.wait)
        entry.addItem(item("牛乳", amount = 200))
        entry.addItem(item("パン", amount = 300))

        items.remove(entry, index = 0)
        setup.wait.advance(by = UndoNotice.duration - 1.seconds)
        items.restore(entry)
        setup.wait.advance(by = 1.seconds)

        assertNull(items.removed.current)
        assertEquals(listOf("牛乳", "パン"), entry.state.form.items.map { it.name })
    }
}
