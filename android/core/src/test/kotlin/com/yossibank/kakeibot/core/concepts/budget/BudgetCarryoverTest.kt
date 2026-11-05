package com.yossibank.kakeibot.core.concepts.budget

import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class BudgetCarryoverTest {
    @Test
    fun returnsZeroWithoutStart() {
        val budgets = listOf(budget("2026-01", 50000))

        val result = budgets.carryover(
            into = month("2026-10"),
            from = null,
        ) { 0 }

        assertEquals(0, result)
    }

    @Test
    fun accumulatesRemainingOfEachMonth() {
        val budgets = listOf(budget("2026-01", 50000))

        val expenses = mapOf(
            "2026-07" to 40000,
            "2026-08" to 50000,
            "2026-09" to 30000,
        )

        val result = budgets.carryover(
            into = month("2026-10"),
            from = month("2026-07"),
        ) { (expenses[it.toString()] ?: 0).toLong() }

        assertEquals(30000, result)
    }

    @Test
    fun subtractsOverspentMonth() {
        val budgets = listOf(budget("2026-01", 50000))

        val expenses = mapOf(
            "2026-08" to 70000,
            "2026-09" to 40000,
        )

        val result = budgets.carryover(
            into = month("2026-10"),
            from = month("2026-08"),
        ) { (expenses[it.toString()] ?: 0).toLong() }

        assertEquals(-10000, result)
    }

    @Test
    fun restartsAfterMonthWithoutBudget() {
        val budgets = listOf(
            budget("2026-01", 50000),
            budget("2026-08", null),
            budget("2026-09", 50000),
        )

        val result = budgets.carryover(
            into = month("2026-11"),
            from = month("2026-07"),
        ) { 10000 }

        assertEquals(80000, result)
    }

    @Test
    fun returnsZeroWhenMonthIsNotAfterStart() {
        val budgets = listOf(budget("2026-01", 50000))
        val start = month("2026-10")

        val same = budgets.carryover(
            into = start,
            from = start,
        ) { 0 }

        val earlier = budgets.carryover(
            into = month("2026-09"),
            from = start,
        ) { 0 }

        assertEquals(0, same)
        assertEquals(0, earlier)
    }

    @Test
    fun addsStartMonthFromNextMonth() {
        val budgets = listOf(budget("2026-01", 50000))

        val result = budgets.carryover(
            into = month("2026-11"),
            from = month("2026-10"),
        ) { 20000 }

        assertEquals(30000, result)
    }

    @Test
    fun ignoresCategoryBudgets() {
        val budgets = listOf(
            budget("2026-01", 50000),
            Budget(
                categoryId = Identifier(),
                fromMonth = month("2026-01"),
                amount = 10000,
            ),
        )

        val result = budgets.carryover(
            into = month("2026-10"),
            from = month("2026-09"),
        ) { 20000 }

        assertEquals(30000, result)
    }

    @Test
    fun sumsWithoutWrappingAround() {
        val limit = 999_999_999
        val budgets = listOf(budget("2026-01", limit))

        val result = budgets.carryover(
            into = month("2026-04"),
            from = month("2026-01"),
        ) { 0L }

        assertEquals(3L * limit, result)
    }

    private fun budget(
        from: String,
        amount: Int?,
    ): Budget = Budget(
        categoryId = null,
        fromMonth = month(from),
        amount = amount,
    )

    private fun month(text: String): YearMonth = assertNotNull(YearMonth.parse(text))
}
