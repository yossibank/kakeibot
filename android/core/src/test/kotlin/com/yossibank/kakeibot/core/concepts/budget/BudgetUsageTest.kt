package com.yossibank.kakeibot.core.concepts.budget

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class BudgetUsageTest(
    private val fixture: UsageCase,
) {
    @Serializable
    data class UsageCase(
        val summary: String,
        val budget: Int,
        val spent: Int,
        val today: LocalDate,
        val periodEnd: LocalDate,
        val remaining: Long,
        val daysLeft: Int,
        val isOver: Boolean,
        val isNearLimit: Boolean,
    ) {
        override fun toString(): String = summary
    }

    @Test
    fun countsRemainingAndDaysLeft() {
        val usage = BudgetUsage(
            budget = fixture.budget,
            spent = fixture.spent.toLong(),
            today = fixture.today,
            periodEnd = fixture.periodEnd,
        )

        assertEquals(fixture.remaining, usage.remaining)
        assertEquals(fixture.daysLeft, usage.daysLeft)
        assertEquals(fixture.isOver, usage.isOver)
        assertEquals(fixture.isNearLimit, usage.isNearLimit)
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<UsageCase> = CoreFixture.cases("budget/budget-usage.json", UsageCase.serializer())
    }
}
