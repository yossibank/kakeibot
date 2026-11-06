package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.budget.amount
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.entry.expenseTotal
import com.yossibank.kakeibot.core.concepts.entry.incomeTotal
import com.yossibank.kakeibot.core.concepts.entry.within
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.amount
import com.yossibank.kakeibot.core.concepts.recurring.occurrences
import com.yossibank.kakeibot.core.concepts.recurring.record
import com.yossibank.kakeibot.core.concepts.recurring.scheduledAmount

data class MonthOverview(
    val list: EntryList?,
    val budgets: List<Budget>,
    val recurrings: List<Recurring>,
    val monthStartDay: MonthStartDay,
    val carryoverFrom: YearMonth? = null,
    val today: LocalDate,
) {
    val month: YearMonth = today.periodMonth(startingOn = monthStartDay)

    val period: ClosedRange<LocalDate> = month.period(startingOn = monthStartDay)

    val periodRecurrings: List<PeriodRecurring> = periodRecurrings(
        of = recurrings,
        period = period,
        entries = list?.entries,
        today = today,
    )

    val monthDays: List<EntryDay> = list?.days?.within(period).orEmpty()

    val monthExpense: Long = monthDays.expenseTotal

    val monthIncome: Long = monthDays.incomeTotal

    val budgetCarryover: Long = list?.budgetCarryover(
        budgets = budgets,
        from = carryoverFrom,
        into = month,
        startingOn = monthStartDay,
    ) ?: 0L

    val todayExpense: Long
        get() = expense(on = today)

    val yesterdayExpense: Long
        get() = expense(on = today.adding(days = -1))

    val recurringExpense: Long
        get() = recurringTotal(Entry.Kind.expense)

    val recurringIncome: Long
        get() = recurringTotal(Entry.Kind.income)

    val paidRecurringExpense: Long
        get() = recurringTotal(Entry.Kind.expense) { it == PeriodRecurring.Status.done }

    val upcomingRecurringExpense: Long
        get() = recurringTotal(Entry.Kind.expense) { it == PeriodRecurring.Status.upcoming }

    val paidRecurringRatio: Double
        get() {
            if (recurringExpense <= 0) {
                return 0.0
            }

            val ratio = paidRecurringExpense.toDouble() / recurringExpense.toDouble()

            return minOf(ratio, 1.0)
        }

    val budgetUsage: BudgetUsage?
        get() {
            val budget = budgets.amount(
                categoryId = null,
                month = month,
            ) ?: return null

            return BudgetUsage(
                budget = budget,
                carryover = budgetCarryover,
                spent = monthExpense,
                today = today,
                periodEnd = period.endInclusive,
            )
        }

    val nextRecurringExpense: PeriodRecurring?
        get() = periodRecurrings.firstOrNull { item ->
            item.recurring.type == Entry.Kind.expense && item.status == PeriodRecurring.Status.upcoming
        }

    fun expense(range: ClosedRange<LocalDate>): Long = list?.days?.within(range)?.expenseTotal ?: 0L

    fun moved(to: LocalDate): MonthOverview = copy(today = to)

    private fun expense(on: LocalDate): Long = list?.days?.firstOrNull { it.date == on }?.expenseTotal ?: 0L

    private fun recurringTotal(
        type: Entry.Kind,
        isIncluded: (PeriodRecurring.Status) -> Boolean = { true },
    ): Long = periodRecurrings
        .filter { it.recurring.type == type && isIncluded(it.status) }
        .sumOf { it.amount }

    private companion object {
        fun periodRecurrings(
            of: List<Recurring>,
            period: ClosedRange<LocalDate>,
            entries: List<Entry>?,
            today: LocalDate,
        ): List<PeriodRecurring> {
            val recorded = entries?.filter { it.recurringId != null }.orEmpty()

            return of
                .flatMap { recurring ->
                    recurring
                        .occurrences(
                            from = period.start,
                            through = period.endInclusive,
                        )
                        .mapNotNull { occurrence ->
                            val date = occurrence.date

                            val entry = recurring.record(
                                of = occurrence,
                                entries = recorded,
                            )

                            val amount = entry?.amount?.toLong()
                                ?: entries?.let {
                                    recurring.amount(
                                        paidOn = date,
                                        entries = it,
                                    )
                                }
                                ?: recurring.scheduledAmount(paidOn = date).toLong()

                            if (entry == null && amount <= 0) {
                                return@mapNotNull null
                            }

                            val state = status(
                                of = date,
                                entry = entry,
                                recurring = recurring,
                                today = today,
                            )

                            PeriodRecurring(
                                date = date,
                                recurring = recurring,
                                entry = entry,
                                status = state,
                                amount = amount,
                            )
                        }
                }
                .sortedBy { it.date }
        }

        fun status(
            of: LocalDate,
            entry: Entry?,
            recurring: Recurring,
            today: LocalDate,
        ): PeriodRecurring.Status {
            if (entry != null) {
                return PeriodRecurring.Status.done
            }

            if (of > today) {
                return PeriodRecurring.Status.upcoming
            }

            val isGenerated = recurring.generatedUntil?.let { of <= it } ?: false

            return if (of == today && !isGenerated) {
                PeriodRecurring.Status.upcoming
            } else {
                PeriodRecurring.Status.missing
            }
        }
    }
}
