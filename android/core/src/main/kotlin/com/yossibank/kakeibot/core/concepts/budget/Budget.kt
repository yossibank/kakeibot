package com.yossibank.kakeibot.core.concepts.budget

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.shared.Identifier

data class Budget(
    val id: Identifier<Budget> = Identifier(),
    val categoryId: Identifier<EntryCategory>?,
    val fromMonth: YearMonth,
    val amount: Int?,
)

fun List<Budget>.amount(
    categoryId: Identifier<EntryCategory>?,
    month: YearMonth,
): Int? {
    val rows = filter { budget ->
        budget.categoryId == categoryId && budget.fromMonth <= month
    }

    return rows.maxByOrNull { it.fromMonth }?.amount
}

fun List<Budget>.carryover(
    into: YearMonth,
    from: YearMonth?,
    expense: (YearMonth) -> Int,
): Int {
    val start = from ?: return 0

    val months = generateSequence(start) { it.adding(months = 1) }.takeWhile { it < into }

    return months.fold(0) { total, current ->
        val budget = amount(
            categoryId = null,
            month = current,
        ) ?: return@fold 0

        total + budget - expense(current)
    }
}
