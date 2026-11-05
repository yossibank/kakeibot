package com.yossibank.kakeibot.core.concepts.date

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull

class HolidayTest {
    @RunWith(Parameterized::class)
    class Year(
        private val fixture: YearCase,
    ) {
        @Test
        fun namesHolidaysOfYear() {
            val first = assertNotNull(
                LocalDate.of(
                    year = fixture.year,
                    month = 1,
                    day = 1,
                ),
            )

            val days = (0 until 365).map { first.adding(days = it) }

            val holidays = days.mapNotNull { date ->
                Holiday.name(date)?.let {
                    NamedDate(
                        date = date,
                        name = it,
                    )
                }
            }

            assertEquals(fixture.holidays, holidays)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<YearCase> = CoreFixture.cases("date/holiday-dates.json", YearCase.serializer())
        }
    }

    class Single {
        @Test
        fun skipsUnsupportedYears() {
            val date = assertNotNull(LocalDate.parse("2021-01-01"))

            assertFalse(Holiday.contains(date))
        }
    }

    @Serializable
    data class YearCase(
        val summary: String,
        val year: Int,
        val holidays: List<NamedDate>,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class NamedDate(
        val date: LocalDate,
        val name: String,
    )
}
