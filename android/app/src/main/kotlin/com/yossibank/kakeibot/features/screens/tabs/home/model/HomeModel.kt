package com.yossibank.kakeibot.features.screens.tabs.home.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.features.shared.entrylist.EntryRowItem
import com.yossibank.kakeibot.features.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.monthOverviewUpdates
import com.yossibank.kakeibot.store.queries.types.MonthOverview

class HomeModel(
    private val database: AppDatabase,
) {
    var overview: MonthOverview? by mutableStateOf(null)
        private set

    val month: YearMonth?
        get() = overview?.month

    val periodText: String
        get() {
            val period = overview?.period ?: return ""
            return PeriodText.range(period)
        }

    val usage: BudgetUsage?
        get() = overview?.budgetUsage

    val recentRows: List<EntryRowItem>
        get() {
            val list = overview?.list ?: return emptyList()

            return list.entries
                .sortedWith(recentOrder)
                .take(RECENT_LIMIT)
                .map { entry ->
                    EntryRowItem.of(
                        entry = entry,
                        list = list,
                        dayLabel = entry.date.monthDayText,
                    )
                }
        }

    suspend fun observe(today: LocalDate) {
        database.monthOverviewUpdates(on = today).collect { overview = it }
    }

    private companion object {
        const val RECENT_LIMIT = 5

        val recentOrder: Comparator<Entry> =
            compareByDescending<Entry> { it.date }.thenByDescending { it.createdAt }
    }
}
