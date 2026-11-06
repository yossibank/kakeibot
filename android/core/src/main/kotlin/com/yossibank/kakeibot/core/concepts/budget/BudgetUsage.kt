package com.yossibank.kakeibot.core.concepts.budget

import com.yossibank.kakeibot.core.concepts.date.LocalDate

@ConsistentCopyVisibility
data class BudgetUsage private constructor(
    val baseBudget: Int,
    val carryover: Long,
    val spent: Long,
    val daysLeft: Int,
) {
    val budget: Long
        get() = baseBudget + carryover

    val remaining: Long
        get() = budget - spent

    val isOver: Boolean
        get() = spent > budget

    val isNearLimit: Boolean
        get() = budget > 0 && !isOver && spent * 5 >= budget * 4

    val progress: Double
        get() {
            if (budget <= 0) {
                return 1.0
            }

            val ratio = spent.toDouble() / budget.toDouble()

            return minOf(ratio, 1.0)
        }

    companion object {
        operator fun invoke(
            budget: Int,
            carryover: Long = 0,
            spent: Long,
            today: LocalDate,
            periodEnd: LocalDate,
        ): BudgetUsage {
            val days = periodEnd.dayNumber - today.dayNumber + 1

            return BudgetUsage(
                baseBudget = budget,
                carryover = carryover,
                spent = spent,
                daysLeft = maxOf(days, 1),
            )
        }
    }
}
