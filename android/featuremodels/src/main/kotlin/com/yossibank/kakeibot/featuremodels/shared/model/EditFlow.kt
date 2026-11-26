package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.featuremodels.shared.notice.Deletion

class EditFlow<Saved : Any>(
    task: ModelTask,
    private val source: EditFlowSource<Saved>,
) : ScreenPerforming {
    val state = State<Saved>(task)
    val output = Output(source)

    enum class Prompt {
        menu,
        discard,
        hideChanges,
        hide,
        delete,
    }

    class Outcome<Saved : Any> internal constructor(
        val saved: Saved? = null,
        val isHidden: Boolean? = null,
        val deletion: Deletion? = null,
        val closes: Boolean = true,
    )

    class State<Saved : Any>(
        val task: ModelTask,
    ) {
        val prompt = Shown<Prompt>()
        val outcome = ScreenOutcome<Outcome<Saved>>()
    }

    class Output(
        private val source: EditFlowSource<*>,
    ) {
        val isEditing: Boolean
            get() = source.isEditing

        val isChanged: Boolean
            get() = source.isChanged

        val isHidden: Boolean
            get() = source.isHidden

        val canSave: Boolean
            get() = source.problem == null

        val saveTitle: String
            get() = source.problem ?: source.readyTitle

        val asksBeforeHiding: Boolean
            get() = !source.isHidden && source.asksBeforeHiding
    }

    private class Removal(
        val deletion: Deletion?,
    )

    fun close() {
        source.rest()

        if (source.isChanged) {
            state.prompt.show(Prompt.discard)
            return
        }

        state.outcome.send(Outcome())
    }

    fun back() {
        if (source.rest()) {
            return
        }

        close()
    }

    fun discard() {
        state.prompt.close(Prompt.discard)
        state.outcome.send(Outcome())
    }

    suspend fun save(): Saved? {
        source.rest()

        val saved = store() ?: return null

        if (!source.keepsOpen(after = saved)) {
            state.outcome.send(Outcome(saved = saved))
        }

        return saved
    }

    suspend fun toggleHidden() {
        if (output.asksBeforeHiding) {
            state.prompt.show(Prompt.hide)
            return
        }

        continueHiding()
    }

    suspend fun continueHiding() {
        if (source.isChanged) {
            state.prompt.show(Prompt.hideChanges)
            return
        }

        setHidden(!source.isHidden)
    }

    suspend fun setHidden(isHidden: Boolean): Boolean {
        if (state.task.isRunning || !source.isEditing || !storeHidden(isHidden)) {
            return false
        }

        state.outcome.send(Outcome(isHidden = isHidden))

        return true
    }

    suspend fun saveTogglingHidden(): Saved? {
        source.rest()

        val saved = store() ?: return null

        if (source.keepsOpen(after = saved)) {
            return saved
        }

        if (!source.isEditing) {
            state.outcome.send(Outcome(saved = saved))
            return saved
        }

        val isHidden = !source.isHidden

        val outcome = if (storeHidden(isHidden)) {
            Outcome(
                saved = saved,
                isHidden = isHidden,
            )
        } else {
            Outcome(
                saved = saved,
                closes = false,
            )
        }

        state.outcome.send(outcome)

        return saved
    }

    suspend fun delete(): Deletion? {
        if (state.task.isRunning || !source.isEditing) {
            return null
        }

        val removal = state.task.attempt(describe = source::deleteFailedMessage) {
            Removal(source.remove())
        } ?: return null

        state.outcome.send(Outcome(deletion = removal.deletion))

        return removal.deletion
    }

    private suspend fun store(): Saved? {
        if (state.task.isRunning) {
            return null
        }

        val problem = source.problem

        if (problem != null) {
            state.task.show(problem)
            return null
        }

        return source.store()
    }

    private suspend fun storeHidden(isHidden: Boolean): Boolean {
        val stored = state.task.attempt(describe = source::hideFailedMessage) {
            source.storeHidden(isHidden)
        }

        return stored != null
    }
}
