package com.yossibank.kakeibot.featuremodels.screens.settings.budgets

import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.within
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped

val BudgetListModel.Output.suggestions: List<BudgetListModel.Suggestion>
    get() {
        val target = state.presented.editing ?: return emptyList()
        val month = month ?: return emptyList()
        val categoryId = target.categoryId
        val recurring = if (categoryId == null) recurringExpense else 0L
        val seen = mutableSetOf<Int>()

        return listOf(
            BudgetListModel.Suggestion(
                title = "先月",
                amount = spent(categoryId, month.adding(months = -1)).clamped,
            ),
            BudgetListModel.Suggestion(
                title = "3 か月の平均",
                amount = averageSpent(categoryId).clamped,
            ),
            BudgetListModel.Suggestion(
                title = "固定費",
                amount = recurring.clamped,
            ),
        ).filter { it.amount > 0 && seen.add(it.amount) }
    }

fun BudgetListModel.Output.usage(categoryId: Identifier<EntryCategory>?): BudgetUsage? {
    val overview = input.overview ?: return null
    val budget = amount(categoryId) ?: return null

    return BudgetUsage(
        budget = budget,
        carryover = if (categoryId == null) carryover else 0L,
        spent = spent(categoryId),
        today = overview.today,
        periodEnd = overview.period.endInclusive,
    )
}

internal fun BudgetListModel.Output.spentByCategory(
    month: YearMonth,
): Map<Identifier<EntryCategory>?, Long> {
    val overview = input.overview ?: return emptyMap()
    val period = month.period(startingOn = overview.monthStartDay)

    val expenses = overview.list?.days
        ?.within(period)
        .orEmpty()
        .flatMap { it.entries }
        .filter { it.type == Entry.Kind.expense }

    val byCategory = expenses
        .filter { it.categoryId != null }
        .groupBy { it.categoryId }
        .mapValues { (_, entries) -> entries.sumOf { it.amount.toLong() } }

    return byCategory + (null to expenses.sumOf { it.amount.toLong() })
}

private fun BudgetListModel.Output.spent(
    categoryId: Identifier<EntryCategory>?,
    month: YearMonth,
): Long = spentByCategory(month)[categoryId] ?: 0L

private fun BudgetListModel.Output.averageSpent(categoryId: Identifier<EntryCategory>?): Long {
    val overview = input.overview ?: return 0L
    val month = month ?: return 0L
    val firstDate = overview.list?.days?.minOfOrNull { it.date } ?: return 0L

    val months = (1..AVERAGE_MONTHS)
        .map { month.adding(months = -it) }
        .filter { it.period(startingOn = overview.monthStartDay).endInclusive >= firstDate }

    if (months.size < 2) {
        return 0L
    }

    val total = months.sumOf { month ->
        spent(
            categoryId = categoryId,
            month = month,
        )
    }

    val unit = months.size.toLong() * AVERAGE_UNIT

    return (total + unit - 1) / unit * AVERAGE_UNIT
}

private const val AVERAGE_MONTHS = 3
private const val AVERAGE_UNIT = 100
