package com.yossibank.kakeibot.features.screens.tabs.records.model

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
import com.yossibank.kakeibot.features.shared.entrylist.EntryRowItem
import com.yossibank.kakeibot.features.shared.model.ModelTask
import com.yossibank.kakeibot.features.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.recordsLayout
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class RecordsModel(
    private val database: AppDatabase,
    private val entryList: Flow<EntryList>,
    today: LocalDate,
) {
    var today: LocalDate by mutableStateOf(today)

    var month: YearMonth? by mutableStateOf(null)
        private set

    var isLoaded: Boolean by mutableStateOf(false)
        private set

    private var list: EntryList? by mutableStateOf(null)

    private var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)

    private var weekStart: Weekday by mutableStateOf(Weekday.monday)

    private var selected: LocalDate? by mutableStateOf(null)

    var layout: RecordsLayout by mutableStateOf(RecordsLayout.calendar)
        private set

    val weekdays: List<Weekday>
        get() = Weekday.week(startingOn = weekStart)

    val weeks: List<List<LocalDate?>>
        get() = period.weeks(startingOn = weekStart)

    val selectedDate: LocalDate
        get() {
            val period = period
            val date = selected

            return when {
                date != null && date in period -> date
                today in period -> today
                else -> period.start
            }
        }

    val shownMonth: YearMonth
        get() = month ?: today.periodMonth(startingOn = monthStartDay)

    val period: ClosedRange<LocalDate>
        get() = shownMonth.period(startingOn = monthStartDay)

    val monthTitle: String
        get() = "${shownMonth.year}年 ${shownMonth.month}月"

    val periodText: String
        get() = PeriodText.range(period)

    val days: List<EntryDay> by derivedStateOf {
        list?.days?.within(period) ?: emptyList()
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

    suspend fun observe() {
        coroutineScope {
            launch {
                database.settingUpdates(SettingKey.monthStartDay).collect { monthStartDay = it }
            }

            launch {
                database.settingUpdates(SettingKey.weekStart).collect { weekStart = it }
            }

            launch {
                database.settingUpdates(SettingKey.recordsLayout).collect { layout = it }
            }

            launch {
                entryList.collect {
                    list = it
                    isLoaded = true
                }
            }
        }
    }

    fun move(months: Int) {
        month = shownMonth.adding(months = months)
        selected = null
    }

    fun select(date: LocalDate) {
        selected = date
    }

    fun day(on: LocalDate): EntryDay? = daysByDate[on]

    suspend fun select(layout: RecordsLayout) {
        this.layout = layout

        ModelTask.quiet {
            database.setSetting(
                key = SettingKey.recordsLayout,
                to = layout,
            )
        }
    }

    fun rows(of: EntryDay): List<EntryRowItem> {
        val list = list ?: return emptyList()

        return of.entries.map { entry ->
            EntryRowItem.of(
                entry = entry,
                list = list,
            )
        }
    }
}
