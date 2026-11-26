package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.notification.NotificationAuthorization
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenOutcome
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.featuremodels.shared.notification.NotificationPermission
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.input.SettingsEditOutcome
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.latestEntryList
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import com.yossibank.kakeibot.store.writes.types.Deletion

class RecurringEditModel(
    parts: ScreenParts,
    today: LocalDate,
    type: Entry.Kind = Entry.Kind.expense,
    editingId: Identifier<Recurring>? = null,
) : ScreenPerforming {
    val state = State(today, type, isScheduleOpen = editingId == null)
    val input = Input(editingId)
    val output = Output(input, state)

    private val dependencies = Dependencies(parts.database, parts.clock)

    class State(
        today: LocalDate,
        type: Entry.Kind,
        isScheduleOpen: Boolean,
    ) {
        val task = ModelTask()
        val outcome = ScreenOutcome<SettingsEditOutcome<Unit>>()

        var today: LocalDate by mutableStateOf(today)
        var isScheduleOpen: Boolean by mutableStateOf(isScheduleOpen)
        var panel: RecurringPanel? by mutableStateOf(null)
        var prompt: RecurringEditPrompt? by mutableStateOf(null)

        var form: RecurringEditForm by mutableStateOf(
            RecurringEditForm.starting(
                today = today,
                type = type,
            ),
        )
            private set

        var calculator by mutableStateOf(AmountCalculator())
            private set

        var feeCalculator by mutableStateOf(AmountCalculator())
            private set

        var loan by mutableStateOf(RecurringLoanInput())
            private set

        var isHolidayShiftChosen = false
            private set

        fun update(change: RecurringEditForm.() -> RecurringEditForm) {
            form = form.change()
        }

        fun updateLoan(change: RecurringLoanInput.() -> RecurringLoanInput) {
            loan = loan.change()
        }

        fun select(wallet: Identifier<Wallet>) {
            form = form.withWallet(wallet)
        }

        fun choose(shift: HolidayShift) {
            form = form.copy(holidayShift = shift)
            isHolidayShiftChosen = true
        }

        fun press(key: AmountCalculator.Key) {
            calculator = calculator.press(key)
        }

        fun pressFee(key: AmountCalculator.Key) {
            feeCalculator = feeCalculator.press(key)
        }

        fun setFee(amount: Int) {
            feeCalculator = AmountCalculator(amount = amount)
        }

        fun useAutoCount() {
            loan = loan.copy(
                isCountAuto = true,
                manualFinal = null,
            )
        }

        fun load(recurring: Recurring) {
            val draft = RecurringDraft(recurring = recurring)

            form = RecurringEditForm.of(draft)
            calculator = AmountCalculator(amount = draft.amount)
            feeCalculator = AmountCalculator(amount = draft.fee)
            loan = loan.copy(manualFinal = recurring.finalAmount)
        }
    }

    class Input(
        val editingId: Identifier<Recurring>?,
    ) {
        var isHidden: Boolean by mutableStateOf(false)
            internal set

        var loanBalances: Map<Identifier<Wallet>, Long> by mutableStateOf(emptyMap())
            internal set

        var generatedUntil: LocalDate? by mutableStateOf(null)
            internal set

        var options: EntryOptions? by mutableStateOf(null)
            internal set

        var cardBills: List<Recurring> by mutableStateOf(emptyList())
            internal set

        var baseline: RecurringDraft? by mutableStateOf(null)
            internal set

        var authorization by mutableStateOf(NotificationAuthorization.allowed)
            internal set
    }

    class Output(
        internal val input: Input,
        internal val state: State,
    ) {
        val isEditing: Boolean
            get() = input.editingId != null

        val amount: Int
            get() = state.calculator.amount

        val fee: Int
            get() = state.feeCalculator.amount

        fun icon(of: Identifier<Icon>): Icon? = input.options?.icons?.get(of)
    }

    private class Dependencies(
        val database: AppDatabase,
        val clock: ScreenClock,
    )

    suspend fun load() {
        state.task.attempt(failure = LOAD_FAILED) {
            input.options = dependencies.database.entryOptions()
            input.cardBills = dependencies.database.recurrings()

            loadLoanBalances()
            loadRecurring()

            if (state.form.categoryId == null) {
                state.update { copy(categoryId = output.categories.firstOrNull()?.id) }
            }

            suggestHolidayShift()

            if (state.form.walletId == null) {
                state.update { copy(walletId = output.wallets.firstOrNull()?.id) }
            }

            presetDestination()
            chooseCountMode()
            input.baseline = output.draft
        }
    }

    fun refreshAuthorization(permission: NotificationPermission) {
        input.authorization = permission.authorization()
    }

    suspend fun save(permission: NotificationPermission = NotificationPermission.allowed): Boolean {
        if (!store(permission)) {
            return false
        }

        state.outcome.send(SettingsEditOutcome(saved = Unit))

        return true
    }

    suspend fun saveTogglingHidden(
        permission: NotificationPermission = NotificationPermission.allowed,
    ): Boolean {
        if (!store(permission)) {
            return false
        }

        val isHidden = !input.isHidden

        val outcome = if (hide(isHidden)) {
            SettingsEditOutcome(saved = Unit, isHidden = isHidden)
        } else {
            SettingsEditOutcome(saved = Unit, closes = false)
        }

        state.outcome.send(outcome)

        return true
    }

    suspend fun delete(): Deletion? {
        val id = input.editingId ?: return null

        val deletion = state.task.attempt(failure = ModelTask.saveFailed) {
            dependencies.database.deleteRecurring(
                id = id,
                at = dependencies.clock.now,
            )
        }

        deletion?.let { state.outcome.send(SettingsEditOutcome(deletion = it)) }

        return deletion
    }

    suspend fun setHidden(isHidden: Boolean): Boolean {
        if (!hide(isHidden)) {
            return false
        }

        state.outcome.send(SettingsEditOutcome(isHidden = isHidden))

        return true
    }

    private suspend fun store(permission: NotificationPermission): Boolean {
        val problem = output.draft.problems.firstOrNull()

        if (problem != null) {
            state.task.show(output.message(problem))
            return false
        }

        if (state.task.isRunning) {
            return false
        }

        val saved = state.task.attempt(failure = ModelTask.saveFailed) {
            dependencies.database.saveRecurring(
                draft = output.draft,
                editing = input.editingId,
                today = state.today,
                at = dependencies.clock.now,
            )
        }

        if (saved != null && state.form.remindDaysBefore != null) {
            permission.requestIfUndecided()
        }

        return saved != null
    }

    private suspend fun hide(isHidden: Boolean): Boolean {
        val id = input.editingId ?: return false

        val done = state.task.attempt(failure = ModelTask.saveFailed) {
            dependencies.database.setRecurringHidden(
                id = id,
                isHidden = isHidden,
                today = state.today,
                at = dependencies.clock.now,
            )
        }

        if (done != null) {
            input.isHidden = isHidden
        }

        return done != null
    }

    private suspend fun loadLoanBalances() {
        val list = dependencies.database.latestEntryList()

        input.loanBalances = output.wallets
            .filter { it.kind == Wallet.Kind.loan }
            .associate { wallet ->
                wallet.id to list.balance(
                    of = wallet,
                    through = state.today,
                )
            }
    }

    private suspend fun loadRecurring() {
        val id = input.editingId ?: return

        val recurring =
            dependencies.database.recurrings(includingHidden = true).firstOrNull { it.id == id }
                ?: throw IllegalStateException("recurringNotFound")

        input.isHidden = recurring.archivedAt != null
        state.load(recurring)
        input.generatedUntil = recurring.generatedUntil
    }

    companion object {
        val remindChoices: List<Int?> = listOf(null, 0, 1, 3, 7)

        private const val LOAD_FAILED = "固定費を読めませんでした"
    }
}
