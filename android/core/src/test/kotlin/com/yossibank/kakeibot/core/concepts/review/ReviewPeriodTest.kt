package com.yossibank.kakeibot.core.concepts.review

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class ReviewPeriodTest(
    private val fixture: PeriodCase,
) {
    @Serializable
    data class PeriodCase(
        val summary: String,
        val scale: ReviewPeriod.Scale,
        val date: LocalDate,
        val monthStartDay: MonthStartDay,
        val weekStart: Weekday,
        val start: LocalDate,
        val end: LocalDate,
        val previousStart: LocalDate,
        val previousEnd: LocalDate,
        val today: LocalDate? = null,
        val comparisonStart: LocalDate,
        val comparisonEnd: LocalDate,
    ) {
        override fun toString(): String = summary
    }

    @Test
    fun findsPeriodAndPrevious() {
        val period = period()
        val previous = period.previous

        assertEquals(fixture.start..fixture.end, period.range)
        assertEquals(fixture.previousStart..fixture.previousEnd, previous.range)
        assertEquals(period, previous.adding(1))
    }

    @Test
    fun cutsPreviousToSameElapsedDays() {
        val period = period()
        val today = fixture.today ?: fixture.date
        val range = period.comparisonRange(today = today)

        assertEquals(fixture.comparisonStart..fixture.comparisonEnd, range)
    }

    @Test
    fun movesSeveralPeriods() {
        val period = period()
        val back = period.adding(-3)
        val stepped = period.previous.previous.previous

        assertEquals(stepped, back)
        assertEquals(period, back.adding(3))
    }

    private fun period(): ReviewPeriod = ReviewPeriod(
        scale = fixture.scale,
        containing = fixture.date,
        monthStartDay = fixture.monthStartDay,
        weekStart = fixture.weekStart,
    )

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<PeriodCase> = CoreFixture.cases("review/review-period.json", PeriodCase.serializer())
    }
}
