package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.nextDate
import com.yossibank.kakeibot.core.concepts.recurring.total
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldInput
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldModel
import com.yossibank.kakeibot.store.database.AppDatabase
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
import com.yossibank.kakeibot.store.writes.methods.reorder
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import com.yossibank.kakeibot.store.writes.types.Deletion
import com.yossibank.kakeibot.store.writes.types.RecurringTable
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class RecurringListModel(
    database: AppDatabase,
    clock: ScreenClock,
    entryList: Flow<EntryList>,
    today: LocalDate,
) : SettingsFoldModel {
    val state = State(today)
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(database, clock, entryList)

    class State(
        today: LocalDate,
    ) {
        val task = ModelTask()

        var today: LocalDate by mutableStateOf(today)

        var type: Entry.Kind by mutableStateOf(Entry.Kind.expense)

        var movingOrder: List<Identifier<Recurring>>? by mutableStateOf(null)
            private set

        fun move(
            id: Identifier<Recurring>,
            to: Int,
            among: List<Identifier<Recurring>>,
        ) {
            val order = (movingOrder ?: among).toMutableList()
            val from = order.indexOf(id)

            if (from < 0) {
                return
            }

            val target = to.coerceIn(0, order.lastIndex)

            if (from == target) {
                return
            }

            order.removeAt(from)
            order.add(target, id)
            movingOrder = order
        }

        fun cancelMoving() {
            movingOrder = null
        }
    }

    class Input {
        var recurrings: List<Recurring> by mutableStateOf(emptyList())
            internal set

        var list: EntryList? by mutableStateOf(null)
            internal set

        var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)
            internal set

        val hint = SettingsFoldInput.hint(SettingsScreen.recurrings)
        val hiddenList = SettingsFoldInput.hiddenList(SettingsScreen.recurrings)
    }

    class Output(
        private val input: Input,
        private val state: State,
    ) {
        val visible: List<Recurring>
            get() = recurrings(isHidden = false)

        val hidden: List<Recurring>
            get() = recurrings(isHidden = true)

        val rows: List<RecurringRow>
            get() {
                val list = input.list ?: return emptyList()
                return shown.map { row(of = it, list = list) }
            }

        val hiddenRows: List<RecurringRow>
            get() {
                val list = input.list ?: return emptyList()
                return hidden.map { row(of = it, list = list) }
            }

        val monthTotal: Long
            get() {
                val period = state.today
                    .periodMonth(startingOn = input.monthStartDay)
                    .period(startingOn = input.monthStartDay)

                val entries = input.list?.entries ?: return visible.total(
                    of = state.type,
                    range = period,
                )

                return visible.total(
                    of = state.type,
                    range = period,
                    entries = entries,
                )
            }

        val emptyText: String
            get() = when (state.type) {
                Entry.Kind.expense -> "家賃やサブスクなどを足すと、ここに並びます"
                Entry.Kind.income -> "給料や年金などを足すと、ここに並びます"
                Entry.Kind.transfer -> "カードの引き落としや積立などを足すと、ここに並びます"
            }

        private val shown: List<Recurring>
            get() {
                val order = state.movingOrder ?: return visible
                val byId = visible.associateBy { it.id }
                return order.mapNotNull { byId[it] }
            }

        private fun recurrings(isHidden: Boolean): List<Recurring> =
            input.recurrings.filter { recurring ->
                recurring.type == state.type && (recurring.archivedAt != null) == isHidden
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

            val next = of.nextDate(onOrAfter = state.today)

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
                        on = next ?: state.today,
                    ).clamped,
                type = of.type,
                icon = list.icon(of = of),
                next = next,
                closing = of.closingDay?.let(RecurringText::closingNote),
            )
        }
    }

    private class Dependencies(
        val database: AppDatabase,
        val clock: ScreenClock,
        val entryList: Flow<EntryList>,
    )

    suspend fun observe() {
        val database = dependencies.database

        coroutineScope {
            launch {
                observe(database.recurringUpdates(includingHidden = true)) { input.recurrings = it }
            }

            launch {
                observe(dependencies.entryList) { input.list = it }
            }

            observe(database.settingUpdates(SettingKey.monthStartDay)) { input.monthStartDay = it }
        }
    }

    fun move(
        id: Identifier<Recurring>,
        to: Int,
    ) {
        state.move(
            id = id,
            to = to,
            among = output.visible.map { it.id },
        )
    }

    override suspend fun loadFold(fold: SettingsFoldInput) {
        fold.load(from = dependencies.database)
    }

    override suspend fun setFold(
        fold: SettingsFoldInput,
        isClosed: Boolean,
    ) {
        fold.save(
            isClosed = isClosed,
            to = dependencies.database,
        )
    }

    suspend fun toggleHiddenList() {
        setFold(
            fold = input.hiddenList,
            isClosed = input.hiddenList.isClosed != true,
        )
    }

    suspend fun finishMoving() {
        val order = state.movingOrder ?: return
        val others = input.recurrings.map { it.id }.filter { it !in order }

        state.task.attempt(failure = ORDER_FAILED) {
            dependencies.database.reorder(
                RecurringTable,
                ids = order + others,
                at = dependencies.clock.now,
            )
        }

        state.cancelMoving()
    }

    suspend fun hide(id: Identifier<Recurring>): Boolean {
        state.cancelMoving()

        return setHidden(
            id = id,
            isHidden = true,
            failure = HIDE_FAILED,
        )
    }

    suspend fun show(id: Identifier<Recurring>): Boolean = setHidden(
        id = id,
        isHidden = false,
        failure = SHOW_FAILED,
    )

    suspend fun delete(id: Identifier<Recurring>): Deletion? {
        state.cancelMoving()

        return state.task.attempt(failure = DELETE_FAILED) { remove(id) }
    }

    suspend fun deleteHidden(): Deletion? {
        state.cancelMoving()

        val deletions = output.hidden.map { recurring ->
            ModelTask.quiet { remove(recurring.id) }
        }

        if (deletions.any { it == null }) {
            state.task.show(BULK_DELETE_FAILED)
        }

        return deletions.filterNotNull().takeIf { it.isNotEmpty() }?.let { Deletion.merging(it) }
    }

    suspend fun restore(deletion: Deletion) {
        state.task.attempt(failure = ModelTask.restoreFailed) {
            dependencies.database.restore(deletion)
        }
    }

    private suspend fun remove(id: Identifier<Recurring>): Deletion =
        dependencies.database.deleteRecurring(
            id = id,
            at = dependencies.clock.now,
        )

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

    private suspend fun setHidden(
        id: Identifier<Recurring>,
        isHidden: Boolean,
        failure: String,
    ): Boolean {
        val done = state.task.attempt(failure = failure) {
            dependencies.database.setRecurringHidden(
                id = id,
                isHidden = isHidden,
                today = state.today,
                at = dependencies.clock.now,
            )
        }

        return done != null
    }

    companion object {
        const val loadFailedMessage = "固定費を読めませんでした"

        private const val HIDE_FAILED = "非表示にできませんでした"
        private const val SHOW_FAILED = "表示に戻せませんでした"
        private const val DELETE_FAILED = "削除できませんでした"
        private const val ORDER_FAILED = "並びを保存できませんでした"
        private const val BULK_DELETE_FAILED = "削除できないものがありました"

        fun title(type: Entry.Kind): String = if (type == Entry.Kind.transfer) "振替" else "固定費"
    }
}
