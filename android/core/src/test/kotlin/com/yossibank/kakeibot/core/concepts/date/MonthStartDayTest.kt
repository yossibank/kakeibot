package com.yossibank.kakeibot.core.concepts.date

import kotlinx.serialization.builtins.serializer
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class MonthStartDayTest {
    @RunWith(Parameterized::class)
    class Valid(
        private val day: Int,
    ) {
        @Test
        fun acceptsDayInRange() {
            val startDay = assertNotNull(MonthStartDay.of(day))

            assertEquals(day, startDay.day)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<Int> = validity.valid
        }
    }

    @RunWith(Parameterized::class)
    class Invalid(
        private val day: Int,
    ) {
        @Test
        fun rejectsDayOutOfRange() {
            assertNull(MonthStartDay.of(day))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<Int> = validity.invalid
        }
    }

    companion object {
        private val validity: ValidityFixture<Int>
            get() = ValidityFixture.load("date/month-start-day.json", Int.serializer())
    }
}
