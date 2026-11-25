package com.yossibank.kakeibot.featuremodels.screens.tabs.records.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.date.weeks
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.entry.expenseTotal
import com.yossibank.kakeibot.core.concepts.entry.incomeTotal
import com.yossibank.kakeibot.core.concepts.entry.within
import com.yossibank.kakeibot.core.concepts.setting.RecordsLayout
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryRowItem
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.recordsLayout
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class RecordsModel(
    database: AppDatabase,
    entryList: Flow<EntryList>,
    today: LocalDate,
) {
    val state = State(today)
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(database, entryList)

    class State(
        today: LocalDate,
    ) {
        val task = ModelTask()

        var today: LocalDate by mutableStateOf(today)

        var month: YearMonth? by mutableStateOf(null)
            private set

        var selected: LocalDate? by mutableStateOf(null)
            private set

        fun move(to: YearMonth) {
            month = to
            selected = null
        }

        fun select(date: LocalDate) {
            selected = date
        }
    }

    class Input {
        var list: EntryList? by mutableStateOf(null)
            internal set

        var isLoaded: Boolean by mutableStateOf(false)
            internal set

        var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)
            internal set

        var weekStart: Weekday by mutableStateOf(Weekday.monday)
            internal set

        var layout: RecordsLayout by mutableStateOf(RecordsLayout.calendar)
            internal set
    }

    class Output(
        private val input: Input,
        private val state: State,
    ) {
        val weekdays: List<Weekday>
            get() = Weekday.week(startingOn = input.weekStart)

        val weeks: List<List<LocalDate?>>
            get() = period.weeks(startingOn = input.weekStart)

        val selectedDate: LocalDate
            get() {
                val period = period
                val date = state.selected

                return when {
                    date != null && date in period -> date
                    state.today in period -> state.today
                    else -> period.start
                }
            }

        val shownMonth: YearMonth
            get() = state.month ?: state.today.periodMonth(startingOn = input.monthStartDay)

        val period: ClosedRange<LocalDate>
            get() = shownMonth.period(startingOn = input.monthStartDay)

        val monthTitle: String
            get() = "${shownMonth.year}年 ${shownMonth.month}月"

        val periodText: String
            get() = PeriodText.range(period)

        val days: List<EntryDay> by derivedStateOf {
            input.list?.days?.within(period) ?: emptyList()
        }

        private val daysByDate: Map<LocalDate, EntryDay> by derivedStateOf {
            days.associateBy { it.date }
        }

        val expenseTotal: Long
            get() = days.expenseTotal

        val incomeTotal: Long
            get() = days.incomeTotal

        val balance: Long
            get() = incomeTotal - expenseTotal

        val balanceTitle: String
            get() = if (balance < 0) "収支 · 赤字" else "収支 · 黒字"

        fun day(on: LocalDate): EntryDay? = daysByDate[on]

        fun rows(of: EntryDay): List<EntryRowItem> {
            val list = input.list ?: return emptyList()

            return of.entries.map { entry ->
                EntryRowItem.of(
                    entry = entry,
                    list = list,
                )
            }
        }
    }

    private class Dependencies(
        val database: AppDatabase,
        val entryList: Flow<EntryList>,
    )

    suspend fun observe() {
        val database = dependencies.database

        coroutineScope {
            launch {
                observe(database.settingUpdates(SettingKey.monthStartDay)) {
                    input.monthStartDay = it
                }
            }

            launch {
                observe(database.settingUpdates(SettingKey.weekStart)) { input.weekStart = it }
            }

            launch {
                observe(database.settingUpdates(SettingKey.recordsLayout)) { input.layout = it }
            }

            launch {
                observe(dependencies.entryList) {
                    input.list = it
                    input.isLoaded = true
                }
            }
        }
    }

    fun move(months: Int) {
        state.move(to = output.shownMonth.adding(months = months))
    }

    suspend fun select(layout: RecordsLayout) {
        input.layout = layout

        ModelTask.quiet {
            dependencies.database.setSetting(
                key = SettingKey.recordsLayout,
                to = layout,
            )
        }
    }

    private suspend fun <Value> observe(
        values: Flow<Value>,
        receive: suspend (Value) -> Unit,
    ) {
        state.task.observe(
            values = values,
            failure = loadFailedMessage,
            receive = receive,
        )
    }

    companion object {
        const val loadFailedMessage = "記録を読めませんでした"
    }
}
