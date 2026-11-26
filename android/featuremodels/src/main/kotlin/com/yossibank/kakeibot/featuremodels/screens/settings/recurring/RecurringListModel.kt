package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.total
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.notice.UndoNoticeState
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldInput
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldModel
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.recurringUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
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
    parts: ScreenParts,
    today: LocalDate,
    opening: Identifier<Recurring>? = null,
) : SettingsFoldModel {
    val state = State(today, opening?.let { Editing.Existing(it) })
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(parts.database, parts.clock, parts.entryList)

    sealed interface Editing {
        data object New : Editing

        data class Existing(
            val id: Identifier<Recurring>,
        ) : Editing
    }

    sealed interface DeleteTarget {
        data object AllHidden : DeleteTarget

        data class One(
            val id: Identifier<Recurring>,
        ) : DeleteTarget
    }

    class State(
        today: LocalDate,
        editing: Editing?,
    ) {
        val task = ModelTask()
        val hidden = UndoNoticeState<Identifier<Recurring>>()
        val deleted = UndoNoticeState<Deletion>()

        var today: LocalDate by mutableStateOf(today)
        var editing: Editing? by mutableStateOf(editing)
        var openId: Identifier<Recurring>? by mutableStateOf(null)

        var deleting: DeleteTarget? by mutableStateOf(null)
            private set

        var type: Entry.Kind by mutableStateOf(Entry.Kind.expense)
            private set

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

        fun ask(target: DeleteTarget) {
            deleting = target
        }

        fun closePrompt(target: DeleteTarget) {
            if (deleting == target) {
                deleting = null
            }
        }

        fun select(type: Entry.Kind) {
            openId = null
            this.type = type
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
        internal val input: Input,
        internal val state: State,
    ) {
        val visible: List<Recurring>
            get() = recurrings(isHidden = false)

        val hidden: List<Recurring>
            get() = recurrings(isHidden = true)

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

        private fun recurrings(isHidden: Boolean): List<Recurring> =
            input.recurrings.filter { recurring ->
                recurring.type == state.type && (recurring.archivedAt != null) == isHidden
            }
    }

    private class Dependencies(
        val database: AppDatabase,
        val clock: ScreenClock,
        val entryList: Flow<EntryList>,
    )

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

        val isHidden = setHidden(
            id = id,
            isHidden = true,
            failure = HIDE_FAILED,
        )

        if (isHidden) {
            state.hidden.show(id)
        }

        return isHidden
    }

    suspend fun show(id: Identifier<Recurring>): Boolean = setHidden(
        id = id,
        isHidden = false,
        failure = SHOW_FAILED,
    )

    suspend fun delete(id: Identifier<Recurring>): Deletion? {
        state.cancelMoving()

        val deletion = state.task.attempt(failure = DELETE_FAILED) { remove(id) }

        deletion?.let(state.deleted::show) ?: state.deleted.dismiss()

        return deletion
    }

    suspend fun deleteHidden(): Deletion? {
        state.cancelMoving()

        val deletions = output.hidden.map { recurring ->
            ModelTask.quiet { remove(recurring.id) }
        }

        if (deletions.any { it == null }) {
            state.task.show(BULK_DELETE_FAILED)
        }

        val deletion = deletions.filterNotNull().takeIf { it.isNotEmpty() }?.let(Deletion::merging)

        deletion?.let(state.deleted::show)

        return deletion
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
