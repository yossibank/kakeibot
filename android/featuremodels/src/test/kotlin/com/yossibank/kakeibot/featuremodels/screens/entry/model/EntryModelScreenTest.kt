package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelScreenTest {
    @Test
    fun showsFieldWithItsDirectionAndKeypadTarget() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.transferModel()

        model.state.focus(EntryModel.Field.Fee)
        model.press(3)
        val fee = model.state.field
        val feeForward = model.state.isForward
        model.state.focus(EntryModel.Field.Transfer)
        model.press(5)

        assertEquals(EntryModel.Field.Fee, fee)
        assertTrue(feeForward)
        assertEquals(3, model.output.fee)
        assertEquals(EntryModel.Field.Transfer, model.state.field)
        assertFalse(model.state.isForward)
        assertEquals(5, model.output.amount)
    }

    @Test
    fun startsFromFirstFieldWhenTypeChanges() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.state.focus(EntryModel.Field.Date)

        model.select(type = Entry.Kind.transfer)
        val transfer = model.state.field
        model.state.focus(EntryModel.Field.Fee)
        model.press(3)
        model.select(type = Entry.Kind.income)
        model.press(5)

        assertEquals(EntryModel.Field.Transfer, transfer)
        assertEquals(EntryModel.Field.Category, model.state.field)
        assertEquals(3, model.state.feeCalculator.amount)
        assertEquals(5, model.output.amount)
    }

    @Test
    fun keepsOneShownAtATime() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.state.presented.show(EntryModel.Presented.Items)
        model.state.presented.show(EntryModel.Presented.Discard)
        val discard = model.state.presented.current
        model.state.presented.closeAll()

        assertEquals(EntryModel.Presented.Discard, discard)
        assertNull(model.state.presented.current)
    }
}
