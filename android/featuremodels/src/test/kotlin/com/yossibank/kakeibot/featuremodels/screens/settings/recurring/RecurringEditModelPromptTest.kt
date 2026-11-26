package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.modelTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class RecurringEditModelPromptTest {
    @Test
    fun opensOnePanelAtATime() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()

        model.open(RecurringPanel.Amount)
        model.open(RecurringPanel.Holiday)
        val opened = model.state.panel

        model.state.panel = null

        assertEquals(RecurringPanel.Holiday, opened)
        assertNull(model.state.panel)
    }

    @Test
    fun showsOnePromptAtATime() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()

        model.state.ask(RecurringEditPrompt.Hide)
        val hide = model.state.prompt

        model.state.ask(RecurringEditPrompt.Delete)

        assertEquals(RecurringEditPrompt.Hide, hide)
        assertEquals(RecurringEditPrompt.Delete, model.state.prompt)
    }

    @Test
    fun closesOnlyThePromptInFront() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()

        model.state.ask(RecurringEditPrompt.Hide)
        model.state.closePrompt(RecurringEditPrompt.Discard)
        val kept = model.state.prompt

        model.state.closePrompt(RecurringEditPrompt.Hide)

        assertEquals(RecurringEditPrompt.Hide, kept)
        assertNull(model.state.prompt)
    }

    @Test
    fun keepsPanelOpenBehindPrompt() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        val closed = model.state.panel

        model.open(RecurringPanel.Amount)
        model.state.ask(RecurringEditPrompt.Delete)
        val opened = model.state.panel

        model.state.panel = null

        assertNull(closed)
        assertEquals(RecurringPanel.Amount, opened)
        assertNull(model.state.panel)
        assertEquals(RecurringEditPrompt.Delete, model.state.prompt)
    }

    private fun ModelTestSetup.editModel() = RecurringEditModel(
        parts = parts,
        today = today,
    )
}
