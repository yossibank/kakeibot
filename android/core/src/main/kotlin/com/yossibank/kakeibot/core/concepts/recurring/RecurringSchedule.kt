package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry

private const val searchDays = 400

fun Recurring.occurrences(
    from: LocalDate,
    through: LocalDate,
): List<Recurring.Occurrence> {
    val lower = maxOf(from, startDate)
    val upper = endDate?.let { minOf(through, it) } ?: through

    if (lower > upper) {
        return emptyList()
    }

    val first = lower.yearMonth.adding(months = -1)
    val last = upper.yearMonth.adding(months = 1)

    return months(
        from = first,
        through = last,
    )
        .map { clampedDate(it) }
        .map {
            Recurring.Occurrence(
                scheduled = it,
                date = holidayShift.apply(to = it),
            )
        }
        .filter { lower <= it.date && it.date <= upper }
}

fun Recurring.dates(
    from: LocalDate,
    through: LocalDate,
): List<LocalDate> = occurrences(
    from = from,
    through = through,
).map { it.date }

fun Recurring.pendingOccurrences(through: LocalDate): List<Recurring.Occurrence> {
    val start = generatedUntil?.adding(days = 1) ?: startDate

    return occurrences(
        from = start,
        through = through,
    )
}

fun Recurring.nextDate(onOrAfter: LocalDate): LocalDate? {
    val horizon = onOrAfter.adding(days = searchDays)

    return dates(
        from = onOrAfter,
        through = horizon,
    ).firstOrNull()
}

fun Recurring.isRecorded(
    by: Entry,
    scheduled: LocalDate,
): Boolean {
    val recorded = by.recurringDate

    if (by.recurringId != id || recorded == null) {
        return false
    }

    return recorded.yearMonth == scheduled.yearMonth
}

fun Recurring.occurrence(on: LocalDate): Recurring.Occurrence = Recurring.Occurrence(
    scheduled = scheduledDate(of = on),
    date = on,
)

fun Recurring.scheduledDate(of: LocalDate): LocalDate = scheduledDateShifted(to = of) ?: of

fun Recurring.scheduledDateShifted(to: LocalDate): LocalDate? =
    scheduledDates(shiftedInto = to.yearMonth).firstOrNull { holidayShift.apply(to = it) == to }

fun Recurring.scheduledDates(shiftedInto: YearMonth): List<LocalDate> {
    val previous = shiftedInto.adding(months = -1)
    val next = shiftedInto.adding(months = 1)

    return months(
        from = previous,
        through = next,
    )
        .map { clampedDate(it) }
        .filter { holidayShift.apply(to = it).yearMonth == shiftedInto }
}

fun Recurring.occurrenceMonth(of: LocalDate): YearMonth = scheduledDate(of = of).yearMonth

private fun Recurring.clampedDate(month: YearMonth): LocalDate = LocalDate.ofClamped(
    yearMonth = month,
    clampedDay = day,
)

private fun Recurring.months(
    from: YearMonth,
    through: YearMonth,
): List<YearMonth> {
    val months = (from.monthIndex..through.monthIndex).map { YearMonth.ofMonthIndex(it) }

    return when (frequency) {
        Recurring.Frequency.monthly -> months

        Recurring.Frequency.yearly -> {
            val month = month ?: 1

            months.filter { it.month == month }
        }
    }
}
