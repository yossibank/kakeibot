package com.yossibank.kakeibot.core.concepts.review

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import kotlinx.serialization.Serializable

@ConsistentCopyVisibility
data class ReviewPeriod private constructor(
    val scale: Scale,
    val monthStartDay: MonthStartDay,
    val weekStart: Weekday,
    val range: ClosedRange<LocalDate>,
) {
    @Serializable
    enum class Scale(
        val rawValue: String,
    ) {
        week("week"),
        month("month"),
        year("year"),
        ;

        companion object {
            fun of(rawValue: String): Scale? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    val previous: ReviewPeriod
        get() = adding(-1)

    fun comparisonRange(today: LocalDate): ClosedRange<LocalDate> {
        val full = previous.range

        if (today !in range) {
            return full
        }

        val elapsed = range.start.days(until = today)
        val shifted = full.start.adding(days = elapsed)
        val end = minOf(shifted, full.endInclusive)

        return full.start..end
    }

    fun adding(count: Int): ReviewPeriod {
        val date = when (scale) {
            Scale.week -> {
                val days = 7 * count

                range.start.adding(days = days)
            }

            Scale.month -> {
                val month = range.endInclusive.yearMonth.adding(months = count)

                month.period(startingOn = monthStartDay).start
            }

            Scale.year -> {
                val months = 12 * count
                val month = range.endInclusive.yearMonth.adding(months = months)

                month.period(startingOn = monthStartDay).start
            }
        }

        return ReviewPeriod(
            scale = scale,
            containing = date,
            monthStartDay = monthStartDay,
            weekStart = weekStart,
        )
    }

    companion object {
        operator fun invoke(
            scale: Scale,
            containing: LocalDate,
            monthStartDay: MonthStartDay,
            weekStart: Weekday,
        ): ReviewPeriod {
            val range = when (scale) {
                Scale.week -> containing.week(startingOn = weekStart)

                Scale.month -> containing.period(startingOn = monthStartDay)

                Scale.year -> {
                    val month = containing.periodMonth(startingOn = monthStartDay)
                    val monthsToDecember = 12 - month.month
                    val december = month.adding(months = monthsToDecember)
                    val january = december.adding(months = -11)
                    val start = january.period(startingOn = monthStartDay).start
                    val end = december.period(startingOn = monthStartDay).endInclusive

                    start..end
                }
            }

            return ReviewPeriod(
                scale = scale,
                monthStartDay = monthStartDay,
                weekStart = weekStart,
                range = range,
            )
        }
    }
}
