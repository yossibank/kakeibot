package com.yossibank.kakeibot.features.screens.tabs.records.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.entry.expenseTotal
import com.yossibank.kakeibot.core.concepts.entry.incomeTotal
import com.yossibank.kakeibot.core.concepts.entry.within
import com.yossibank.kakeibot.features.shared.entrylist.EntryRowItem
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

class RecordsModel(
    private val database: AppDatabase,
    today: LocalDate,
) {
    var today: LocalDate by mutableStateOf(today)

    var month: YearMonth? by mutableStateOf(null)
        private set

    var isLoaded: Boolean by mutableStateOf(false)
        private set

    private var list: EntryList? by mutableStateOf(null)

    private var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)

    val shownMonth: YearMonth
        get() = month ?: today.periodMonth(startingOn = monthStartDay)

    val period: ClosedRange<LocalDate>
        get() = shownMonth.period(startingOn = monthStartDay)

    val periodText: String
        get() = "${period.start.monthDayText}〜${period.endInclusive.monthDayText}"

    val days: List<EntryDay>
        get() = list?.days?.within(period) ?: emptyList()

    val expenseTotal: Long
        get() = days.expenseTotal

    val incomeTotal: Long
        get() = days.incomeTotal

    suspend fun observe() {
        coroutineScope {
            launch {
                database.settingUpdates(SettingKey.monthStartDay).collect { monthStartDay = it }
            }

            launch {
                database.entryListUpdates().collect {
                    list = it
                    isLoaded = true
                }
            }
        }
    }

    fun move(months: Int) {
        month = shownMonth.adding(months = months)
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
