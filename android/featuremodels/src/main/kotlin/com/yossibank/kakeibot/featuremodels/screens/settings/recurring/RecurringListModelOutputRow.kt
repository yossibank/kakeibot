package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.nextDate
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.amount
import com.yossibank.kakeibot.store.queries.types.icon
import com.yossibank.kakeibot.store.queries.types.place
import com.yossibank.kakeibot.store.queries.types.title

val RecurringListModel.Output.rows: List<RecurringRow>
    get() {
        val list = input.list ?: return emptyList()
        return shown.map { row(of = it, list = list) }
    }

val RecurringListModel.Output.hiddenRows: List<RecurringRow>
    get() {
        val list = input.list ?: return emptyList()
        return hidden.map { row(of = it, list = list) }
    }

private val RecurringListModel.Output.shown: List<Recurring>
    get() {
        val order = state.movingOrder ?: return visible
        val byId = visible.associateBy { it.id }
        return order.mapNotNull { byId[it] }
    }

private fun RecurringListModel.Output.row(
    of: Recurring,
    list: EntryList,
): RecurringRow {
    val schedule = RecurringText.schedule(
        frequency = of.frequency,
        month = of.month ?: of.startDate.month,
        day = of.day,
    )

    val next = of.nextDate(onOrAfter = input.today)

    return RecurringRow(
        id = of.id,
        title = list.title(of = of) ?: RecurringListModel.title(of.type),
        schedule = RecurringText.detail(
            schedule = schedule,
            holiday = RecurringText.holidayNote(of.holidayShift),
        ),
        place = list.place(of = of),
        amount = list
            .amount(
                of = of,
                on = next ?: input.today,
            ).clamped,
        type = of.type,
        icon = list.icon(of = of),
        next = next,
        closing = of.closingDay?.let(RecurringText::closingNote),
    )
}
