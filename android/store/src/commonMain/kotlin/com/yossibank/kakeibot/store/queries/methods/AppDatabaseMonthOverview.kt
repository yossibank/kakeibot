package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.setting.TemplateOrder
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import com.yossibank.kakeibot.store.queries.types.entryListJoin
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.budgetCarryoverFrom
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.values.databaseValue
import kotlinx.coroutines.flow.Flow

fun AppDatabase.monthOverviewUpdates(on: LocalDate): Flow<MonthOverview> = entryListJoin(
    part = observation(
        "budget",
        "recurring",
        "setting",
    ) {
        fetchMonthPlan(on)
    },
) { list, plan ->
    plan.with(list)
}

suspend fun AppDatabase.monthOverview(on: LocalDate): MonthOverview = read {
    val list = fetchEntryList(includesItems = false)
    val plan = fetchMonthPlan(on)

    plan.with(list)
}

suspend fun AppDatabase.widgetOverview(
    on: LocalDate,
    including: Identifier<Entry>? = null,
): MonthOverview = read {
    val plan = fetchMonthPlan(on)
    val start = plan.widgetStart

    val entries = entryDao()
        .since(
            start = start.databaseValue,
            month = start.yearMonth.databaseValue,
            id = including?.databaseValue,
        )
        .map { it.decoded(EntryRecord::entry) }

    val list = fetchEntryList(entries = entries)

    plan.with(list)
}

private const val widgetMonths = 4

private suspend fun AppDatabase.fetchMonthPlan(today: LocalDate): MonthOverview = MonthOverview(
    list = null,
    budgets = fetchBudgets(),
    recurrings = fetchRecurrings(),
    monthStartDay = fetchSetting(SettingKey.monthStartDay),
    carryoverFrom = fetchSetting(SettingKey.budgetCarryoverFrom),
    today = today,
)

private val MonthOverview.widgetStart: LocalDate
    get() {
        val month = period.start.yearMonth.adding(months = -widgetMonths)
        val monthStart = month.period(startingOn = MonthStartDay.first).start
        val templateStart = today.adding(days = -TemplateOrder.frequentDays)
        val start = minOf(monthStart, templateStart)
        val carryoverFrom = carryoverFrom ?: return start
        val carryoverStart = carryoverFrom.period(startingOn = monthStartDay).start

        return minOf(start, carryoverStart)
    }

private fun MonthOverview.with(list: EntryList): MonthOverview = copy(list = list)
