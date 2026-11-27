package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecurringRepaymentTest {
    @Test
    fun forgetsManualFinalWhenCountTurnsAuto() {
        val manual = RecurringRepayment().usingManualCount(final = 12_000)

        val auto = manual.usingAutoCount()

        assertFalse(manual.isCountAuto)
        assertEquals(12_000, manual.manualFinal)
        assertTrue(auto.isCountAuto)
        assertNull(auto.manualFinal)
    }

    @Test
    fun keepsManualFinalWhenLoadedOrCounted() {
        val loaded = RecurringRepayment().loaded(final = 8_000)

        val counted = loaded.counted(AmountCalculator(amount = 24)).countAuto(isAuto = false)

        assertEquals(8_000, counted.manualFinal)
        assertEquals(24, counted.count.amount)
        assertFalse(counted.isCountAuto)
    }
}
