package com.yossibank.kakeibot.featuremodels.screens.entry.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenOutcome
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
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
import com.yossibank.kakeibot.store.writes.methods.saveEntry

class EntryModel(
    database: AppDatabase,
    clock: ScreenClock,
    today: LocalDate,
    editing: Identifier<Entry>? = null,
) : ScreenPerforming {
    val state = State(today)
    val input = Input(editing)
    val output = Output(input, state)

    private val dependencies = Dependencies(database, clock)

    enum class Field {
        Category,
        Wallet,
        ToWallet,
        Date,
        Amount,
        Fee,
        Transfer,
    }

    enum class Outcome {
        Closed,
        Continued,
    }

    sealed interface Presented {
        data object Discard : Presented

        data object Delete : Presented

        data object Items : Presented

        data class Template(
            val draft: EntryTemplateDraft,
        ) : Presented
    }

    class State(
        today: LocalDate,
    ) {
        val task = ModelTask()
        val outcome = ScreenOutcome<Outcome>()

        var today: LocalDate by mutableStateOf(today)

        var form: EntryForm by mutableStateOf(EntryForm(date = today))
            private set

        var calculator: AmountCalculator by mutableStateOf(AmountCalculator())
            private set

        var feeCalculator: AmountCalculator by mutableStateOf(AmountCalculator())
            private set

        var field: Field by mutableStateOf(Field.Amount)
            private set

        var voiceFilled: VoiceFilled? by mutableStateOf(null)
            private set

        var presented: Presented? by mutableStateOf(null)
            private set

        fun present(presented: Presented) {
            this.presented = presented
        }

        fun dismiss() {
            presented = null
        }

        fun update(change: EntryForm.() -> EntryForm) {
            form = form.change()
        }

        fun focus(field: Field) {
            val isTransferOnly = field == Field.Fee || field == Field.Transfer
            this.field =
                if (isTransferOnly && form.type != Entry.Kind.transfer) Field.Amount else field
        }

        fun select(category: EntryCategory) {
            form = form.withCategory(category.id)
            field = Field.Amount
        }

        fun toggleTag(id: Identifier<EntryTag>) {
            form = form.copy(tagId = if (form.tagId == id) null else id)
        }

        fun selectDestination(wallet: Wallet) {
            form = form.copy(toWalletId = wallet.id)
            field = Field.Transfer
        }

        fun swapWallets() {
            form = form.copy(
                walletId = form.toWalletId,
                toWalletId = form.walletId,
                billMonth = null,
            )
        }

        fun select(date: LocalDate) {
            form = form.withDate(date)
            field = Field.Amount
        }

        fun press(key: AmountCalculator.Key) {
            if (field == Field.Fee) {
                feeCalculator = feeCalculator.press(key)
            } else {
                calculator = calculator.press(key)
            }
        }

        fun setAmount(amount: Int) {
            calculator = AmountCalculator(amount = amount)
        }

        fun setFee(amount: Int) {
            feeCalculator = AmountCalculator(amount = amount)
        }

        fun clear() {
            form = form.cleared()
            calculator = AmountCalculator()
            feeCalculator = AmountCalculator()
            voiceFilled = null
        }

        internal fun fill(
            form: EntryForm,
            calculator: AmountCalculator,
            voiceFilled: VoiceFilled?,
        ) {
            this.form = form
            this.calculator = calculator
            this.voiceFilled = voiceFilled
        }

        internal fun load(
            form: EntryForm,
            amount: Int,
            fee: Int,
        ) {
            this.form = form
            calculator = AmountCalculator(amount = amount)
            feeCalculator = AmountCalculator(amount = fee)
        }
    }

    class Input(
        editingId: Identifier<Entry>?,
    ) {
        var editingId: Identifier<Entry>? by mutableStateOf(editingId)
            internal set

        var original: Entry? = null
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
    ) {
        val isEditing: Boolean
            get() = input.editingId != null

        val isBlank: Boolean
            get() = !isEditing && amount <= 0

        val startField: Field
            get() = if (state.form.type == Entry.Kind.transfer) Field.Transfer else Field.Category

        val showsRecent: Boolean
            get() = isBlank && state.field == startField

        val amount: Int
            get() = state.calculator.amount

        val fee: Int
            get() = if (state.form.type == Entry.Kind.transfer) state.feeCalculator.amount else 0

        val activeCalculator: AmountCalculator
            get() = if (state.field == Field.Fee) state.feeCalculator else state.calculator
    }

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
                    fee = database.fee(of = entry.id)?.amount ?: 0,
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
        if (!store()) {
            return false
        }

        state.outcome.send(Outcome.Closed)

        return true
    }

    suspend fun saveAndContinue(): Boolean {
        if (!store()) {
            return false
        }

        startNext()
        state.outcome.send(Outcome.Continued)

        return true
    }

    private suspend fun store(): Boolean {
        val draft = output.draft

        if (draft == null || state.task.isRunning) {
            return false
        }

        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            state.task.show(output.message(of = problem))
            return false
        }

        val saved = state.task.attempt(describe = ::describe) {
            dependencies.database.saveEntry(
                draft = draft,
                editing = input.editingId,
                at = dependencies.clock.now,
            )
        }

        return saved != null
    }

    suspend fun delete(): Boolean {
        val original = input.original

        if (original == null || state.task.isRunning) {
            return false
        }

        val deleted = state.task.attempt(describe = ::describe) {
            dependencies.database.deleteEntry(
                id = original.id,
                at = dependencies.clock.now,
            )
        }

        if (deleted != null) {
            state.outcome.send(Outcome.Closed)
        }

        return deleted != null
    }

    suspend fun startNext() {
        state.clear()
        state.focus(output.startField)

        state.task.attempt(describe = ::describe) {
            loadHistory()
        }

        input.baseline = output.snapshot
    }

    suspend fun reloadTemplates() {
        state.task.attempt(describe = ::describe) {
            input.allTemplates = dependencies.database.templates()
        }
    }

    private suspend fun loadHistory() {
        val database = dependencies.database

        input.recentItemNames = database.recentItemNames(limit = RECENT_ITEM_NAME_LIMIT)
        input.recentMemos = database.recentMemos(limit = RECENT_MEMO_LIMIT)
        input.history = database.entryList()
    }

    private suspend fun loadEntry(): Entry? {
        val database = dependencies.database
        val editing = input.editingId ?: return null
        val missing = EntryWriteException(EntryWriteError.entryNotFound)
        val found = database.entry(editing) ?: throw missing
        val entry = found.transferId?.let { database.entry(it) } ?: found

        input.editingId = entry.id
        input.original = entry

        return entry
    }
}
