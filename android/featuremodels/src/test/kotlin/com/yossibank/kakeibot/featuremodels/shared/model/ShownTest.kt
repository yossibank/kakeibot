package com.yossibank.kakeibot.featuremodels.shared.model

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ShownTest {
    @Test
    fun showsOnePromptAtATime() {
        val shown = Shown<Prompt>()

        shown.show(Prompt.menu)
        val menu = shown.isShowing(Prompt.menu)

        shown.show(Prompt.delete)

        assertTrue(menu)
        assertFalse(shown.isShowing(Prompt.menu))
        assertTrue(shown.isShowing(Prompt.delete))
        assertFalse(shown.isShowing(Prompt.discard))
        assertEquals(Prompt.delete, shown.current)
    }

    @Test
    fun closesOnlyThePromptInFront() {
        val shown = Shown<Prompt>()

        shown.show(Prompt.hide)
        shown.close(Prompt.discard)
        val kept = shown.isShowing(Prompt.hide)

        shown.close(Prompt.hide)

        assertTrue(kept)
        assertNull(shown.current)
    }

    @Test
    fun closesWhateverIsShown() {
        val shown = Shown(Prompt.menu)

        shown.closeAll()

        assertNull(shown.current)
    }

    private enum class Prompt {
        menu,
        discard,
        hide,
        delete,
    }
}
