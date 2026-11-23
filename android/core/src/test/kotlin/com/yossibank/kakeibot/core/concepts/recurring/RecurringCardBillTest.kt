package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.recurring.RecurringCardBillFixture.bill
import com.yossibank.kakeibot.core.concepts.recurring.RecurringCardBillFixture.date
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class RecurringCardBillTest {
    @RunWith(Parameterized::class)
    class FindsBillingPeriod(
        private val fixture: PeriodCase,
    ) {
        @Serializable
        data class PeriodCase(
            val summary: String,
            val closingDay: Int,
            val day: Int? = null,
            val holidayShift: HolidayShift? = null,
            val paidOn: LocalDate,
            val from: LocalDate,
            val through: LocalDate,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsBillingPeriod() {
            val bill = bill(
                closingDay = fixture.closingDay,
                day = fixture.day ?: 10,
                holidayShift = fixture.holidayShift ?: HolidayShift.none,
            )

            val period = bill.billingPeriod(paidOn = fixture.paidOn)

            assertEquals(fixture.from..fixture.through, period)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<PeriodCase> =
                CoreFixture.cases("recurring/card-bill-period.json", PeriodCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class ContinuesPeriodsAcrossShortMonths(
        private val start: String,
    ) {
        @Test
        fun continuesPeriodsAcrossShortMonths() {
            val first = assertNotNull(YearMonth.parse(start))

            for (closingDay in 28..31) {
                for (day in 28..31) {
                    val bill = bill(
                        closingDay = closingDay,
                        day = day,
                    )

                    val periods = (0 until 14).map { offset ->
                        val month = first.adding(months = offset)

                        val paidOn = (day downTo 1).firstNotNullOf {
                            LocalDate.of(
                                yearMonth = month,
                                day = it,
                            )
                        }

                        assertNotNull(bill.billingPeriod(paidOn))
                    }

                    assertEquals(14, periods.size)

                    for ((previous, next) in periods.zipWithNext()) {
                        val message = "closing $closingDay day $day at ${next.start}"

                        assertEquals(next.start, previous.endInclusive.adding(days = 1), message)
                    }
                }
            }
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<String> = listOf(
                "2027-01",
                "2027-12",
            )
        }
    }

    @RunWith(Parameterized::class)
    class FindsBillMonthOfShiftedBill(
        private val shift: Int,
    ) {
        @Test
        fun findsBillMonthOfShiftedBill() {
            val bill = bill(closingDay = 31)
            val used = date("2026-08-31")

            val dates = bill.billDates(
                used = used,
                count = 3,
            )

            val month = bill.billMonth(
                used = used,
                shift = shift,
            )

            assertEquals(bill.occurrenceMonth(of = dates[shift]), month)
            assertNotNull(month)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<Int> = listOf(1, 2)
        }
    }

    @RunWith(Parameterized::class)
    class SkipsBillMonthOutsideShiftRange(
        private val shift: Int,
    ) {
        @Test
        fun skipsBillMonthOutsideShiftRange() {
            val bill = bill(closingDay = 31)

            val month = bill.billMonth(
                used = date("2026-08-31"),
                shift = shift,
            )

            assertNull(month)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<Int> = listOf(0, 3, -1)
        }
    }

    @RunWith(Parameterized::class)
    class ClampsBillShift(
        private val shift: Int,
        private val expected: Int,
    ) {
        @Test
        fun clampsBillShift() {
            assertEquals(expected, Recurring.clampedBillShift(shift))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0} -> {1}")
            fun cases(): List<Array<Int>> = listOf(
                arrayOf(-1, 0),
                arrayOf(0, 0),
                arrayOf(1, 1),
                arrayOf(2, 2),
                arrayOf(5, 2),
            )
        }
    }
}
