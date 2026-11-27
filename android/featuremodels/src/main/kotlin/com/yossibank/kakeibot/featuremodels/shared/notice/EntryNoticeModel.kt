package com.yossibank.kakeibot.featuremodels.shared.notice

import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.restoreEntry
import kotlin.time.Duration.Companion.seconds

class EntryNoticeModel(
    parts: ScreenParts,
) : ScreenPerforming {
    val state = State(parts.wait)
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

    class State(
        wait: ScreenWait,
    ) {
        private val shown = UndoNotice<Notice>(wait)

        val notice: Notice?
            get() = shown.current

        val id: Int?
            get() = shown.id

        internal fun show(notice: Notice) {
            shown.show(
                item = notice,
                duration = notice.seconds.seconds,
            )
        }

        internal fun clear() {
            shown.dismiss()
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
