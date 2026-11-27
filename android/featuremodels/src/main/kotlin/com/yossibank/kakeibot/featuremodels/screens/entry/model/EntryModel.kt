package com.yossibank.kakeibot.featuremodels.screens.entry.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ErrorNotice
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenEditable
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenOutcome
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import com.yossibank.kakeibot.featuremodels.shared.model.Shown
import com.yossibank.kakeibot.featuremodels.shared.notice.EntryChange
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.recentMemos
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.methods.templates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.EntryWriteError
import com.yossibank.kakeibot.store.writes.methods.EntryWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.entryItems
import com.yossibank.kakeibot.store.writes.methods.fee
import com.yossibank.kakeibot.store.writes.methods.recentItemNames
import com.yossibank.kakeibot.store.writes.methods.saveEntryResult

class EntryModel(
    parts: ScreenParts,
    today: LocalDate,
    editing: Identifier<Entry>? = null,
    date: LocalDate = today,
) : ScreenPerforming {
    val state = State(date, parts.wait)
    val input = Input(today, editing)
    val output = Output(input, state)

    private val dependencies = Dependencies(parts.database, parts.clock)

    enum class Field {
        Category,
        Wallet,
        ToWallet,
        Date,
        Amount,
        Fee,
        Transfer,
    }

    sealed interface Outcome {
        data class Closed(
            val change: EntryChange,
        ) : Outcome

        data class Continued(
            val change: EntryChange,
        ) : Outcome
    }

    sealed interface Overlay {
        data object Discard : Overlay

        data object Items : Overlay

        data class Template(
            val draft: EntryTemplateDraft,
        ) : Overlay
    }

    class Presented : ScreenEditable {
        val overlay = Shown<Overlay>()
    }

    class Notices(
        wait: ScreenWait,
    ) {
        val error = ErrorNotice(wait)
    }

    class Submodels {
        var calculator: AmountCalculator by mutableStateOf(AmountCalculator())
            internal set

        var feeCalculator: AmountCalculator by mutableStateOf(AmountCalculator())
            internal set
    }

    data class FieldFocus(
        val field: Field = Field.Category,
        val isForward: Boolean = true,
    ) {
        fun moved(
            to: Field,
            type: Entry.Kind,
        ): FieldFocus {
            val isTransferOnly = to == Field.Fee || to == Field.Transfer
            val next = if (isTransferOnly && type != Entry.Kind.transfer) Field.Amount else to

            return FieldFocus(
                field = next,
                isForward = next.order(of = type) >= field.order(of = type),
            )
        }
    }

    class State(
        date: LocalDate,
        wait: ScreenWait,
    ) {
        val notices = Notices(wait)
        val task = ModelTask(notices.error)
        val outcome = ScreenOutcome<Outcome>()
        val presented = Presented()
        val submodels = Submodels()

        var form: EntryForm by mutableStateOf(EntryForm(date = date))
            private set

        var focus: FieldFocus by mutableStateOf(FieldFocus())
            private set

        var voiceFilled: VoiceFilled? by mutableStateOf(null)
            private set

        fun update(change: EntryForm.() -> EntryForm) {
            form = form.change()
        }

        fun focus(field: Field) {
            focus = focus.moved(to = field, type = form.type)
        }

        fun select(date: LocalDate) {
            form = form.withDate(date)
            focus(Field.Amount)
        }

        fun press(key: AmountCalculator.Key) {
            if (focus.field == Field.Fee) {
                submodels.feeCalculator = submodels.feeCalculator.press(key)
            } else {
                submodels.calculator = submodels.calculator.press(key)
            }
        }

        fun setAmount(amount: Int) {
            submodels.calculator = AmountCalculator(amount = amount)
        }

        fun setFee(amount: Int) {
            submodels.feeCalculator = AmountCalculator(amount = amount)
        }

        fun clear() {
            form = form.cleared()
            submodels.calculator = AmountCalculator()
            submodels.feeCalculator = AmountCalculator()
            voiceFilled = null
        }

        internal fun fill(
            form: EntryForm,
            calculator: AmountCalculator,
            voiceFilled: VoiceFilled?,
        ) {
            this.form = form
            submodels.calculator = calculator
            this.voiceFilled = voiceFilled
        }

        internal fun load(
            form: EntryForm,
            amount: Int,
            fee: Int,
        ) {
            this.form = form
            submodels.calculator = AmountCalculator(amount = amount)
            submodels.feeCalculator = AmountCalculator(amount = fee)
        }

        internal fun startAgain(today: LocalDate) {
            form = form.copy(
                date = today,
                billMonth = null,
                items = emptyList(),
                taxIncluded = false,
                templateId = null,
            )

            submodels.feeCalculator = AmountCalculator()
            voiceFilled = null
            focus(Field.Amount)
        }
    }

    class Input(
        today: LocalDate,
        editingId: Identifier<Entry>?,
    ) {
        var today: LocalDate by mutableStateOf(today)
            internal set

        var editingId: Identifier<Entry>? by mutableStateOf(editingId)
            internal set

        var original: Entry? = null
            internal set

        var originalFee: Entry? = null
            internal set

        var history: EntryList? by mutableStateOf(null)
            internal set

        var recentItemNames: List<String> by mutableStateOf(emptyList())
            internal set

        var recentMemos: List<String> by mutableStateOf(emptyList())
            internal set

        var cardBills: List<Recurring> = emptyList()
            internal set

        var options: EntryOptions? by mutableStateOf(null)
            internal set

        var allTemplates: List<EntryTemplate> by mutableStateOf(emptyList())
            internal set

        internal var baseline: Snapshot? by mutableStateOf(null)
    }

    class Output(
        internal val input: Input,
        internal val state: State,
    )

    internal data class Snapshot(
        val form: EntryForm,
        val calculator: AmountCalculator,
        val feeCalculator: AmountCalculator,
    )

    private class Dependencies(
        val database: AppDatabase,
        val clock: ScreenClock,
    )

    suspend fun load() {
        val database = dependencies.database

        state.task.attempt(describe = ::describe) {
            database.insertDefaultsIfEmpty(at = dependencies.clock.now)
            input.options = database.entryOptions()
            input.allTemplates = database.templates()

            input.cardBills = database.recurrings().filter { recurring ->
                recurring.type == Entry.Kind.transfer && recurring.closingDay != null
            }

            val entry = loadEntry()

            if (entry != null) {
                fill(
                    entry = entry,
                    items = database.entryItems(of = entry.id).map { EntryItem.Draft(it) },
                    fee = input.originalFee?.amount ?: 0,
                )
            }

            loadHistory()

            if (entry == null) {
                startNew()
            }

            state.focus(output.startField)
            input.baseline = output.snapshot
        }
    }

    suspend fun save(): Boolean {
        val change = store() ?: return false
        state.outcome.send(Outcome.Closed(change))
        return true
    }

    suspend fun saveAndContinue(): Boolean {
        val change = store() ?: return false

        startNext()
        state.outcome.send(Outcome.Continued(change))

        return true
    }

    suspend fun delete(): Boolean {
        val original = input.original

        if (original == null || state.task.isRunning) {
            return false
        }

        val change = state.task.attempt(describe = ::describe) {
            val database = dependencies.database
            val items = database.entryItems(of = original.id)

            val deleted = database.deleteEntry(
                id = original.id,
                at = dependencies.clock.now,
            )

            EntryChange(
                kind = EntryChange.Kind.Deleted,
                entry = original,
                label = output.label(of = original),
                fee = deleted.firstOrNull { it.transferId == original.id },
                items = items,
            )
        }

        if (change != null) {
            state.outcome.send(Outcome.Closed(change))
        }

        return change != null
    }

    suspend fun reloadTemplates() {
        state.task.attempt(describe = ::describe) {
            input.allTemplates = dependencies.database.templates()
        }
    }

    internal suspend fun loadHistory() {
        val database = dependencies.database

        input.recentItemNames = database.recentItemNames(limit = RECENT_ITEM_NAME_LIMIT)
        input.recentMemos = database.recentMemos(limit = RECENT_MEMO_LIMIT)
        input.history = database.entryList()
    }

    private suspend fun store(): EntryChange? {
        val draft = output.draft

        if (draft == null || state.task.isRunning) {
            return null
        }

        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            state.notices.error.show(output.message(of = problem))
            return null
        }

        return state.task.attempt(describe = ::describe) {
            val database = dependencies.database

            val saved = database.saveEntryResult(
                draft = draft,
                editing = input.editingId,
                at = dependencies.clock.now,
            )

            change(
                saved = saved,
                fee = database.fee(of = saved.entry.id),
            )
        }
    }

    private suspend fun loadEntry(): Entry? {
        val database = dependencies.database
        val editing = input.editingId ?: return null
        val missing = EntryWriteException(EntryWriteError.entryNotFound)
        val found = database.entry(editing) ?: throw missing
        val entry = found.transferId?.let { database.entry(it) } ?: found

        input.editingId = entry.id
        input.original = entry
        input.originalFee = database.fee(of = entry.id)

        return entry
    }
}
