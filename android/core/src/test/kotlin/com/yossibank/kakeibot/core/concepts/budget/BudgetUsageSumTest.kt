package com.yossibank.kakeibot.core.concepts.budget

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class BudgetUsageSumTest {
    @Test
    fun addsWithoutWrappingAround() {
        val limit = 999_999_999
        val today = assertNotNull(LocalDate.parse("2026-10-01"))

        val usage = BudgetUsage(
            budget = limit,
            carryover = 2L * limit,
            spent = 3L * limit,
            today = today,
            periodEnd = today,
        )

        assertEquals(3L * limit, usage.budget)
        assertEquals(0L, usage.remaining)
    }
}
