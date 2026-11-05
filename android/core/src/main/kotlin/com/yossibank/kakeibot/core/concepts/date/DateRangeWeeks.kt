package com.yossibank.kakeibot.core.concepts.date

fun ClosedRange<LocalDate>.weeks(startingOn: Weekday): List<List<LocalDate?>> {
    val firstOffset = start.weekday.daysSinceMonday
    val difference = firstOffset - startingOn.daysSinceMonday
    val leading = (difference + 7) % 7
    val count = endInclusive.dayNumber - start.dayNumber + 1
    val days = (0 until count).map { start.adding(days = it) }
    val filled = List<LocalDate?>(leading) { null } + days
    val trailing = (7 - filled.size % 7) % 7
    val cells = filled + List<LocalDate?>(trailing) { null }

    return cells.chunked(7)
}
