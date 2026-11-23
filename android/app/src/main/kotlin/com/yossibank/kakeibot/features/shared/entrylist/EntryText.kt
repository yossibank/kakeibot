package com.yossibank.kakeibot.features.shared.entrylist

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.features.shared.period.PeriodText

object EntryText {
    const val destinationTitle = "振替先"

    fun walletTitle(type: Entry.Kind): String = when (type) {
        Entry.Kind.expense -> "支払い元"
        Entry.Kind.income -> "入金先"
        Entry.Kind.transfer -> "振替元"
    }

    fun relativeDate(
        date: LocalDate,
        today: LocalDate,
    ): String = when (date.days(until = today)) {
        0 -> "今日（${PeriodText.weekday(date)}）"
        1 -> "昨日（${PeriodText.weekday(date)}）"
        else -> PeriodText.weekdayDate(date)
    }
}
