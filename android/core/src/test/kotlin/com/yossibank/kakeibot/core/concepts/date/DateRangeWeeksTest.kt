package com.yossibank.kakeibot.core.concepts.date

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@RunWith(Parameterized::class)
class DateRangeWeeksTest(
    private val fixture: WeeksCase,
) {
    @Test
    fun laysOutWeeks() {
        val range = fixture.start..fixture.end
        val weeks = range.weeks(fixture.weekStart)
        val cells = weeks.flatten()
        val days = cells.filterNotNull()
        val pairs = days.zipWithNext()

        assertEquals(fixture.rows, weeks.size)
        assertTrue(weeks.all { it.size == 7 })
        assertTrue(cells.take(fixture.leading).all { it == null })
        assertTrue(cells.takeLast(fixture.trailing).all { it == null })
        assertEquals(fixture.leading + days.size + fixture.trailing, cells.size)
        assertEquals(fixture.start, days.first())
        assertEquals(fixture.end, days.last())
        assertTrue(pairs.all { (lhs, rhs) -> lhs.adding(days = 1) == rhs })
    }

    @Serializable
    data class WeeksCase(
        val summary: String,
        val weekStart: Weekday,
        val start: LocalDate,
        val end: LocalDate,
        val leading: Int,
        val trailing: Int,
        val rows: Int,
    ) {
        override fun toString(): String = summary
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<WeeksCase> = CoreFixture.cases("date/date-range-weeks.json", WeeksCase.serializer())
    }
}
