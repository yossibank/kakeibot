package com.yossibank.kakeibot.featuremodels.shared.settingsparts.input

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditModel
import com.yossibank.kakeibot.featuremodels.screens.settings.templates.TemplateEditModel
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.failUpdates
import com.yossibank.kakeibot.featuremodels.support.failWrites
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.recurrings
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SettingsEditOutcomeTest {
    @Test
    fun placesSavedValueInOutcome() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.templateModel()
        model.load()
        model.state.update { copy(name = "ランチ") }

        val saved = assertNotNull(model.save())
        val outcome = assertNotNull(model.state.outcome.value)

        assertEquals(saved.id, outcome.saved?.id)
        assertNull(outcome.isHidden)
        assertNull(outcome.deletion)
        assertTrue(outcome.closes)
    }

    @Test
    fun placesNoOutcomeWhenSaveFails() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.recurringModel()
        model.load()
        model.state.press(AmountCalculator.Key.Digit(5))
        setup.database.failWrites(to = "recurring")

        val isSaved = model.save()

        assertFalse(isSaved)
        assertNull(model.state.outcome.value)
        assertEquals(0, model.state.outcome.count)
    }

    @Test
    fun reportsEachSaveAsChange() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editingModel()

        model.save()
        val first = model.state.outcome.count
        val firstValue = model.state.outcome.value
        model.save()

        assertNotNull(firstValue?.saved)
        assertNotEquals(first, model.state.outcome.count)
    }

    @Test
    fun placesHiddenInOutcome() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editingModel()

        model.setHidden(isHidden = true)
        val outcome = assertNotNull(model.state.outcome.value)

        assertEquals(true, outcome.isHidden)
        assertNull(outcome.saved)
        assertTrue(outcome.closes)
    }

    @Test
    fun placesNoOutcomeWhenHidingFails() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editingModel()
        setup.database.failWrites(to = "recurring")

        val isHidden = model.setHidden(isHidden = true)

        assertFalse(isHidden)
        assertNull(model.state.outcome.value)
    }

    @Test
    fun placesDeletionInOutcome() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editingModel()

        val deletion = model.delete()
        val outcome = assertNotNull(model.state.outcome.value)

        assertNotNull(deletion)
        assertEquals(deletion.id, outcome.deletion?.id)
        assertTrue(outcome.closes)
    }

    @Test
    fun placesSaveAndHideInOneOutcome() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editingModel()
        model.state.update { copy(memo = "家賃と管理費") }

        model.saveTogglingHidden()
        val outcome = assertNotNull(model.state.outcome.value)
        val recurrings = setup.database.recurrings(includingHidden = true)

        assertNotNull(outcome.saved)
        assertEquals(true, outcome.isHidden)
        assertTrue(outcome.closes)
        assertEquals(1, model.state.outcome.count)
        assertTrue(model.input.isHidden)
        assertEquals(listOf("家賃と管理費"), recurrings.map { it.memo })
        assertNotNull(recurrings.first().archivedAt)
    }

    @Test
    fun keepsSheetOpenWhenHidingAfterSaveFails() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editingModel()
        model.state.update { copy(memo = "家賃と管理費") }
        setup.database.failUpdates(to = "recurring", changing = "archived_at")

        model.saveTogglingHidden()
        val outcome = assertNotNull(model.state.outcome.value)

        assertNotNull(outcome.saved)
        assertNull(outcome.isHidden)
        assertFalse(outcome.closes)
        assertFalse(model.input.isHidden)
        assertEquals("保存できませんでした", model.state.task.message)
    }

    @Test
    fun savesWithoutHidingAfterFailedSaveAndHide() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editingModel()
        model.state.update { copy(memo = "家賃と管理費") }
        setup.database.failWrites(to = "recurring")

        val isSaved = model.saveTogglingHidden()

        assertFalse(isSaved)
        assertNull(model.state.outcome.value)
        assertFalse(model.input.isHidden)
    }
}

private fun ModelTestSetup.templateModel() = TemplateEditModel(
    database = database,
    clock = ScreenClock.fixed(now),
    draft = EntryTemplateDraft(
        name = "",
        type = Entry.Kind.expense,
        amount = null,
        categoryId = null,
        walletId = null,
    ),
)

private fun ModelTestSetup.recurringModel(editingId: Identifier<Recurring>? = null) =
    RecurringEditModel(
        database = database,
        clock = ScreenClock.fixed(now),
        today = today,
        editingId = editingId,
    )

private suspend fun ModelTestSetup.editingModel(): RecurringEditModel {
    val recurring = saveRecurring(amount = 78000, day = 27, memo = "家賃")
    val model = recurringModel(editingId = recurring.id)

    model.load()
    return model
}
