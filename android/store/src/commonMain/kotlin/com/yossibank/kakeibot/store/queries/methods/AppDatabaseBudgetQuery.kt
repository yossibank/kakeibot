package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.BudgetRecord
import com.yossibank.kakeibot.store.records.rows.budget
import kotlinx.coroutines.flow.Flow

fun AppDatabase.budgetUpdates(): Flow<List<Budget>> = observation("budget") {
    fetchBudgets()
}

suspend fun AppDatabase.budgets(): List<Budget> = read {
    fetchBudgets()
}

internal suspend fun AppDatabase.fetchBudgets(): List<Budget> = budgetDao()
    .inMonthOrder()
    .map { it.decoded(BudgetRecord::budget) }
