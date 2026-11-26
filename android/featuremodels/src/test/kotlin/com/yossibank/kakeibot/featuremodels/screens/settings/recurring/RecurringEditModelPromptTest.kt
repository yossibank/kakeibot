package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlow
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
        val opened = model.state.panel.current

        model.state.panel.closeAll()

        assertEquals(RecurringPanel.Holiday, opened)
        assertNull(model.state.panel.current)
    }

    @Test
    fun showsOnePromptAtATime() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()

        model.flow.state.prompt.show(EditFlow.Prompt.hideChanges)
        val hide = model.flow.state.prompt.current

        model.flow.state.prompt.show(EditFlow.Prompt.delete)

        assertEquals(EditFlow.Prompt.hideChanges, hide)
        assertEquals(EditFlow.Prompt.delete, model.flow.state.prompt.current)
    }

    @Test
    fun closesOnlyThePromptInFront() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()

        model.flow.state.prompt.show(EditFlow.Prompt.hideChanges)
        model.flow.state.prompt.close(EditFlow.Prompt.discard)
        val kept = model.flow.state.prompt.current

        model.flow.state.prompt.close(EditFlow.Prompt.hideChanges)

        assertEquals(EditFlow.Prompt.hideChanges, kept)
        assertNull(model.flow.state.prompt.current)
    }

    @Test
    fun keepsPanelOpenBehindPrompt() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        val closed = model.state.panel.current

        model.open(RecurringPanel.Amount)
        model.flow.state.prompt.show(EditFlow.Prompt.delete)
        val opened = model.state.panel.current

        model.state.panel.closeAll()

        assertNull(closed)
        assertEquals(RecurringPanel.Amount, opened)
        assertNull(model.state.panel.current)
        assertEquals(EditFlow.Prompt.delete, model.flow.state.prompt.current)
    }

    @Test
    fun closesPanelBeforeAskingToDiscard() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.editModel()
        model.load()

        model.open(RecurringPanel.Amount)
        model.flow.back()
        val afterBack = model.flow.state.prompt.current
        model.state.press(AmountCalculator.Key.Digit(5))
        model.open(RecurringPanel.Amount)
        model.flow.close()

        assertNull(afterBack)
        assertNull(model.state.panel.current)
        assertEquals(EditFlow.Prompt.discard, model.flow.state.prompt.current)
        assertEquals(0, model.flow.state.outcome.count)
    }

    private fun ModelTestSetup.editModel() = RecurringEditModel(
        parts = parts,
        today = today,
    )
}
