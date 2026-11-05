package com.yossibank.kakeibot.core.concepts.date

import kotlin.math.floor

object Holiday {
    val supportedYears = 2022..2099

    fun name(of: LocalDate): String? {
        if (of.year !in supportedYears) {
            return null
        }

        namedHoliday(of)?.let {
            return it
        }

        if (isSubstitute(of)) {
            return "振替休日"
        }

        return if (isBetweenHolidays(of)) "国民の休日" else null
    }

    fun contains(date: LocalDate): Boolean = name(date) != null

    fun isDayOff(date: LocalDate): Boolean {
        val isWeekend = date.weekday == Weekday.saturday || date.weekday == Weekday.sunday
        val isYearEnd = (date.month == 12 && date.day == 31) || (date.month == 1 && date.day <= 3)

        return isWeekend || isYearEnd || contains(date)
    }

    private fun namedHoliday(date: LocalDate): String? {
        val month = date.month
        val day = date.day

        return when {
            month == 1 && day == 1 -> "元日"
            month == 1 && isMonday(date, week = 2) -> "成人の日"
            month == 2 && day == 11 -> "建国記念の日"
            month == 2 && day == 23 -> "天皇誕生日"
            month == 3 && day == springEquinox(date.year) -> "春分の日"
            month == 4 && day == 29 -> "昭和の日"
            month == 5 && day == 3 -> "憲法記念日"
            month == 5 && day == 4 -> "みどりの日"
            month == 5 && day == 5 -> "こどもの日"
            month == 7 && isMonday(date, week = 3) -> "海の日"
            month == 8 && day == 11 -> "山の日"
            month == 9 && isMonday(date, week = 3) -> "敬老の日"
            month == 9 && day == autumnEquinox(date.year) -> "秋分の日"
            month == 10 && isMonday(date, week = 2) -> "スポーツの日"
            month == 11 && day == 3 -> "文化の日"
            month == 11 && day == 23 -> "勤労感謝の日"
            else -> null
        }
    }

    private fun isNamed(date: LocalDate): Boolean = namedHoliday(date) != null

    private fun isSubstitute(date: LocalDate): Boolean {
        if (date.weekday == Weekday.sunday || isNamed(date)) {
            return false
        }

        var previous = date.adding(days = -1)

        while (isNamed(previous)) {
            if (previous.weekday == Weekday.sunday) {
                return true
            }

            previous = previous.adding(days = -1)
        }

        return false
    }

    private fun isBetweenHolidays(date: LocalDate): Boolean {
        val previous = date.adding(days = -1)
        val next = date.adding(days = 1)

        return isNamed(previous) && isNamed(next)
    }

    private fun isMonday(
        date: LocalDate,
        week: Int,
    ): Boolean = date.weekday == Weekday.monday && (date.day - 1) / 7 == week - 1

    private fun springEquinox(year: Int): Int = equinox(
        base = 20.8431,
        year = year,
    )

    private fun autumnEquinox(year: Int): Int = equinox(
        base = 23.2488,
        year = year,
    )

    private fun equinox(
        base: Double,
        year: Int,
    ): Int {
        val years = year - 1980
        val day = floor(base + 0.242194 * years)

        return day.toInt() - years / 4
    }
}
