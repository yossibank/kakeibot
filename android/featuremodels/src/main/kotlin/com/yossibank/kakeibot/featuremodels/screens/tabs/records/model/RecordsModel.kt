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
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts.ReviewText
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryRowItem
import com.yossibank.kakeibot.featuremodels.shared.model.ErrorNotice
import com.yossibank.kakeibot.featuremodels.shared.model.Loadable
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenEditable
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import com.yossibank.kakeibot.featuremodels.shared.model.TabScreenModel
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
    parts: ScreenParts,
    today: LocalDate,
    round: ObservationRound,
) : ScreenPerforming,
    TabScreenModel {
    val state = State(parts.wait)
    val input = Input(today)
    val output = Output(input, state)

    private val dependencies = Dependencies(parts.database, parts.entryList, round)

    data class Fields(
        val selected: LocalDate? = null,
    ) : ScreenEditable

    class State(
        wait: ScreenWait,
    ) {
        val notices = Notices(wait)
        val task = ModelTask(notices.error)

        var fields: Fields by mutableStateOf(Fields())
            private set

        var month: YearMonth? by mutableStateOf(null)
            private set

        fun move(to: YearMonth) {
            month = to
            fields = fields.copy(selected = null)
        }

        fun select(date: LocalDate) {
            fields = fields.copy(selected = date)
        }

        internal fun openCurrentMonth() {
            month = null
        }
    }

    class Notices(
        wait: ScreenWait,
    ) {
        val error = ErrorNotice(wait)
    }

    class Input(
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)
            internal set

        var list: Loadable<EntryList> by mutableStateOf(Loadable.Loading)
            internal set

        var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)
            internal set

        var weekStart: Weekday by mutableStateOf(Weekday.sunday)
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
                val date = state.fields.selected

                return when {
                    date != null && date in period -> date
                    input.today in period -> input.today
                    else -> period.start
                }
            }

        val shownMonth: YearMonth
            get() = state.month ?: input.today.periodMonth(startingOn = input.monthStartDay)

        val period: ClosedRange<LocalDate>
            get() = shownMonth.period(startingOn = input.monthStartDay)

        val monthTitle: String
            get() = "${shownMonth.year}年 ${shownMonth.month}月"

        val periodText: String
            get() = PeriodText.range(period)

        val days: List<EntryDay> by derivedStateOf {
            input.list.value?.days?.within(period) ?: emptyList()
        }

        val expenseTotal: Long
            get() = days.expenseTotal

        val incomeTotal: Long
            get() = days.incomeTotal

        val balance: Long
            get() = incomeTotal - expenseTotal

        val balanceTitle: String
            get() = ReviewText.balanceTitle(balance)

        fun day(on: LocalDate): EntryDay? = daysByDate[on]

        fun rows(of: EntryDay): List<EntryRowItem> {
            val list = input.list.value ?: return emptyList()

            return of.entries.map { entry ->
                EntryRowItem.of(
                    entry = entry,
                    list = list,
                )
            }
        }

        private val daysByDate: Map<LocalDate, EntryDay> by derivedStateOf {
            days.associateBy { it.date }
        }
    }

    private class Dependencies(
        val database: AppDatabase,
        val entryList: Flow<EntryList>,
        val round: ObservationRound,
    )

    override val errorNotice: ErrorNotice
        get() = state.notices.error

    override val isLoadFailed: Boolean
        get() = input.list.isFailed

    override fun setToday(today: LocalDate) {
        input.today = today
    }

    override suspend fun observe() {
        dependencies.round.each { observeAll() }
    }

    override fun retry() {
        dependencies.round.restart()
    }

    fun move(months: Int) {
        state.move(to = output.shownMonth.adding(months = months))
    }

    suspend fun select(layout: RecordsLayout) {
        input.layout = layout

        state.task.attempt(failure = ModelTask.saveFailed) {
            dependencies.database.setSetting(
                key = SettingKey.recordsLayout,
                to = layout,
            )
        }
    }

    private suspend fun observeAll() {
        val database = dependencies.database

        coroutineScope {
            launch {
                observe(database.settingUpdates(SettingKey.monthStartDay)) { startDay ->
                    if (startDay != input.monthStartDay) {
                        input.monthStartDay = startDay
                        state.openCurrentMonth()
                    }
                }
            }

            launch {
                observe(database.settingUpdates(SettingKey.weekStart)) { input.weekStart = it }
            }

            launch {
                observe(database.settingUpdates(SettingKey.recordsLayout)) { input.layout = it }
            }

            launch {
                state.task.observe(
                    values = dependencies.entryList,
                    failure = loadFailedMessage,
                    into = input::list,
                )
            }
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
