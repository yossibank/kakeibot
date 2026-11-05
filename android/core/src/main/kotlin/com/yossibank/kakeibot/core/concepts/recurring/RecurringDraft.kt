package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.time.Instant

data class RecurringDraft(
    val type: Entry.Kind,
    val amount: Int,
    val categoryId: Identifier<EntryCategory>?,
    val walletId: Identifier<Wallet>?,
    val toWalletId: Identifier<Wallet>? = null,
    val memo: String = "",
    val frequency: Recurring.Frequency,
    val month: Int,
    val day: Int,
    val holidayShift: HolidayShift = HolidayShift.none,
    val closingDay: Int? = null,
    val fee: Int = 0,
    val billShift: Int = 0,
    val startDate: LocalDate,
    val endDate: LocalDate? = null,
    val remindDaysBefore: Int? = null,
) {
    constructor(recurring: Recurring) : this(
        type = recurring.type,
        amount = recurring.amount,
        categoryId = recurring.categoryId,
        walletId = recurring.walletId,
        toWalletId = recurring.toWalletId,
        memo = recurring.memo ?: "",
        frequency = recurring.frequency,
        month = recurring.month ?: recurring.startDate.month,
        day = recurring.day,
        holidayShift = recurring.holidayShift,
        closingDay = recurring.closingDay,
        fee = recurring.fee ?: 0,
        billShift = recurring.billShift,
        startDate = recurring.startDate,
        endDate = recurring.endDate,
        remindDaysBefore = recurring.remindDaysBefore,
    )

    @Serializable
    enum class Problem {
        amountNotPositive,
        missingCategory,
        categoryOnTransfer,
        missingWallet,
        missingDestination,
        sameWallet,
        dayOutOfRange,
        closingDayOutOfRange,
        monthOutOfRange,
        endBeforeStart,
        remindOutOfRange,
        feeNegative,
    }

    class ProblemException(
        val problem: Problem,
    ) : Exception(problem.name)

    private data class Fields(
        val categoryId: Identifier<EntryCategory>?,
        val walletId: Identifier<Wallet>,
    )

    val problems: List<Problem>
        get() {
            val problems = mutableListOf<Problem>()
            val closingDay = cardClosingDay
            val endDate = endDate
            val remindDaysBefore = remindDaysBefore

            if (amount < 1 && closingDay == null) {
                problems += Problem.amountNotPositive
            }

            problems += categoryProblems

            if (walletId == null) {
                problems += Problem.missingWallet
            }

            problems += destinationProblems

            if (day !in 1..31) {
                problems += Problem.dayOutOfRange
            }

            if (closingDay != null && closingDay !in 1..31) {
                problems += Problem.closingDayOutOfRange
            }

            if (fee < 0) {
                problems += Problem.feeNegative
            }

            if (frequency == Recurring.Frequency.yearly && month !in 1..12) {
                problems += Problem.monthOutOfRange
            }

            if (endDate != null && endDate < startDate) {
                problems += Problem.endBeforeStart
            }

            if (remindDaysBefore != null && remindDaysBefore !in remindRange) {
                problems += Problem.remindOutOfRange
            }

            return problems
        }

    private val categoryProblems: List<Problem>
        get() = when (type) {
            Entry.Kind.expense,
            Entry.Kind.income,
            -> if (categoryId == null) listOf(Problem.missingCategory) else emptyList()

            Entry.Kind.transfer -> if (categoryId == null) emptyList() else listOf(Problem.categoryOnTransfer)
        }

    private val destinationProblems: List<Problem>
        get() {
            if (type != Entry.Kind.transfer) {
                return emptyList()
            }

            val toWalletId = toWalletId ?: return listOf(Problem.missingDestination)

            return if (toWalletId == walletId) listOf(Problem.sameWallet) else emptyList()
        }

    private val destination: Identifier<Wallet>?
        get() = if (type == Entry.Kind.transfer) toWalletId else null

    private val cardClosingDay: Int?
        get() = if (type == Entry.Kind.transfer) closingDay else null

    private val savedFee: Int?
        get() = if (type == Entry.Kind.transfer && fee > 0) fee else null

    private val savedBillShift: Int
        get() = if (type == Entry.Kind.transfer) 0 else Recurring.clampedBillShift(billShift)

    private val savedAmount: Int
        get() = if (cardClosingDay == null) amount else 0

    private val yearlyMonth: Int?
        get() = if (frequency == Recurring.Frequency.yearly) month else null

    private val trimmedMemo: String?
        get() = memo.trim().ifEmpty { null }

    fun newRecurring(at: Instant): Recurring {
        val fields = validated()

        return Recurring(
            type = type,
            amount = savedAmount,
            categoryId = fields.categoryId,
            walletId = fields.walletId,
            toWalletId = destination,
            memo = trimmedMemo,
            frequency = frequency,
            month = yearlyMonth,
            day = day,
            holidayShift = holidayShift,
            closingDay = cardClosingDay,
            fee = savedFee,
            billShift = savedBillShift,
            startDate = startDate,
            endDate = endDate,
            remindDaysBefore = remindDaysBefore,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: Recurring,
        at: Instant,
    ): Recurring {
        val fields = validated()

        return to.copy(
            type = type,
            amount = savedAmount,
            categoryId = fields.categoryId,
            walletId = fields.walletId,
            toWalletId = destination,
            memo = trimmedMemo,
            frequency = frequency,
            month = yearlyMonth,
            day = day,
            holidayShift = holidayShift,
            closingDay = cardClosingDay,
            fee = savedFee,
            billShift = savedBillShift,
            startDate = startDate,
            endDate = endDate,
            remindDaysBefore = remindDaysBefore,
            updatedAt = at,
        )
    }

    private fun validated(): Fields {
        problems.firstOrNull()?.let {
            throw ProblemException(it)
        }

        val walletId = walletId ?: throw ProblemException(Problem.missingWallet)

        return Fields(
            categoryId = categoryId,
            walletId = walletId,
        )
    }

    companion object {
        val remindRange = 0..30
    }
}
