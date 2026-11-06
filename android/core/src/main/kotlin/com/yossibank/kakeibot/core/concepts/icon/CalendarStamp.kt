package com.yossibank.kakeibot.core.concepts.icon

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class CalendarStamp(
    val id: Identifier<CalendarStamp> = Identifier(),
    val date: LocalDate,
    val iconId: Identifier<Icon>,
    val createdAt: Instant,
)
