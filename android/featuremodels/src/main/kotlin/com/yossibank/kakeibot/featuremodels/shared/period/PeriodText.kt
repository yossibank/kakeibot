package com.yossibank.kakeibot.featuremodels.shared.period

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.featuremodels.shared.datechoice.shortName

object PeriodText {
    fun range(period: ClosedRange<LocalDate>): String =
        "${period.start.monthDayText}〜${period.endInclusive.monthDayText}"

    fun range(
        period: ClosedRange<LocalDate>,
        today: LocalDate,
    ): String {
        val lower = day(
            date = period.start,
            today = today,
        )

        val upper = day(
            date = period.endInclusive,
            today = today,
        )

        return "$lower〜$upper"
    }

    fun day(
        date: LocalDate,
        today: LocalDate,
    ): String {
        if (date.year == today.year) {
            return date.monthDayText
        }

        return "${date.year}/${date.monthDayText}"
    }

    fun startDay(startDay: MonthStartDay): String {
        val day = if (startDay.isLastDay) "毎月末日" else "毎月 ${startDay.day} 日"
        return if (startDay.shift == HolidayShift.none) day else "$day・${startDay.shift.title}"
    }

    fun current(
        startingOn: MonthStartDay,
        today: LocalDate,
    ): String {
        val month = today.periodMonth(startingOn = startingOn)
        return range(month.period(startingOn = startingOn))
    }

    fun shiftNote(
        startingOn: MonthStartDay,
        today: LocalDate,
    ): String {
        if (startingOn.shift == HolidayShift.none) {
            return "土日・祝日でも、そのまま数えます"
        }

        val month = today.periodMonth(startingOn = startingOn)
        val start = month.period(startingOn = startingOn).start
        val plain = startingOn.shifted(by = HolidayShift.none)
        val unshifted = month.period(startingOn = plain).start

        if (start == unshifted) {
            return "今の期間の始まりは、平日です"
        }

        return "${weekdayDate(unshifted)}を ${weekdayDate(start)}にずらしています"
    }

    fun weekday(date: LocalDate): String = date.weekday.shortName

    fun weekdayDate(date: LocalDate): String = "${date.monthDayText}（${weekday(date)}）"
}

fun MonthStartDay.keepingShift(of: MonthStartDay): MonthStartDay = shifted(by = of.shift)

val HolidayShift.title: String
    get() = when (this) {
        HolidayShift.none -> "そのまま"
        HolidayShift.previous -> "前の平日"
        HolidayShift.next -> "次の平日"
    }
