package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EntryModelChangeTest {
    @Test
    fun tracksChangesAfterLoading() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val loaded = model.output.isChanged

        model.press(5)
        val typed = model.output.isChanged

        model.state.press(AmountCalculator.Key.Clear)
        val cleared = model.output.isChanged

        model.state.update { copy(memo = "ランチ") }

        assertFalse(loaded)
        assertTrue(typed)
        assertFalse(cleared)
        assertTrue(model.output.isChanged)
    }

    @Test
    fun ignoresTypeSwitchOnUntouchedNewEntry() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.select(type = Entry.Kind.income)
        val income = model.output.isChanged

        model.select(type = Entry.Kind.transfer)
        val transfer = model.output.isChanged

        model.press(5)
        model.select(type = Entry.Kind.expense)

        assertFalse(income)
        assertFalse(transfer)
        assertTrue(model.output.isChanged)
    }

    @Test
    fun countsTypeSwitchOnEditedEntry() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 500, on = setup.today)
        val model = setup.loadedModel(editing = entry.id)
        val loaded = model.output.isChanged

        model.select(type = Entry.Kind.income)

        assertFalse(loaded)
        assertTrue(model.output.isChanged)
    }

    @Test
    fun closesUnchangedEntryWithoutAsking() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        val closes = model.close()

        assertTrue(closes)
        assertFalse(model.state.isConfirmingDiscard)
    }

    @Test
    fun asksBeforeClosingChangedEntry() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)

        val closes = model.close()
        val asked = model.state.isConfirmingDiscard
        model.state.keepEditing()

        assertFalse(closes)
        assertTrue(asked)
        assertFalse(model.state.isConfirmingDiscard)
        assertEquals(5, model.output.amount)
    }

    @Test
    fun closesWithoutAskingAfterStartingNext() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)
        model.save()

        model.startNext()

        assertTrue(model.close())
    }

    @Test
    fun staysUnchangedBeforeLoading() = modelTest(today = "2026-10-12") { setup ->
        val model = EntryModel(
            database = setup.database,
            clock = ScreenClock.fixed(setup.now),
            today = setup.today,
        )

        model.press(5)

        assertFalse(model.output.isChanged)
    }

    @Test
    fun ignoresAppliedTemplateIdAndRememberedCategories() =
        modelTest(today = "2026-10-12") { setup ->
            val model = setup.loadedModel()
            val first = model.state.form.categoryId

            model.select(type = Entry.Kind.income)
            model.select(type = Entry.Kind.expense)

            assertTrue(model.state.form.categoryByType.isNotEmpty())
            assertTrue(model.state.form.categoryId == first)
            assertFalse(model.output.isChanged)
        }
}
