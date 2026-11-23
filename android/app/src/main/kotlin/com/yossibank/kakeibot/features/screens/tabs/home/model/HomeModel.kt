package com.yossibank.kakeibot.features.screens.tabs.home.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.features.shared.entrylist.EntryRowItem
import com.yossibank.kakeibot.features.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.monthOverviewUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapLatest

class HomeModel(
    private val database: AppDatabase,
    private val entryList: Flow<EntryList>,
    today: LocalDate,
) {
    var today: LocalDate by mutableStateOf(today)

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

    val recentRows: List<EntryRowItem> by derivedStateOf {
        val list = overview?.list

        list?.entries.orEmpty()
            .sortedWith(recentOrder)
            .take(RECENT_LIMIT)
            .mapNotNull { entry ->
                list?.let {
                    EntryRowItem.of(
                        entry = entry,
                        list = it,
                        dayLabel = entry.date.monthDayText,
                    )
                }
            }
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    suspend fun observe() {
        snapshotFlow { today }
            .flatMapLatest { day ->
                database.monthOverviewUpdates(
                    on = day,
                    list = entryList,
                )
            }.collect { overview = it }
    }

    private companion object {
        const val RECENT_LIMIT = 5

        val recentOrder: Comparator<Entry> =
            compareByDescending<Entry> { it.date }.thenByDescending { it.createdAt }
    }
}
