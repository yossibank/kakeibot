package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.recurring.billChoiceCount
import com.yossibank.kakeibot.core.concepts.recurring.billDates
import com.yossibank.kakeibot.core.concepts.recurring.cardBill
import com.yossibank.kakeibot.core.concepts.recurring.endDate
import com.yossibank.kakeibot.core.concepts.recurring.maxCount
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.features.shared.entrylist.EntryText
import com.yossibank.kakeibot.features.shared.model.ModelTask
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.latestEntryList
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

class RecurringEditModel(
    private val database: AppDatabase,
    today: LocalDate,
    type: Entry.Kind = Entry.Kind.expense,
    internal val editingId: Identifier<Recurring>? = null,
) {
    var today: LocalDate by mutableStateOf(today)
    var isScheduleOpen: Boolean by mutableStateOf(editingId == null)

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

    var isHidden: Boolean by mutableStateOf(false)
        private set

    internal var loanBalances: Map<Identifier<Wallet>, Long> by mutableStateOf(emptyMap())
        private set

    internal var generatedUntil: LocalDate? = null
        private set

    private var options: EntryOptions? by mutableStateOf(null)
    private var cardBills: List<Recurring> by mutableStateOf(emptyList())
    private var baseline: RecurringDraft? by mutableStateOf(null)
    private var isHolidayShiftChosen = false

    private val task = ModelTask()

    val isEditing: Boolean
        get() = editingId != null

    val message: String
        get() = task.message

    val amount: Int
        get() = calculator.amount

    val fee: Int
        get() = feeCalculator.amount

    val walletTitle: String
        get() = EntryText.walletTitle(form.type)

    val draft: RecurringDraft
        get() = RecurringDraft(
            type = form.type,
            amount = amount,
            categoryId = form.categoryId,
            walletId = form.walletId,
            toWalletId = form.toWalletId,
            memo = form.memo,
            frequency = form.frequency,
            month = form.month,
            day = form.day,
            holidayShift = form.holidayShift,
            closingDay = if (canUseClosingDay) form.closingDay else null,
            fee = if (form.type == Entry.Kind.transfer) fee else 0,
            finalAmount = finalAmount ?: 0,
            billShift = if (billRecurring == null) 0 else form.billShift,
            startDate = form.startDate,
            endDate = scheduledEndDate,
            remindDaysBefore = form.remindDaysBefore,
        )

    val billRecurring: Recurring?
        get() {
            if (form.type == Entry.Kind.transfer) {
                return null
            }

            return cardBills.cardBill(paidBy = form.walletId)
        }

    val billDates: List<LocalDate>
        get() {
            val bill = billRecurring ?: return emptyList()
            val next = previewRow.next ?: return emptyList()

            return bill.billDates(
                used = next,
                count = Recurring.billChoiceCount,
            )
        }

    val canUseClosingDay: Boolean
        get() = form.type == Entry.Kind.transfer && selectedDestination?.kind == Wallet.Kind.card

    val isCardBill: Boolean
        get() = canUseClosingDay && form.closingDay != null

    val isLoanRepayment: Boolean
        get() = form.type == Entry.Kind.transfer && selectedDestination?.kind == Wallet.Kind.loan

    val canSave: Boolean
        get() = draft.problems.isEmpty()

    val saveTitle: String
        get() {
            val problem = draft.problems.firstOrNull() ?: return if (isEditing) "変更を保存" else "追加する"
            return message(problem)
        }

    val isChanged: Boolean
        get() = baseline?.let { it != draft } ?: false

    val categories: List<EntryCategory>
        get() = when (form.type) {
            Entry.Kind.expense -> options?.expenseCategories.orEmpty()
            Entry.Kind.income -> options?.incomeCategories.orEmpty()
            Entry.Kind.transfer -> emptyList()
        }

    val wallets: List<Wallet>
        get() = options?.wallets.orEmpty()

    val selectedCategory: EntryCategory?
        get() = categories.firstOrNull { it.id == form.categoryId }

    val selectedWallet: Wallet?
        get() = wallets.firstOrNull { it.id == form.walletId }

    val selectedDestination: Wallet?
        get() = wallets.firstOrNull { it.id == form.toWalletId }

    private val suggestedHolidayShift: HolidayShift
        get() {
            if (form.type == Entry.Kind.transfer) {
                return HolidayShift.next
            }

            val glyph = selectedCategory?.let { icon(it.iconId) }?.glyph

            return when (glyph) {
                Icon.Glyph.salary, Icon.Glyph.bonus -> HolidayShift.previous
                Icon.Glyph.home, Icon.Glyph.utility, Icon.Glyph.phone -> HolidayShift.next
                else -> HolidayShift.none
            }
        }

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    fun update(change: RecurringEditForm.() -> RecurringEditForm) {
        form = form.change()
    }

    fun select(type: Entry.Kind) {
        if (type == form.type) {
            return
        }

        form = form.copy(type = type)
        form = form.copy(categoryId = categories.firstOrNull()?.id)

        presetDestination()
        suggestHolidayShift()
    }

    @JvmName("selectCategory")
    fun select(category: Identifier<EntryCategory>) {
        form = form.copy(categoryId = category)
        suggestHolidayShift()
    }

    @JvmName("selectWallet")
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

    fun prepareCount() {
        loan = loan.copy(count = AmountCalculator(amount = repaymentCount ?: 0))
    }

    fun pressCount(key: AmountCalculator.Key) {
        val pressed = loan.count.press(key)
        val isOver = pressed.amount > Recurring.maxCount
        val count = if (isOver) AmountCalculator(amount = Recurring.maxCount) else pressed

        loan = loan.copy(count = count)

        val end = recurring(
            endDate = null,
            finalAmount = null,
        ).endDate(
            afterCount = count.amount,
            from = repaymentStart,
        )

        setEnd(end)
    }

    fun setEnd(date: LocalDate?) {
        form = form.copy(endDate = date)

        loan = loan.copy(
            isCountAuto = false,
            manualFinal = manualFinalAmount(through = date),
        )
    }

    fun useAutoCount() {
        loan = loan.copy(
            isCountAuto = true,
            manualFinal = null,
        )
    }

    fun clearMessage() {
        task.clear()
    }

    suspend fun load() {
        task.attempt(failure = LOAD_FAILED) {
            options = database.entryOptions()
            cardBills = database.recurrings()

            loadLoanBalances()
            loadRecurring()

            if (form.categoryId == null) {
                form = form.copy(categoryId = categories.firstOrNull()?.id)
            }

            suggestHolidayShift()

            if (form.walletId == null) {
                form = form.copy(walletId = wallets.firstOrNull()?.id)
            }

            presetDestination()
            chooseCountMode()
            baseline = draft
        }
    }

    suspend fun save(): Boolean {
        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            task.show(message(problem))
            return false
        }

        if (task.isRunning) {
            return false
        }

        val saved = task.attempt(failure = ModelTask.saveFailed) {
            database.saveRecurring(
                draft = draft,
                editing = editingId,
                today = today,
                at = Instant.now(),
            )
        }

        return saved != null
    }

    suspend fun delete(): Deletion? {
        val id = editingId ?: return null

        return task.attempt(failure = ModelTask.saveFailed) {
            database.deleteRecurring(
                id = id,
                at = Instant.now(),
            )
        }
    }

    suspend fun setHidden(isHidden: Boolean): Boolean {
        val id = editingId ?: return false

        val done = task.attempt(failure = ModelTask.saveFailed) {
            database.setRecurringHidden(
                id = id,
                isHidden = isHidden,
                today = today,
                at = Instant.now(),
            )
        }

        if (done != null) {
            this.isHidden = isHidden
        }

        return done != null
    }

    internal fun recurring(
        endDate: LocalDate?,
        finalAmount: Int?,
    ): Recurring = Recurring(
        type = form.type,
        amount = amount,
        categoryId = null,
        walletId = form.walletId ?: Identifier(),
        toWalletId = form.toWalletId,
        frequency = form.frequency,
        month = if (form.frequency == Recurring.Frequency.yearly) form.month else null,
        day = form.day,
        holidayShift = form.holidayShift,
        finalAmount = finalAmount,
        startDate = form.startDate,
        endDate = endDate,
        createdAt = Instant.EPOCH,
        updatedAt = Instant.EPOCH,
    )

    private fun chooseCountMode() {
        if (!isEditing) {
            loan = loan.copy(isCountAuto = true)
            return
        }

        val plan = autoPlan
        val end = form.endDate

        if (plan == null || end == null) {
            loan = loan.copy(isCountAuto = false)
            return
        }

        val isAuto = autoEndDate(plan) == end && plan.finalAmount == loan.manualFinal

        loan = loan.copy(isCountAuto = isAuto)
    }

    private suspend fun loadLoanBalances() {
        val list = database.latestEntryList()

        loanBalances = wallets
            .filter { it.kind == Wallet.Kind.loan }
            .associate { wallet ->
                wallet.id to list.balance(
                    of = wallet,
                    through = today,
                )
            }
    }

    private fun presetDestination() {
        if (form.type != Entry.Kind.transfer || form.toWalletId != null) {
            return
        }

        form = form.copy(toWalletId = wallets.firstOrNull { it.id != form.walletId }?.id)
    }

    private fun suggestHolidayShift() {
        if (isEditing || isHolidayShiftChosen) {
            return
        }

        form = form.copy(holidayShift = suggestedHolidayShift)
    }

    private fun message(problem: RecurringDraft.Problem): String = when (problem) {
        RecurringDraft.Problem.amountNotPositive -> "金額を入れてください"
        RecurringDraft.Problem.missingCategory -> "カテゴリを選んでください"
        RecurringDraft.Problem.missingWallet -> "${walletTitle}を選んでください"
        RecurringDraft.Problem.missingDestination -> "${EntryText.destinationTitle}を選んでください"
        RecurringDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
        RecurringDraft.Problem.endBeforeStart -> "終わりを始まりより後にしてください"
        else -> ModelTask.saveFailed
    }

    private suspend fun loadRecurring() {
        val id = editingId ?: return

        val recurring = database.recurrings(includingHidden = true).firstOrNull { it.id == id }
            ?: throw IllegalStateException("recurringNotFound")

        val draft = RecurringDraft(recurring = recurring)

        isHidden = recurring.archivedAt != null
        form = RecurringEditForm.of(draft)
        calculator = AmountCalculator(amount = draft.amount)
        feeCalculator = AmountCalculator(amount = draft.fee)
        loan = loan.copy(manualFinal = recurring.finalAmount)
        generatedUntil = recurring.generatedUntil
    }

    companion object {
        val remindChoices: List<Int?> = listOf(null, 0, 1, 3, 7)

        private const val LOAD_FAILED = "固定費を読めませんでした"
    }
}
