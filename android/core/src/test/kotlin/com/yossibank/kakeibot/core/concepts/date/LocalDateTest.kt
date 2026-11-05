package com.yossibank.kakeibot.core.concepts.date

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import java.time.ZoneId
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class LocalDateTest {
    @RunWith(Parameterized::class)
    class ValidText(
        private val text: String,
    ) {
        @Test
        fun parsesValidText() {
            val date = assertNotNull(LocalDate.parse(text))

            assertEquals(text, date.toString())
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
            assertNull(LocalDate.parse(text))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<String> = validity.invalid
        }
    }

    @RunWith(Parameterized::class)
    class InstantConversion(
        private val fixture: InstantCase,
    ) {
        @Test
        fun convertsInstantInTimeZone() {
            val timeZone = ZoneId.of(fixture.timeZone)

            val date = LocalDate.of(
                instant = Instant.parse(fixture.instant),
                timeZone = timeZone,
            )

            assertEquals(fixture.date, date)
        }

        @Test
        fun findsStartOfDayInTimeZone() {
            val timeZone = ZoneId.of(fixture.timeZone)

            val start = fixture.date.startOfDay(timeZone)
            val justBefore = start.minusSeconds(1)
            val previousDay = fixture.date.adding(days = -1)

            val startDate = LocalDate.of(
                instant = start,
                timeZone = timeZone,
            )

            val justBeforeDate = LocalDate.of(
                instant = justBefore,
                timeZone = timeZone,
            )

            assertEquals(fixture.date, startDate)
            assertEquals(previousDay, justBeforeDate)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<InstantCase> = CoreFixture.cases("date/local-date-instant.json", InstantCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class Week(
        private val fixture: WeekCase,
    ) {
        @Test
        fun findsWeek() {
            val week = fixture.date.week(startingOn = fixture.weekStart)

            assertEquals(fixture.start..fixture.end, week)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<WeekCase> = CoreFixture.cases("date/local-date-week.json", WeekCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class PeriodMonth(
        private val fixture: PeriodCase,
    ) {
        @Test
        fun findsPeriodMonth() {
            val startDay = fixture.monthStartDay.shifted(by = fixture.monthStartShift ?: HolidayShift.none)
            val dayBefore = fixture.start.adding(days = -1)
            val dayAfter = fixture.end.adding(days = 1)

            assertEquals(fixture.month, fixture.start.periodMonth(startingOn = startDay))
            assertEquals(fixture.month, fixture.end.periodMonth(startingOn = startDay))
            assertEquals(fixture.month.adding(months = -1), dayBefore.periodMonth(startingOn = startDay))
            assertEquals(fixture.month.adding(months = 1), dayAfter.periodMonth(startingOn = startDay))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<PeriodCase> = CoreFixture.cases("date/year-month-period.json", PeriodCase.serializer())
        }
    }

    class Single {
        @Test
        fun movesBeforeYearOne() {
            val date = assertNotNull(LocalDate.parse("0001-01-01"))

            val dayBefore = LocalDate.of(
                year = 0,
                month = 12,
                day = 31,
            )

            val earlier = date.adding(days = -1)

            assertEquals(dayBefore, earlier)
            assertEquals(date, earlier.adding(days = 1))
        }

        @Test
        fun encodesAsText() {
            val date = assertNotNull(LocalDate.parse("2026-02-01"))
            val serializer = ListSerializer(LocalDate.serializer())

            val text = Json.encodeToString(serializer, listOf(date))
            val decoded = Json.decodeFromString(serializer, text)

            assertEquals("""["2026-02-01"]""", text)
            assertEquals(listOf(date), decoded)
        }
    }

    @Serializable
    data class InstantCase(
        val summary: String,
        val instant: String,
        val timeZone: String,
        val date: LocalDate,
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

    @Serializable
    data class WeekCase(
        val summary: String,
        val weekStart: Weekday,
        val date: LocalDate,
        val start: LocalDate,
        val end: LocalDate,
    ) {
        override fun toString(): String = summary
    }

    companion object {
        private val validity: ValidityFixture<String>
            get() = ValidityFixture.load("date/local-date-text.json", String.serializer())
    }
}
