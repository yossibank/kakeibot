package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring

data class PeriodRecurring(
    val date: LocalDate,
    val recurring: Recurring,
    val entry: Entry?,
    val status: Status,
    val amount: Long,
) {
    enum class Status {
        done,
        upcoming,
        missing,
    }
}
