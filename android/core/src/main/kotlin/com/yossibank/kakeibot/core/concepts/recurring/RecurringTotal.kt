package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry

fun List<Recurring>.total(
    of: Entry.Kind,
    range: ClosedRange<LocalDate>,
): Int = filter { it.type == of }.fold(0) { sum, recurring ->
    val dates = recurring.dates(
        from = range.start,
        through = range.endInclusive,
    )

    sum + recurring.amount * dates.size
}
