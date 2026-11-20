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
import com.yossibank.kakeibot.core.concepts.recurring.RepaymentPlan
import com.yossibank.kakeibot.core.concepts.recurring.billChoiceCount
import com.yossibank.kakeibot.core.concepts.recurring.billDates
import com.yossibank.kakeibot.core.concepts.recurring.cardBill
import com.yossibank.kakeibot.core.concepts.recurring.dates
import com.yossibank.kakeibot.core.concepts.recurring.endDate
import com.yossibank.kakeibot.core.concepts.recurring.maxCount
import com.yossibank.kakeibot.core.concepts.recurring.nextDate
import com.yossibank.kakeibot.core.concepts.recurring.scheduledAmount
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.latestEntryList
import com.yossibank.kakeibot.store.queries.methods.recurrings
import com.yossibank.kakeibot.store.queries.types.EntryOptions
import com.yossibank.kakeibot.store.writes.methods.deleteRecurring
import com.yossibank.kakeibot.store.writes.methods.saveRecurring
import com.yossibank.kakeibot.store.writes.methods.setRecurringHidden
import com.yossibank.kakeibot.store.writes.types.Deletion
import kotlinx.coroutines.CancellationException
import java.time.Instant

class RecurringEditModel(
    private val database: AppDatabase,
    val today: LocalDate,
    type: Entry.Kind = Entry.Kind.expense,
    private val editingId: Identifier<Recurring>? = null,
) {
    var categoryId: Identifier<EntryCategory>? by mutableStateOf(null)
    var toWalletId: Identifier<Wallet>? by mutableStateOf(null)
    var memo: String by mutableStateOf("")
    var frequency: Recurring.Frequency by mutableStateOf(Recurring.Frequency.monthly)
    var month: Int by mutableStateOf(today.month)
    var day: Int by mutableStateOf(today.day)
    var closingDay: Int? by mutableStateOf(null)
    var startDate: LocalDate by mutableStateOf(today)
    var endDate: LocalDate? by mutableStateOf(null)
    var remindDaysBefore: Int? by mutableStateOf(null)
    var billShift: Int by mutableStateOf(0)
    var isScheduleOpen: Boolean by mutableStateOf(editingId == null)
    var isNotificationAllowed: Boolean by mutableStateOf(true)

    var walletId: Identifier<Wallet>? by mutableStateOf(null)
        private set

    var holidayShift: HolidayShift by mutableStateOf(HolidayShift.none)
        private set

    var type: Entry.Kind by mutableStateOf(type)
        private set

    var calculator by mutableStateOf(AmountCalculator())
        private set

    var feeCalculator by mutableStateOf(AmountCalculator())
        private set

    var countCalculator by mutableStateOf(AmountCalculator())
        private set

    var isCountAuto: Boolean by mutableStateOf(true)
        private set

    var isHidden: Boolean by mutableStateOf(false)
        private set

    var message: String by mutableStateOf("")
        private set

    private var options: EntryOptions? by mutableStateOf(null)
    private var cardBills: List<Recurring> by mutableStateOf(emptyList())
    private var loanBalances: Map<Identifier<Wallet>, Long> by mutableStateOf(emptyMap())
    private var baseline: RecurringDraft? by mutableStateOf(null)
    private var manualFinal: Int? by mutableStateOf(null)
    private var generatedUntil: LocalDate? = null
    private var isHolidayShiftChosen = false

    val isEditing: Boolean
        get() = editingId != null

    val amount: Int
        get() = calculator.amount

    val fee: Int
        get() = feeCalculator.amount

    val walletTitle: String
        get() = when (type) {
            Entry.Kind.expense -> "支払い元"
            Entry.Kind.income -> "入金先"
            Entry.Kind.transfer -> "振替元"
        }

    val draft: RecurringDraft
        get() = RecurringDraft(
            type = type,
            amount = amount,
            categoryId = categoryId,
            walletId = walletId,
            toWalletId = toWalletId,
            memo = memo,
            frequency = frequency,
            month = month,
            day = day,
            holidayShift = holidayShift,
            closingDay = if (canUseClosingDay) closingDay else null,
            fee = if (type == Entry.Kind.transfer) fee else 0,
            finalAmount = finalAmount ?: 0,
            billShift = if (billRecurring == null) 0 else billShift,
            startDate = startDate,
            endDate = scheduledEndDate,
            remindDaysBefore = remindDaysBefore,
        )

    val billRecurring: Recurring?
        get() = if (type == Entry.Kind.transfer) null else cardBills.cardBill(paidBy = walletId)

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
        get() = type == Entry.Kind.transfer && selectedDestination?.kind == Wallet.Kind.card

    val isCardBill: Boolean
        get() = canUseClosingDay && closingDay != null

    val isLoanRepayment: Boolean
        get() = type == Entry.Kind.transfer && selectedDestination?.kind == Wallet.Kind.loan

    val loanOwed: Int?
        get() {
            if (!isLoanRepayment) {
                return null
            }

            val balance = toWalletId?.let { loanBalances[it] } ?: return null

            return if (balance <
                0
            ) {
                (-balance).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
            } else {
                null
            }
        }

    val autoPlan: RepaymentPlan?
        get() = loanOwed?.let {
            RepaymentPlan.of(
                owed = it,
                amount = amount,
            )
        }

    val usesAutoCount: Boolean
        get() = isCountAuto && autoPlan != null

    val repaymentStart: LocalDate
        get() {
            val next = generatedUntil?.adding(days = 1) ?: startDate
            return maxOf(startDate, next)
        }

    val scheduledEndDate: LocalDate?
        get() {
            val plan = autoPlan

            if (!usesAutoCount || plan == null) {
                return endDate
            }

            return autoEndDate(plan)
        }

    val finalAmount: Int?
        get() {
            if (!isLoanRepayment) {
                return null
            }

            return if (usesAutoCount) autoPlan?.finalAmount else manualFinal
        }

    val repaymentCount: Int?
        get() {
            val end = scheduledEndDate ?: return null

            return recurring(
                endDate = end,
                finalAmount = finalAmount,
            ).dates(
                from = repaymentStart,
                through = end,
            ).size
        }

    val plannedTotal: Long?
        get() {
            val end = scheduledEndDate ?: return null

            val planned = recurring(
                endDate = end,
                finalAmount = finalAmount,
            )

            return planned
                .dates(
                    from = repaymentStart,
                    through = end,
                ).sumOf { planned.scheduledAmount(paidOn = it).toLong() }
        }

    val balanceGap: Long?
        get() {
            val owed = loanOwed ?: return null
            val total = plannedTotal ?: return null
            return if (total != owed.toLong()) total - owed else null
        }

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
        get() = when (type) {
            Entry.Kind.expense -> options?.expenseCategories.orEmpty()
            Entry.Kind.income -> options?.incomeCategories.orEmpty()
            Entry.Kind.transfer -> emptyList()
        }

    val wallets: List<Wallet>
        get() = options?.wallets.orEmpty()

    val selectedCategory: EntryCategory?
        get() = categories.firstOrNull { it.id == categoryId }

    val selectedWallet: Wallet?
        get() = wallets.firstOrNull { it.id == walletId }

    val selectedDestination: Wallet?
        get() = wallets.firstOrNull { it.id == toWalletId }

    val isNotificationDenied: Boolean
        get() = remindDaysBefore != null && !isNotificationAllowed

    val previewRow: RecurringRow
        get() {
            val schedule = RecurringText.schedule(
                frequency = frequency,
                month = month,
                day = day,
            )

            val name = memo.trim()
            val destination = if (type == Entry.Kind.transfer) selectedDestination?.name else null
            val place = listOfNotNull(selectedWallet?.name, destination).joinToString(" → ")

            val icon = if (type == Entry.Kind.transfer) {
                selectedWallet?.let { icon(it.iconId) }
            } else {
                selectedCategory?.let { icon(it.iconId) }
            }

            val next = recurring(
                endDate = scheduledEndDate,
                finalAmount = null,
            ).nextDate(onOrAfter = today)

            return RecurringRow(
                id = editingId ?: Identifier(),
                title = name.ifEmpty { selectedCategory?.name ?: RecurringListModel.title(type) },
                schedule = RecurringText.detail(
                    schedule = schedule,
                    holiday = RecurringText.holidayNote(holidayShift),
                ),
                place = place.ifEmpty { null },
                amount = if (isCardBill) null else amount,
                type = type,
                icon = icon,
                next = next,
                closing = if (canUseClosingDay) {
                    closingDay?.let(
                        RecurringText::closingNote,
                    )
                } else {
                    null
                },
            )
        }

    fun icon(of: Identifier<Icon>): Icon? = options?.icons?.get(of)

    fun select(type: Entry.Kind) {
        if (type == this.type) {
            return
        }

        this.type = type
        categoryId = categories.firstOrNull()?.id

        presetDestination()
        suggestHolidayShift()
    }

    @JvmName("selectCategory")
    fun select(category: Identifier<EntryCategory>) {
        categoryId = category
        suggestHolidayShift()
    }

    @JvmName("selectWallet")
    fun select(wallet: Identifier<Wallet>) {
        if (wallet != walletId) {
            billShift = 0
        }

        walletId = wallet
    }

    fun choose(shift: HolidayShift) {
        holidayShift = shift
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
        countCalculator = AmountCalculator(amount = repaymentCount ?: 0)
    }

    fun pressCount(key: AmountCalculator.Key) {
        countCalculator = countCalculator.press(key)

        if (countCalculator.amount > Recurring.maxCount) {
            countCalculator = AmountCalculator(amount = Recurring.maxCount)
        }

        val end = recurring(
            endDate = null,
            finalAmount = null,
        ).endDate(
            afterCount = countCalculator.amount,
            from = repaymentStart,
        )

        setEnd(end)
    }

    fun setEnd(date: LocalDate?) {
        isCountAuto = false
        endDate = date
        manualFinal = manualFinalAmount(through = date)
    }

    fun useAutoCount() {
        isCountAuto = true
        manualFinal = null
    }

    fun clearMessage() {
        message = ""
    }

    suspend fun load() {
        try {
            options = database.entryOptions()
            cardBills = database.recurrings()

            loadLoanBalances()
            loadRecurring()

            if (categoryId == null) {
                categoryId = categories.firstOrNull()?.id
            }

            suggestHolidayShift()

            if (walletId == null) {
                walletId = wallets.firstOrNull()?.id
            }

            presetDestination()
            chooseCountMode()
            baseline = draft
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            message = LOAD_FAILED
        }
    }

    suspend fun save(): Boolean {
        val problem = draft.problems.firstOrNull()

        if (problem != null) {
            message = message(problem)
            return false
        }

        return run {
            database.saveRecurring(
                draft = draft,
                editing = editingId,
                today = today,
                at = Instant.now(),
            )
        }
    }

    suspend fun delete(): Deletion? {
        val id = editingId ?: return null

        var deletion: Deletion? = null

        run {
            deletion = database.deleteRecurring(
                id = id,
                at = Instant.now(),
            )
        }

        return deletion
    }

    suspend fun setHidden(isHidden: Boolean): Boolean {
        val id = editingId ?: return false

        val isDone = run {
            database.setRecurringHidden(
                id = id,
                isHidden = isHidden,
                today = today,
                at = Instant.now(),
            )
        }

        if (isDone) {
            this.isHidden = isHidden
        }

        return isDone
    }

    private val suggestedHolidayShift: HolidayShift
        get() {
            if (type == Entry.Kind.transfer) {
                return HolidayShift.next
            }

            val glyph = selectedCategory?.let { icon(it.iconId) }?.glyph

            return when (glyph) {
                Icon.Glyph.salary, Icon.Glyph.bonus -> HolidayShift.previous
                Icon.Glyph.home, Icon.Glyph.utility, Icon.Glyph.phone -> HolidayShift.next
                else -> HolidayShift.none
            }
        }

    private fun recurring(
        endDate: LocalDate?,
        finalAmount: Int?,
    ): Recurring = Recurring(
        type = type,
        amount = amount,
        categoryId = null,
        walletId = walletId ?: Identifier(),
        toWalletId = toWalletId,
        frequency = frequency,
        month = if (frequency == Recurring.Frequency.yearly) month else null,
        day = day,
        holidayShift = holidayShift,
        finalAmount = finalAmount,
        startDate = startDate,
        endDate = endDate,
        createdAt = Instant.EPOCH,
        updatedAt = Instant.EPOCH,
    )

    private fun autoEndDate(plan: RepaymentPlan): LocalDate? = recurring(
        endDate = null,
        finalAmount = null,
    ).endDate(
        afterCount = plan.count,
        from = repaymentStart,
    )

    private fun manualFinalAmount(through: LocalDate?): Int? {
        val end = through ?: return null
        val owed = loanOwed ?: return null

        val count = recurring(
            endDate = end,
            finalAmount = null,
        ).dates(
            from = repaymentStart,
            through = end,
        ).size

        return RepaymentPlan
            .of(
                owed = owed,
                amount = amount,
                count = count,
            )?.finalAmount
    }

    private fun chooseCountMode() {
        if (!isEditing) {
            isCountAuto = true
            return
        }

        val plan = autoPlan
        val end = endDate

        if (plan == null || end == null) {
            isCountAuto = false
            return
        }

        isCountAuto = autoEndDate(plan) == end && plan.finalAmount == manualFinal
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
        if (type != Entry.Kind.transfer || toWalletId != null) {
            return
        }

        toWalletId = wallets.firstOrNull { it.id != walletId }?.id
    }

    private fun suggestHolidayShift() {
        if (isEditing || isHolidayShiftChosen) {
            return
        }

        holidayShift = suggestedHolidayShift
    }

    private fun message(problem: RecurringDraft.Problem): String = when (problem) {
        RecurringDraft.Problem.amountNotPositive -> "金額を入れてください"
        RecurringDraft.Problem.missingCategory -> "カテゴリを選んでください"
        RecurringDraft.Problem.missingWallet -> "${walletTitle}を選んでください"
        RecurringDraft.Problem.missingDestination -> "${DESTINATION_TITLE}を選んでください"
        RecurringDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
        RecurringDraft.Problem.endBeforeStart -> "終わりを始まりより後にしてください"
        else -> SAVE_FAILED
    }

    private suspend fun loadRecurring() {
        val id = editingId ?: return

        val recurring = database.recurrings(includingHidden = true).firstOrNull { it.id == id }
            ?: throw IllegalStateException("recurringNotFound")

        val draft = RecurringDraft(recurring = recurring)

        isHidden = recurring.archivedAt != null
        type = draft.type
        calculator = AmountCalculator(amount = draft.amount)
        categoryId = draft.categoryId
        walletId = draft.walletId
        toWalletId = draft.toWalletId
        memo = draft.memo
        frequency = draft.frequency
        month = draft.month
        day = draft.day
        holidayShift = draft.holidayShift
        closingDay = draft.closingDay
        feeCalculator = AmountCalculator(amount = draft.fee)
        manualFinal = recurring.finalAmount
        generatedUntil = recurring.generatedUntil
        billShift = draft.billShift
        startDate = draft.startDate
        endDate = draft.endDate
        remindDaysBefore = draft.remindDaysBefore
    }

    private suspend fun run(action: suspend () -> Unit): Boolean = try {
        action()
        true
    } catch (error: CancellationException) {
        throw error
    } catch (_: Exception) {
        message = SAVE_FAILED
        false
    }

    companion object {
        const val DESTINATION_TITLE = "振替先"

        val remindChoices: List<Int?> = listOf(null, 0, 1, 3, 7)

        private const val LOAD_FAILED = "固定費を読めませんでした"
        private const val SAVE_FAILED = "保存できませんでした"
    }
}
