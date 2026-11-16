package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.budget.amount
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.queries.methods.fetchBudgets
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue

enum class BudgetWriteError {
    amountNotPositive,
}

class BudgetWriteException(
    val error: BudgetWriteError,
) : Exception(error.name)

suspend fun AppDatabase.setBudget(
    amount: Int?,
    categoryId: Identifier<EntryCategory>?,
    from: YearMonth,
) {
    if (amount != null && amount < 1) {
        throw BudgetWriteException(BudgetWriteError.amountNotPositive)
    }

    write {
        val budgets = fetchBudgets()

        val existing = budgets.firstOrNull { budget ->
            budget.categoryId == categoryId && budget.fromMonth == from
        }

        val others = budgets.filter { it.id != existing?.id }

        val inherited = others.amount(
            categoryId = categoryId,
            month = from,
        )

        if (inherited == amount) {
            existing?.let { budgetDao().delete(it.id.databaseValue) }

            return@write
        }

        if (existing != null) {
            budgetDao().update(existing.copy(amount = amount).record())
        } else {
            val budget = Budget(
                categoryId = categoryId,
                fromMonth = from,
                amount = amount,
            )

            budgetDao().insert(budget.record())
        }
    }
}
