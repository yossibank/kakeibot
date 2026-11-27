package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class FieldFocusTest {
    @Test
    fun startsOnCategoryMovingForward() {
        val focus = EntryModel.FieldFocus()

        assertEquals(EntryModel.Field.Category, focus.field)
        assertTrue(focus.isForward)
    }

    @Test
    fun movesBackwardToAnEarlierField() {
        val focus = EntryModel.FieldFocus()
            .moved(to = EntryModel.Field.Amount, type = Entry.Kind.expense)
            .moved(to = EntryModel.Field.Category, type = Entry.Kind.expense)

        assertEquals(EntryModel.Field.Category, focus.field)
        assertFalse(focus.isForward)
    }

    @Test
    fun sendsTransferOnlyFieldsToAmountOutsideTransfers() {
        val focus = EntryModel.FieldFocus()
            .moved(to = EntryModel.Field.Fee, type = Entry.Kind.expense)

        assertEquals(EntryModel.Field.Amount, focus.field)
        assertTrue(focus.isForward)
    }
}
