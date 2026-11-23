package com.yossibank.kakeibot.features.shared.period

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.designsystem.components.date.shortName

object PeriodText {
    fun range(period: ClosedRange<LocalDate>): String =
        "${period.start.monthDayText}〜${period.endInclusive.monthDayText}"

    fun startDay(startDay: MonthStartDay): String {
        val day = if (startDay.isLastDay) "毎月末日" else "毎月 ${startDay.day} 日"
        return if (startDay.shift == HolidayShift.none) day else "$day・${startDay.shift.title}"
    }

    fun weekday(date: LocalDate): String = date.weekday.shortName

    fun weekdayDate(date: LocalDate): String = "${date.monthDayText}（${weekday(date)}）"
}

val HolidayShift.title: String
    get() = when (this) {
        HolidayShift.none -> "そのまま"
        HolidayShift.previous -> "前の平日"
        HolidayShift.next -> "次の平日"
    }
