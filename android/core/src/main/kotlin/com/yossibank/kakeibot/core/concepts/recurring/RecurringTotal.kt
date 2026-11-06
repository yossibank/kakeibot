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

fun List<Recurring>.total(
    of: Entry.Kind,
    range: ClosedRange<LocalDate>,
    entries: List<Entry>,
): Long {
    val recorded = entries.filter { it.recurringId != null }

    return filter { it.type == of }.fold(0L) { sum, recurring ->
        val occurrences = recurring.occurrences(
            from = range.start,
            through = range.endInclusive,
        )

        sum + occurrences.sumOf { occurrence ->
            recurring.record(of = occurrence, entries = recorded)?.amount?.toLong()
                ?: recurring.amount(paidOn = occurrence.date, entries = entries)
        }
    }
}

fun Recurring.record(
    of: Recurring.Occurrence,
    entries: List<Entry>,
): Entry? = entries.firstOrNull { isRecorded(by = it, scheduled = of.scheduled) }
