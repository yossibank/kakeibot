package com.yossibank.kakeibot.core.concepts.budget

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class BudgetAmountTest(
    private val fixture: AmountCase,
) {
    @Serializable
    data class AmountCase(
        val summary: String,
        val budgets: List<Row>,
        val category: String? = null,
        val month: YearMonth,
        val amount: Int? = null,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class Row(
        val category: String? = null,
        val fromMonth: YearMonth,
        val amount: Int? = null,
    )

    @Test
    fun usesLatestRowUpToMonth() {
        val ids = mapOf(
            "food" to Identifier<EntryCategory>(),
            "daily" to Identifier<EntryCategory>(),
        )

        val budgets = fixture.budgets.map { row ->
            Budget(
                categoryId = row.category?.let { ids[it] },
                fromMonth = row.fromMonth,
                amount = row.amount,
            )
        }

        val amount = budgets.amount(
            categoryId = fixture.category?.let { ids[it] },
            month = fixture.month,
        )

        assertEquals(fixture.amount, amount)
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<AmountCase> = CoreFixture.cases("budget/budget-amount.json", AmountCase.serializer())
    }
}
