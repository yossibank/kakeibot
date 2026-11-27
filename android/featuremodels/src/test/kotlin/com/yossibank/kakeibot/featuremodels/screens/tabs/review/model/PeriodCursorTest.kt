package com.yossibank.kakeibot.featuremodels.screens.tabs.review.model

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PeriodCursorTest {
    @Test
    fun movesBackAndForward() {
        val back = ReviewModel.PeriodCursor().moved(count = -2)
        val forward = back.moved(count = 1)

        assertEquals(-2, back.offset)
        assertEquals(-1, forward.offset)
        assertTrue(forward.canMoveForward)
    }

    @Test
    fun staysWhenMovingPastCurrent() {
        val cursor = ReviewModel.PeriodCursor()

        assertEquals(cursor, cursor.moved(count = 1))
        assertFalse(cursor.canMoveForward)
    }

    @Test
    fun restartsAtCurrent() {
        val cursor = ReviewModel.PeriodCursor(offset = -3).restarted()

        assertEquals(0, cursor.offset)
    }
}
