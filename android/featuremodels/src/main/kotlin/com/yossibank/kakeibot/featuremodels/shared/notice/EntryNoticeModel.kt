package com.yossibank.kakeibot.featuremodels.shared.notice

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.restoreEntry
import kotlinx.coroutines.delay

class EntryNoticeModel(
    parts: ScreenParts,
) : ScreenPerforming {
    val state = State()
    val output = Output(state)

    private val dependencies = Dependencies(parts.database, parts.clock)

    sealed interface Notice {
        data class Changed(
            val change: EntryChange,
        ) : Notice

        data object Undone : Notice

        data class Failed(
            val message: String,
        ) : Notice
    }

    class State {
        var notice: Notice? by mutableStateOf(null)
            private set

        var count: Int by mutableIntStateOf(0)
            private set

        internal fun show(notice: Notice) {
            this.notice = notice
            count += 1
        }

        internal fun clear() {
            notice = null
        }

        @Composable
        fun Timer() {
            val notice = notice ?: return
            val shown = count

            LaunchedEffect(shown) {
                delay(notice.seconds * 1_000L)

                if (count == shown) {
                    clear()
                }
            }
        }
    }

    class Output(
        internal val state: State,
    )

    private class Dependencies(
        val database: AppDatabase,
        val clock: ScreenClock,
    )

    fun show(change: EntryChange) {
        state.show(Notice.Changed(change))
    }

    suspend fun undo() {
        val shown = state.notice

        state.clear()

        val change = (shown as? Notice.Changed)?.change ?: return
        val undone = ModelTask.quiet { undo(change) }

        state.show(if (undone == null) Notice.Failed(UNDO_FAILED_MESSAGE) else Notice.Undone)
    }

    fun clear() {
        state.clear()
    }

    fun clearOnTap() {
        if (state.notice?.dismissesOnTap != true) {
            return
        }

        state.clear()
    }

    private suspend fun undo(change: EntryChange) {
        val database = dependencies.database
        val at = dependencies.clock.now

        when (val kind = change.kind) {
            EntryChange.Kind.Recorded -> {
                database.deleteEntry(
                    id = change.entry.id,
                    restoringNoSpend = change.clearedNoSpendDays,
                    at = at,
                )
            }

            is EntryChange.Kind.Edited -> {
                database.restoreEntry(
                    entry = kind.previous,
                    fee = kind.previousFee,
                    restoringNoSpend = change.clearedNoSpendDays,
                    at = at,
                )
            }

            EntryChange.Kind.Deleted -> {
                database.restoreEntry(
                    entry = change.entry,
                    fee = change.fee,
                    items = change.items,
                    at = at,
                )
            }
        }
    }

    companion object {
        private const val UNDO_FAILED_MESSAGE = "取り消せませんでした"
    }
}

val EntryNoticeModel.Output.change: EntryChange?
    get() = (state.notice as? EntryNoticeModel.Notice.Changed)?.change

val EntryNoticeModel.Notice.message: String
    get() = when (this) {
        is EntryNoticeModel.Notice.Changed -> change.message
        EntryNoticeModel.Notice.Undone -> "取り消しました"
        is EntryNoticeModel.Notice.Failed -> message
    }

val EntryNoticeModel.Notice.seconds: Int
    get() = when (this) {
        is EntryNoticeModel.Notice.Changed, is EntryNoticeModel.Notice.Failed -> 4
        EntryNoticeModel.Notice.Undone -> 2
    }

val EntryNoticeModel.Notice.dismissesOnTap: Boolean
    get() = when (this) {
        is EntryNoticeModel.Notice.Changed -> !change.isDeletion
        EntryNoticeModel.Notice.Undone, is EntryNoticeModel.Notice.Failed -> true
    }
