package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier

data class RecurringRow(
    val id: Identifier<Recurring>,
    val title: String,
    val schedule: String,
    val place: String?,
    val amount: Int?,
    val type: Entry.Kind,
    val icon: Icon?,
    val next: LocalDate?,
    val closing: String?,
)
