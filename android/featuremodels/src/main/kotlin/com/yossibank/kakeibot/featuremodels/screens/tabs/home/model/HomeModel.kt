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
import com.yossibank.kakeibot.featuremodels.shared.model.Loadable
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.TabScreenModel
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.monthOverviewUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapLatest

class HomeModel(
    parts: ScreenParts,
    today: LocalDate,
    round: ObservationRound,
) : TabScreenModel {
    val state = State(today)
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(parts.database, parts.entryList, round)

    class State(
        today: LocalDate,
    ) {
        val task = ModelTask()

        var today: LocalDate by mutableStateOf(today)
            internal set
    }

    class Input {
        var overview: Loadable<MonthOverview> by mutableStateOf(Loadable.Loading)
            internal set
    }

    class Output(
        private val input: Input,
        private val state: State,
    ) {
        val month: YearMonth?
            get() = input.overview.value?.month

        val periodText: String
            get() {
                val period = input.overview.value?.period ?: return ""
                return PeriodText.range(period)
            }

        val usage: BudgetUsage?
            get() = input.overview.value?.budgetUsage

        val middleTitle: String
            get() = if (usage == null) "昨日の支出" else "今月の支出"

        val middleAmount: Long
            get() {
                val overview = input.overview.value ?: return 0L
                return if (usage == null) overview.yesterdayExpense else overview.monthExpense
            }

        val showsNoRecords: Boolean
            get() = input.overview.value?.list != null && recentRows.isEmpty()

        val recentRows: List<EntryRowItem> by derivedStateOf {
            val list = input.overview.value?.list

            list?.entries.orEmpty()
                .sortedWith(recentOrder)
                .take(RECENT_LIMIT)
                .mapNotNull { entry ->
                    list?.let {
                        EntryRowItem.of(
                            entry = entry,
                            list = it,
                            dayLabel = dayLabel(entry.date),
                        )
                    }
                }
        }

        private fun dayLabel(date: LocalDate): String = when (date) {
            state.today -> "今日"
            state.today.adding(days = -1) -> "昨日"
            else -> date.monthDayText
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
        val round: ObservationRound,
    )

    override val task: ModelTask
        get() = state.task

    override val isLoadFailed: Boolean
        get() = false

    override fun setToday(today: LocalDate) {
        state.today = today
    }

    override suspend fun observe() {
        dependencies.round.each { observeOverview() }
    }

    override fun retry() {
        dependencies.round.restart()
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    private suspend fun observeOverview() {
        val overviews = snapshotFlow { state.today }.flatMapLatest { day ->
            dependencies.database.monthOverviewUpdates(
                on = day,
                list = dependencies.entryList,
            )
        }

        state.task.observe(
            values = overviews,
            failure = loadFailedMessage,
            into = input::overview,
        )
    }

    companion object {
        const val loadFailedMessage = "記録を読めませんでした"
    }
}
