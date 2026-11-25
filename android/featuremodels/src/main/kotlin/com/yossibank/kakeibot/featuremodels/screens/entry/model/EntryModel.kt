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
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
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
) {
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

    class State(
        today: LocalDate,
    ) {
        val task = ModelTask()

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

            task.clear()
        }

        fun toggleTag(id: Identifier<EntryTag>) {
            form = form.copy(tagId = if (form.tagId == id) null else id)
        }

        fun selectDestination(wallet: Wallet) {
            form = form.copy(toWalletId = wallet.id)
            field = Field.Transfer

            task.clear()
        }

        fun swapWallets() {
            form = form.copy(
                walletId = form.toWalletId,
                toWalletId = form.walletId,
                billMonth = null,
            )

            task.clear()
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

            task.clear()
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
        ) {
            this.form = form
            calculator = AmountCalculator(amount = amount)
        }
    }

    class Input(
        editingId: Identifier<Entry>?,
    ) {
        var editingId: Identifier<Entry>? by mutableStateOf(editingId)
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

    fun select(type: Entry.Kind) {
        if (state.form.type == type) {
            return
        }

        val isUntouched = !output.isEditing && !output.isChanged

        state.update { withType(type) }

        if (isUntouched && type != Entry.Kind.transfer) {
            setWallet(output.usualWalletId)
        }

        val form = state.form
        val categories = output.categories
        val remembered = form.categoryByType[type]

        val categoryId = when {
            categories.any { it.id == remembered } -> remembered
            categories.any { it.id == form.categoryId } -> form.categoryId
            else -> categories.firstOrNull()?.id
        }

        state.update { withCategory(categoryId) }

        if (type == Entry.Kind.transfer) {
            chooseDestination()
        }

        state.focus(output.startField)
        state.task.clear()

        if (isUntouched) {
            input.baseline = output.snapshot
        }
    }

    suspend fun load() {
        val database = dependencies.database

        state.task.attempt(failure = ModelTask.loadFailed) {
            database.insertDefaultsIfEmpty(at = dependencies.clock.now)

            val loaded = database.entryOptions()

            input.allTemplates = database.templates()
            input.cardBills = database.recurrings().filter { recurring ->
                recurring.type == Entry.Kind.transfer && recurring.closingDay != null
            }

            loadHistory()

            val entry = loadEntry()

            input.options = loaded

            if (entry != null) {
                val items = database.entryItems(of = entry.id).map { EntryItem.Draft(it) }

                state.load(
                    form = EntryForm.of(
                        entry = entry,
                        items = items,
                    ),
                    amount = entry.amount,
                )
                state.setFee(database.fee(of = entry.id)?.amount ?: 0)
            } else {
                state.update { withCategory(output.categories.firstOrNull()?.id) }
                setWallet(output.usualWalletId)
            }

            state.focus(output.startField)
            input.baseline = output.snapshot
        }
    }

    suspend fun save(): Boolean {
        val draft = output.draft

        if (draft == null || state.task.isRunning) {
            return false
        }

        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            state.task.show(output.message(of = problem))
            return false
        }

        val saved = state.task.attempt(describe = ::saveFailure) {
            dependencies.database.saveEntry(
                draft = draft,
                editing = input.editingId,
                at = dependencies.clock.now,
            )
        }

        return saved != null
    }

    suspend fun delete(): Boolean {
        val editing = input.editingId

        if (editing == null || state.task.isRunning) {
            return false
        }

        val deleted = state.task.attempt(failure = "削除できませんでした") {
            dependencies.database.deleteEntry(
                id = editing,
                at = dependencies.clock.now,
            )
        }

        return deleted != null
    }

    suspend fun startNext() {
        state.clear()
        state.focus(output.startField)

        state.task.attempt(failure = ModelTask.loadFailed) {
            loadHistory()
        }

        input.baseline = output.snapshot
    }

    suspend fun reloadTemplates() {
        state.task.attempt(failure = ModelTask.loadFailed) {
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
        val entry = input.editingId?.let { database.entry(it) } ?: return null
        val transferId = entry.transferId ?: return entry
        val transfer = database.entry(transferId) ?: return entry

        input.editingId = transfer.id

        return transfer
    }

    private fun saveFailure(error: Exception): String {
        val isMissing = (error as? EntryWriteException)?.error == EntryWriteError.entryNotFound
        return if (isMissing) "記録が見つかりませんでした" else ModelTask.saveFailed
    }
}
