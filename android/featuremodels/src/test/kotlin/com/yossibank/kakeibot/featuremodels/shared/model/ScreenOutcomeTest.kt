package com.yossibank.kakeibot.featuremodels.shared.model

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNull

class ScreenOutcomeTest {
    @Test
    fun startsWithoutValue() {
        val outcome = ScreenOutcome<Int>()

        assertNull(outcome.value)
        assertEquals(0, outcome.count)
    }

    @Test
    fun reportsSameValueSentTwiceAsChange() {
        val outcome = ScreenOutcome<Int>()

        outcome.send(1)
        val first = outcome.count
        val firstValue = outcome.value
        outcome.send(1)

        assertEquals(1, firstValue)
        assertEquals(1, outcome.value)
        assertNotEquals(first, outcome.count)
    }
}
