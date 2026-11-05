package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import java.time.Instant

data class NoSpendDay(
    val date: LocalDate,
    val createdAt: Instant,
) {
    val id: LocalDate
        get() = date
}
