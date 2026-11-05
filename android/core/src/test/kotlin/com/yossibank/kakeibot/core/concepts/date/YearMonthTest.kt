package com.yossibank.kakeibot.core.concepts.date

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.serializer
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class YearMonthTest {
    @RunWith(Parameterized::class)
    class ValidText(
        private val text: String,
    ) {
        @Test
        fun parsesValidText() {
            val month = assertNotNull(YearMonth.parse(text))

            assertEquals(text, month.toString())
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<String> = validity.valid
        }
    }

    @RunWith(Parameterized::class)
    class InvalidText(
        private val text: String,
    ) {
        @Test
        fun rejectsInvalidText() {
            assertNull(YearMonth.parse(text))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<String> = validity.invalid
        }
    }

    class Single {
        @Test
        fun movesBeforeYearOne() {
            val month = assertNotNull(
                YearMonth.of(
                    year = 1,
                    month = 1,
                ),
            )

            val previousDecember = YearMonth.of(
                year = -1,
                month = 12,
            )

            val earlier = month.adding(months = -13)

            assertEquals(previousDecember, earlier)
            assertEquals("-0001-12", earlier.toString())
            assertNull(YearMonth.parse(earlier.toString()))
        }
    }

    @RunWith(Parameterized::class)
    class Period(
        private val fixture: PeriodCase,
    ) {
        @Test
        fun findsPeriod() {
            val startDay = fixture.monthStartDay.shifted(by = fixture.monthStartShift ?: HolidayShift.none)
            val period = fixture.month.period(startingOn = startDay)

            assertEquals(fixture.start..fixture.end, period)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<PeriodCase> = CoreFixture.cases("date/year-month-period.json", PeriodCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class Weeks(
        private val fixture: WeeksCase,
    ) {
        @Test
        fun laysOutWeeks() {
            val weeks = fixture.month.weeks(startingOn = fixture.weekStart)
            val cells = weeks.flatten()
            val days = cells.filterNotNull()

            assertEquals(fixture.rows, weeks.size)
            assertTrue(weeks.all { it.size == 7 })
            assertTrue(cells.take(fixture.leading).all { it == null })
            assertTrue(cells.takeLast(fixture.trailing).all { it == null })
            assertEquals(fixture.leading + days.size + fixture.trailing, cells.size)
            assertEquals((1..fixture.month.numberOfDays).toList(), days.map { it.day })
            assertTrue(days.all { it.yearMonth == fixture.month })
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<WeeksCase> = CoreFixture.cases("date/year-month-weeks.json", WeeksCase.serializer())
        }
    }

    @Serializable
    data class WeeksCase(
        val summary: String,
        val weekStart: Weekday,
        val month: YearMonth,
        val leading: Int,
        val trailing: Int,
        val rows: Int,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class PeriodCase(
        val summary: String,
        val monthStartDay: MonthStartDay,
        val monthStartShift: HolidayShift? = null,
        val month: YearMonth,
        val start: LocalDate,
        val end: LocalDate,
    ) {
        override fun toString(): String = summary
    }

    companion object {
        private val validity: CoreFixture.Validity<String>
            get() = CoreFixture.validity("date/year-month-text.json", String.serializer())
    }
}
