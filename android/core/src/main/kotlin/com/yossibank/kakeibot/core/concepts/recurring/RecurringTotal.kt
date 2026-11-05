package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry

fun List<Recurring>.total(
    of: Entry.Kind,
    range: ClosedRange<LocalDate>,
): Long = filter { it.type == of }.fold(0L) { sum, recurring ->
    val dates = recurring.dates(
        from = range.start,
        through = range.endInclusive,
    )

    sum + dates.sumOf { recurring.scheduledAmount(paidOn = it).toLong() }
}
