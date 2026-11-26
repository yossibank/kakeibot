package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.notice.EntryChange
import com.yossibank.kakeibot.featuremodels.support.failWrites
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelOutcomeTest {
    @Test
    fun placesClosedAfterSaving() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)

        val isSaved = model.save()

        val outcome = assertIs<EntryModel.Outcome.Closed>(model.state.outcome.value)

        assertTrue(isSaved)
        assertEquals(EntryChange.Kind.Recorded, outcome.change.kind)
        assertEquals(5, outcome.change.entry.amount)
        assertEquals(1, model.state.outcome.count)
    }

    @Test
    fun placesNoOutcomeWhenSavingFails() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)
        setup.database.failWrites(to = "entry")

        val isSaved = model.save()

        assertFalse(isSaved)
        assertNull(model.state.outcome.value)
    }

    @Test
    fun continuesWithNextEntryAfterSaving() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)

        val isSaved = model.saveAndContinue()
        val amount = model.output.amount
        model.press(7)
        val isNextSaved = model.saveAndContinue()

        val outcome = assertIs<EntryModel.Outcome.Continued>(model.state.outcome.value)

        assertTrue(isSaved)
        assertEquals(0, amount)
        assertTrue(isNextSaved)
        assertEquals(7, outcome.change.entry.amount)
        assertEquals(2, model.state.outcome.count)
        assertEquals(setOf(5, 7), setup.database.entryList().entries.map { it.amount }.toSet())
        assertFalse(model.output.isChanged)
    }

    @Test
    fun placesClosedAfterDeleting() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel(editing = entry.id)

        val isDeleted = model.delete()

        val outcome = assertIs<EntryModel.Outcome.Closed>(model.state.outcome.value)

        assertTrue(isDeleted)
        assertEquals(EntryChange.Kind.Deleted, outcome.change.kind)
        assertEquals(entry.id, outcome.change.entry.id)
    }
}
