package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.writes.methods.entryItems
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelItemTest {
    @Test
    fun savesItemsWithEntry() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.addItem(item("牛乳", amount = 400))
        model.save()
        val entry = setup.database.entryList().entries.first()

        assertEquals(400, entry.amount)
        assertEquals(listOf("牛乳"), setup.database.entryItems(of = entry.id).map { it.name })
    }

    @Test
    fun followsItemTotalWhileNoDifference() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.addItem(item("牛乳", amount = 396))
        model.addItem(item("パン", amount = 250))
        val followed = model.output.amount
        model.updateItem(index = 1, item = item("パン", amount = 200))
        val updated = model.output.amount
        model.press(9)
        model.addItem(item("卵", amount = 100))
        val typed = model.output.amount
        val adjustment = model.output.itemAdjustment
        model.adjustToItems()

        assertEquals(646, followed)
        assertEquals(596, updated)
        assertEquals(9, typed)
        assertEquals(-687L, adjustment)
        assertEquals(696, model.output.amount)
    }

    @Test
    fun restoresRemovedItemInPlace() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.addItem(item("牛乳", amount = 396))
        model.addItem(item("パン", amount = 250))

        val removed = checkNotNull(model.removeItem(index = 0))
        val afterRemove = model.output.amount
        model.restoreItem(removed)

        assertEquals(250, afterRemove)
        assertEquals(listOf("牛乳", "パン"), model.state.form.items.map { it.name })
        assertEquals(646, model.output.amount)
    }

    @Test
    fun followsItemTotalWithTax() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.addItem(
            item("牛乳", amount = 396, quantity = 2, taxRate = AmountCalculator.TaxRate.reduced),
        )
        model.addItem(item("食パン", amount = 250, taxRate = AmountCalculator.TaxRate.reduced))
        model.addItem(item("洗剤", amount = 398, taxRate = AmountCalculator.TaxRate.standard))
        model.addItem(item("弁当", amount = 540))

        assertEquals(1584L, model.output.itemTotals.subtotal)
        assertEquals(listOf(51L, 39L), model.output.itemTotals.taxes.map { it.amount })
        assertEquals(1674, model.output.amount)
        assertEquals(0L, model.output.itemAdjustment)
        assertEquals(4, model.output.state.form.items.size)
        assertEquals(5, model.output.itemCount)
    }

    @Test
    fun keepsAmountWhenItemTotalIsNegative() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)
        model.addItem(item("値引", amount = -30))

        model.adjustToItems()

        assertFalse(model.output.canAdjustToItems)
        assertEquals(5, model.output.amount)
        assertTrue(model.output.hasItemAdjustment)
    }

    @Test
    fun editsStoreAsFirstMemoLine() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.state.store = "青葉"
        val added = model.state.form.memo
        model.state.update { copy(memo = "若葉\n特売") }
        model.state.store = "青葉\n本店"

        assertEquals("青葉", added)
        assertEquals("青葉 本店\n特売", model.state.form.memo)
        assertEquals("青葉 本店", model.state.store)
    }

    @Test
    fun suggestsRecentItemNames() = modelTest(today = "2026-10-12") { setup ->
        setup.save(
            Entry.Kind.expense,
            amount = 500,
            on = setup.today,
            items = listOf(
                item("牛乳", amount = 200),
                item("低脂肪乳", amount = 200),
                item("パン", amount = 100),
            ),
        )
        val model = setup.loadedModel()

        val all = model.output.itemNameSuggestions(text = " ")
        val milk = model.output.itemNameSuggestions(text = "乳")
        val exact = model.output.itemNameSuggestions(text = "パン")

        assertEquals(setOf("牛乳", "低脂肪乳", "パン"), all.toSet())
        assertEquals(setOf("牛乳", "低脂肪乳"), milk.toSet())
        assertTrue(exact.isEmpty())
    }

    @Test
    fun showsQuantityOnlyWhenMany() {
        val pair = item("牛乳", amount = 396, quantity = 2)
        val uneven = item("卵", amount = 200, quantity = 3)
        val single = item("パン", amount = 250)

        assertEquals("2 × ¥198", pair.quantityText())
        assertEquals("×3", uneven.quantityText())
        assertNull(single.quantityText())
    }

    @Test
    fun splitsAmountIntoUnitPrice() {
        val pair = item("牛乳", amount = 396, quantity = 2)
        val odd = item("卵", amount = 100, quantity = 3)

        assertEquals(198 to 2, pair.unitPrice())
        assertEquals(100 to 1, odd.unitPrice())
    }

    @Test
    fun loadsItemsWhenEditing() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(
            Entry.Kind.expense,
            amount = 500,
            on = setup.today,
            items = listOf(item("パン", amount = 250)),
        )
        val model = setup.loadedModel(editing = entry.id)

        val loaded = model.state.form.items
        model.removeItem(index = 0)

        assertEquals(listOf(item("パン", amount = 250)), loaded)
        assertEquals(500, model.output.amount)
    }

    @Test
    fun dropsItemsFromTransfer() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.addItem(item("牛乳", amount = 400))

        model.select(type = Entry.Kind.transfer)
        model.save()
        val entry = setup.database.entryList().entries.first()

        assertFalse(model.output.showsItems)
        assertEquals(Entry.Kind.transfer, entry.type)
        assertTrue(setup.database.entryItems(of = entry.id).isEmpty())
        assertNotEquals(entry.walletId, entry.toWalletId)
    }
}
