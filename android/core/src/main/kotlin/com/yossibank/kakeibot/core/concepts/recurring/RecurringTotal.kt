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
): Long = filter { it.type == of }.fold(0L) { sum, recurring ->
    val occurrences = recurring.occurrences(
        from = range.start,
        through = range.endInclusive,
    )

    sum + occurrences.sumOf { recurring.amount(of = it, entries = entries) }
}

fun Recurring.record(
    of: Recurring.Occurrence,
    entries: List<Entry>,
): Entry? = entries.firstOrNull { isRecorded(by = it, scheduled = of.scheduled) }

fun Recurring.amount(
    of: Recurring.Occurrence,
    entries: List<Entry>,
): Long = record(of = of, entries = entries)?.amount?.toLong()
    ?: amount(paidOn = of.date, entries = entries)
