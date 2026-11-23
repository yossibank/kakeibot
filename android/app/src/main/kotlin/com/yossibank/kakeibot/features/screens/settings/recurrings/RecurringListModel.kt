package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.nextDate
import com.yossibank.kakeibot.core.concepts.recurring.total
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.text.clamped
import com.yossibank.kakeibot.features.shared.model.ModelTask
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.recurringUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.amount
import com.yossibank.kakeibot.store.queries.types.icon
import com.yossibank.kakeibot.store.queries.types.place
import com.yossibank.kakeibot.store.queries.types.title
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.deleteRecurrings
import com.yossibank.kakeibot.store.writes.methods.reorderRecurrings
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import com.yossibank.kakeibot.store.writes.types.Deletion
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import java.time.Instant

class RecurringListModel(
    private val database: AppDatabase,
    today: LocalDate,
) {
    var today: LocalDate by mutableStateOf(today)

    var type: Entry.Kind by mutableStateOf(Entry.Kind.expense)

    var movingOrder: List<Identifier<Recurring>>? by mutableStateOf(null)
        private set

    private var recurrings: List<Recurring> by mutableStateOf(emptyList())
    private var list: EntryList? by mutableStateOf(null)
    private var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)

    private val task = ModelTask()

    val message: String
        get() = task.message

    val visible: List<Recurring>
        get() = recurrings(isHidden = false)

    val hidden: List<Recurring>
        get() = recurrings(isHidden = true)

    val rows: List<RecurringRow>
        get() {
            val list = list ?: return emptyList()
            return shown.map { row(of = it, list = list) }
        }

    val hiddenRows: List<RecurringRow>
        get() {
            val list = list ?: return emptyList()
            return hidden.map { row(of = it, list = list) }
        }

    val monthTotal: Long
        get() {
            val period = today
                .periodMonth(startingOn = monthStartDay)
                .period(startingOn = monthStartDay)

            val entries = list?.entries ?: return visible.total(
                of = type,
                range = period,
            )

            return visible.total(
                of = type,
                range = period,
                entries = entries,
            )
        }

    val emptyText: String
        get() = when (type) {
            Entry.Kind.expense -> "家賃やサブスクなどを足すと、ここに並びます"
            Entry.Kind.income -> "給料や年金などを足すと、ここに並びます"
            Entry.Kind.transfer -> "カードの引き落としや積立などを足すと、ここに並びます"
        }

    private val shown: List<Recurring>
        get() {
            val order = movingOrder ?: return visible
            val byId = visible.associateBy { it.id }
            return order.mapNotNull { byId[it] }
        }

    suspend fun observe() {
        coroutineScope {
            launch {
                database.recurringUpdates(includingHidden = true).collect { recurrings = it }
            }

            launch {
                database.entryListUpdates().collect { list = it }
            }

            database.settingUpdates(SettingKey.monthStartDay).collect { monthStartDay = it }
        }
    }

    fun move(
        id: Identifier<Recurring>,
        to: Int,
    ) {
        val order = (movingOrder ?: visible.map { it.id }).toMutableList()
        val from = order.indexOf(id)

        if (from < 0) {
            return
        }

        val target = to.coerceIn(0, order.lastIndex)

        if (from == target) {
            movingOrder = order
            return
        }

        order.removeAt(from)
        order.add(target, id)
        movingOrder = order
    }

    fun cancelMoving() {
        movingOrder = null
    }

    suspend fun finishMoving() {
        val order = movingOrder ?: return
        val others = recurrings.map { it.id }.filter { it !in order }

        task.attempt(failure = ModelTask.saveFailed) {
            database.reorderRecurrings(
                ids = order + others,
                at = Instant.now(),
            )
        }

        movingOrder = null
    }

    suspend fun hide(id: Identifier<Recurring>): Boolean = setHidden(
        id = id,
        isHidden = true,
    )

    suspend fun show(id: Identifier<Recurring>): Boolean = setHidden(
        id = id,
        isHidden = false,
    )

    suspend fun delete(id: Identifier<Recurring>): Deletion? =
        task.attempt(failure = ModelTask.saveFailed) {
            database.deleteRecurring(
                id = id,
                at = Instant.now(),
            )
        }

    suspend fun deleteHidden(): Deletion? {
        val ids = hidden.map { it.id }

        if (ids.isEmpty()) {
            return null
        }

        return task.attempt(failure = ModelTask.saveFailed) {
            database.deleteRecurrings(
                ids = ids,
                at = Instant.now(),
            )
        }
    }

    suspend fun restore(deletion: Deletion) {
        task.attempt(failure = ModelTask.restoreFailed) {
            database.restore(deletion)
        }
    }

    fun clearMessage() {
        task.clear()
    }

    private suspend fun setHidden(
        id: Identifier<Recurring>,
        isHidden: Boolean,
    ): Boolean {
        val done = task.attempt(failure = ModelTask.saveFailed) {
            database.setRecurringHidden(
                id = id,
                isHidden = isHidden,
                today = today,
                at = Instant.now(),
            )
        }

        return done != null
    }

    private fun recurrings(isHidden: Boolean): List<Recurring> = recurrings.filter { recurring ->
        recurring.type == type && (recurring.archivedAt != null) == isHidden
    }

    private fun row(
        of: Recurring,
        list: EntryList,
    ): RecurringRow {
        val schedule = RecurringText.schedule(
            frequency = of.frequency,
            month = of.month ?: of.startDate.month,
            day = of.day,
        )

        val next = of.nextDate(onOrAfter = today)

        return RecurringRow(
            id = of.id,
            title = list.title(of = of) ?: title(of.type),
            schedule = RecurringText.detail(
                schedule = schedule,
                holiday = RecurringText.holidayNote(of.holidayShift),
            ),
            place = list.place(of = of),
            amount = list
                .amount(
                    of = of,
                    on = next ?: today,
                ).clamped,
            type = of.type,
            icon = list.icon(of = of),
            next = next,
            closing = of.closingDay?.let(RecurringText::closingNote),
        )
    }

    companion object {
        fun title(type: Entry.Kind): String = if (type == Entry.Kind.transfer) "振替" else "固定費"
    }
}
