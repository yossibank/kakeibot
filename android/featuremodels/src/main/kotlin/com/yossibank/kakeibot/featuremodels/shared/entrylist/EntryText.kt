package com.yossibank.kakeibot.featuremodels.shared.entrylist

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText

object EntryText {
    const val destinationTitle = "振替先"

    fun walletTitle(type: Entry.Kind): String = when (type) {
        Entry.Kind.expense -> "支払い元"
        Entry.Kind.income -> "入金先"
        Entry.Kind.transfer -> "振替元"
    }

    fun dateText(
        date: LocalDate,
        today: LocalDate,
    ): String {
        val day = PeriodText.day(
            date = date,
            today = today,
        )

        val text = "$day（${PeriodText.weekday(date)}）"

        return when (date) {
            today -> "今日 $text"
            today.adding(days = -1) -> "昨日 $text"
            else -> text
        }
    }

    fun shortDateText(
        date: LocalDate,
        today: LocalDate,
    ): String = when (date) {
        today -> {
            "今日"
        }

        today.adding(days = -1) -> {
            "昨日"
        }

        else -> {
            PeriodText.day(
                date = date,
                today = today,
            )
        }
    }

    fun dateValue(
        date: LocalDate,
        today: LocalDate,
    ): String {
        val day = shortDateText(
            date = date,
            today = today,
        )

        return "$day（${PeriodText.weekday(date)}）"
    }
}
