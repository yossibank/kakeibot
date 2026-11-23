package com.yossibank.kakeibot.features.screens.settings.recurrings

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.recurring.RepaymentPlan
import com.yossibank.kakeibot.core.concepts.recurring.dates
import com.yossibank.kakeibot.core.concepts.recurring.endDate
import com.yossibank.kakeibot.core.concepts.recurring.scheduledAmount
import com.yossibank.kakeibot.designsystem.components.text.clamped

val RecurringEditModel.countCalculator: AmountCalculator
    get() = loan.count

val RecurringEditModel.loanOwed: Int?
    get() {
        if (!isLoanRepayment) {
            return null
        }

        val balance = form.toWalletId?.let { loanBalances[it] } ?: return null

        return if (balance < 0) (-balance).clamped else null
    }

val RecurringEditModel.autoPlan: RepaymentPlan?
    get() = loanOwed?.let {
        RepaymentPlan.of(
            owed = it,
            amount = amount,
        )
    }

val RecurringEditModel.usesAutoCount: Boolean
    get() = loan.isCountAuto && autoPlan != null

val RecurringEditModel.repaymentStart: LocalDate
    get() {
        val next = generatedUntil?.adding(days = 1) ?: form.startDate
        return maxOf(form.startDate, next)
    }

val RecurringEditModel.scheduledEndDate: LocalDate?
    get() {
        val plan = autoPlan

        if (!usesAutoCount || plan == null) {
            return form.endDate
        }

        return autoEndDate(plan)
    }

val RecurringEditModel.finalAmount: Int?
    get() {
        if (!isLoanRepayment) {
            return null
        }

        return if (usesAutoCount) autoPlan?.finalAmount else loan.manualFinal
    }

val RecurringEditModel.repaymentCount: Int?
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

val RecurringEditModel.plannedTotal: Long?
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

val RecurringEditModel.balanceGap: Long?
    get() {
        val owed = loanOwed ?: return null
        val total = plannedTotal ?: return null
        return if (total != owed.toLong()) total - owed else null
    }

internal fun RecurringEditModel.autoEndDate(plan: RepaymentPlan): LocalDate? = recurring(
    endDate = null,
    finalAmount = null,
).endDate(
    afterCount = plan.count,
    from = repaymentStart,
)

internal fun RecurringEditModel.manualFinalAmount(through: LocalDate?): Int? {
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
