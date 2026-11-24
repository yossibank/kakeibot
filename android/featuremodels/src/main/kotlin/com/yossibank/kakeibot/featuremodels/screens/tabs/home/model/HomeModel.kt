package com.yossibank.kakeibot.featuremodels.screens.tabs.home.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryRowItem
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.monthOverviewUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapLatest

class HomeModel(
    database: AppDatabase,
    entryList: Flow<EntryList>,
    today: LocalDate,
) {
    val state = State(today)
    val input = Input()
    val output = Output(input)

    private val dependencies = Dependencies(database, entryList)

    class State(
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)
    }

    class Input {
        var overview: MonthOverview? by mutableStateOf(null)
            internal set
    }

    class Output(
        private val input: Input,
    ) {
        val month: YearMonth?
            get() = input.overview?.month

        val periodText: String
            get() {
                val period = input.overview?.period ?: return ""
                return PeriodText.range(period)
            }

        val usage: BudgetUsage?
            get() = input.overview?.budgetUsage

        val recentRows: List<EntryRowItem> by derivedStateOf {
            val list = input.overview?.list

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

        private companion object {
            const val RECENT_LIMIT = 5

            val recentOrder: Comparator<Entry> =
                compareByDescending<Entry> { it.date }.thenByDescending { it.createdAt }
        }
    }

    private class Dependencies(
        val database: AppDatabase,
        val entryList: Flow<EntryList>,
    )

    @OptIn(ExperimentalCoroutinesApi::class)
    suspend fun observe() {
        snapshotFlow { state.today }
            .flatMapLatest { day ->
                dependencies.database.monthOverviewUpdates(
                    on = day,
                    list = dependencies.entryList,
                )
            }.collect { input.overview = it }
    }
}
