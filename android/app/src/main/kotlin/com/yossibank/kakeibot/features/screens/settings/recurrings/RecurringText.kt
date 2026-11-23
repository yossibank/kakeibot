package com.yossibank.kakeibot.features.screens.settings.recurrings

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring

object RecurringText {
    fun schedule(
        frequency: Recurring.Frequency,
        month: Int,
        day: Int,
    ): String {
        val dayText = if (day >= 31) "末日" else "$day 日"

        return when (frequency) {
            Recurring.Frequency.monthly -> "毎月 $dayText"
            Recurring.Frequency.yearly -> "毎年 $month 月 $dayText"
        }
    }

    fun holidayNote(shift: HolidayShift): String? = when (shift) {
        HolidayShift.none -> null
        HolidayShift.previous -> "休日は前の平日"
        HolidayShift.next -> "休日は次の平日"
    }

    fun closingDay(day: Int?): String {
        day ?: return "決まった額"
        return "利用分（${closingNote(day)}）"
    }

    fun closingNote(day: Int): String = if (day >= 31) "末日締め" else "$day 日締め"

    fun remind(days: Int?): String = when (days) {
        null -> "知らせない"
        0 -> "当日"
        1 -> "前日"
        else -> "$days 日前"
    }

    fun date(date: LocalDate): String = "${date.year}/${date.monthDayText}"

    fun detail(
        schedule: String,
        holiday: String?,
    ): String = listOfNotNull(schedule, holiday).joinToString("・")

    fun namePrompt(type: Entry.Kind): String = when (type) {
        Entry.Kind.expense -> "家賃・サブスクなど"
        Entry.Kind.income -> "給料・年金など"
        Entry.Kind.transfer -> "カードの引き落とし・積立など"
    }
}
