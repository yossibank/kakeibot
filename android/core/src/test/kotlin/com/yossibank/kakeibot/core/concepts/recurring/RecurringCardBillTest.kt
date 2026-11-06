package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
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
            fun cases(): List<PeriodCase> = CoreFixture.cases("recurring/card-bill-period.json", PeriodCase.serializer())
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

    class Bills {
        @Test
        fun sumsCardUsageOfPeriod() {
            val bill = bill(closingDay = 15)
            val card = assertNotNull(bill.toWalletId)

            val entries = listOf(
                entry(Entry.Kind.expense, 30000, "2026-09-16", card),
                entry(Entry.Kind.expense, 12000, "2026-10-15", card),
                entry(Entry.Kind.income, 2000, "2026-10-01", card),
                entry(Entry.Kind.transfer, 45000, "2026-10-10", card),
                entry(Entry.Kind.expense, 9000, "2026-10-16", card),
                entry(Entry.Kind.expense, 5000, "2026-10-01", Identifier()),
            )

            val amount = bill.amount(
                paidOn = date("2026-11-10"),
                entries = entries,
            )

            assertEquals(85000, amount)
        }

        @Test
        fun sumsCardUsageWithoutWrappingAround() {
            val limit = 999_999_999
            val bill = bill(closingDay = 15)
            val card = assertNotNull(bill.toWalletId)

            val entries = List(3) {
                entry(Entry.Kind.expense, limit, "2026-10-01", card)
            }

            val amount = bill.amount(
                paidOn = date("2026-11-10"),
                entries = entries,
            )

            assertEquals(3L * limit, amount)
        }

        @Test
        fun skipsPaymentIntoCard() {
            val bill = bill(closingDay = 15)
            val card = assertNotNull(bill.toWalletId)
            val payment = entry(Entry.Kind.transfer, 45000, "2026-10-10", bill.walletId).copy(toWalletId = card)

            val entries = listOf(
                payment,
                entry(Entry.Kind.expense, 12000, "2026-10-15", card),
            )

            val amount = bill.amount(
                paidOn = date("2026-11-10"),
                entries = entries,
            )

            assertEquals(12000, amount)
        }

        @Test
        fun countsMovedUsageInChosenMonth() {
            val bill = bill(closingDay = 31)
            val card = assertNotNull(bill.toWalletId)
            val october = date("2026-10-10")
            val november = date("2026-11-10")
            val late = entry(Entry.Kind.expense, 3000, "2026-08-31", card).copy(billMonth = november.yearMonth)
            val moved = entry(Entry.Kind.expense, 500, "2026-09-20", card).copy(billMonth = november.yearMonth)

            val entries = listOf(
                late,
                moved,
                entry(Entry.Kind.expense, 9000, "2026-09-05", card),
                entry(Entry.Kind.expense, 7000, "2026-10-05", card),
            )

            val octoberAmount = bill.amount(
                paidOn = october,
                entries = entries,
            )

            val novemberAmount = bill.amount(
                paidOn = november,
                entries = entries,
            )

            assertEquals(9000, octoberAmount)
            assertEquals(10500, novemberAmount)
        }

        @Test
        fun countsMovedUsageOncePerOccurrence() {
            val bill = bill(
                closingDay = 31,
                day = 27,
                holidayShift = HolidayShift.next,
            )

            val card = assertNotNull(bill.toWalletId)
            val february = date("2027-03-01")
            val march = date("2027-03-29")
            val moved = entry(Entry.Kind.expense, 500, "2027-01-20", card).copy(billMonth = YearMonth.parse("2027-02"))

            val entries = listOf(
                moved,
                entry(Entry.Kind.expense, 9000, "2027-01-05", card),
                entry(Entry.Kind.expense, 7000, "2027-02-05", card),
            )

            val februaryAmount = bill.amount(
                paidOn = february,
                entries = entries,
            )

            val marchAmount = bill.amount(
                paidOn = march,
                entries = entries,
            )

            assertEquals(9500, februaryAmount)
            assertEquals(7000, marchAmount)
        }

        @Test
        fun listsBillDatesFromUsualOne() {
            val bill = bill(closingDay = 31)

            val dates = bill.billDates(
                used = date("2026-08-31"),
                count = 3,
            )

            assertEquals(listOf("2026-09-10", "2026-10-10", "2026-11-10"), dates.map { it.toString() })
        }

        @Test
        fun skipsBillMonthWithoutClosingDay() {
            val bill = bill(closingDay = 31).copy(closingDay = null)

            val month = bill.billMonth(
                used = date("2026-08-31"),
                shift = 1,
            )

            assertNull(month)
        }

        @Test
        fun findsCardBillOfWallet() {
            val bill = bill(closingDay = 15)
            val card = assertNotNull(bill.toWalletId)
            val noClosing = bill(closingDay = 15).copy(closingDay = null)
            val expense = bill(closingDay = 15).copy(type = Entry.Kind.expense)

            val found = listOf(noClosing, expense, bill).cardBill(paidBy = card)

            assertEquals(bill.id, found?.id)
        }

        @Test
        fun skipsCardBillWithoutClosingDayOrExpense() {
            val noClosing = bill(closingDay = 15).copy(closingDay = null)
            val expense = bill(closingDay = 15).copy(type = Entry.Kind.expense)
            val other = bill(closingDay = 15)

            val none = listOf(noClosing, expense).cardBill(paidBy = noClosing.toWalletId)
            val noneForExpense = listOf(expense).cardBill(paidBy = expense.toWalletId)
            val otherCard = listOf(other).cardBill(paidBy = Identifier())

            assertNull(none)
            assertNull(noneForExpense)
            assertNull(otherCard)
        }

        @Test
        fun listsBillDatesBeforeStartFromUsualOne() {
            val bill = bill(closingDay = 31).copy(startDate = date("2026-09-20"))

            val dates = bill.billDates(
                used = date("2026-08-31"),
                count = 3,
            )

            assertEquals(listOf("2026-09-10", "2026-10-10", "2026-11-10"), dates.map { it.toString() })
        }

        @Test
        fun keepsFixedAmountWithoutClosingDay() {
            val bill = bill(closingDay = 15).copy(closingDay = null)

            val amount = bill.amount(
                paidOn = date("2026-11-10"),
                entries = emptyList(),
            )

            assertEquals(45000, amount)
        }
    }
}

private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))

private fun bill(
    closingDay: Int,
    day: Int = 10,
    holidayShift: HolidayShift = HolidayShift.none,
): Recurring {
    val now = Instant.ofEpochSecond(1_791_000_000)

    return Recurring(
        type = Entry.Kind.transfer,
        amount = 45000,
        categoryId = null,
        walletId = Identifier(),
        toWalletId = Identifier(),
        frequency = Recurring.Frequency.monthly,
        day = day,
        holidayShift = holidayShift,
        closingDay = closingDay,
        startDate = date("2026-01-01"),
        createdAt = now,
        updatedAt = now,
    )
}

private fun entry(
    type: Entry.Kind,
    amount: Int,
    on: String,
    wallet: Identifier<Wallet>,
): Entry {
    val now = Instant.ofEpochSecond(1_791_000_000)

    return Entry(
        type = type,
        amount = amount,
        date = date(on),
        categoryId = null,
        walletId = wallet,
        createdAt = now,
        updatedAt = now,
    )
}
