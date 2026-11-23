package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.RecurringCardBillFixture.bill
import com.yossibank.kakeibot.core.concepts.recurring.RecurringCardBillFixture.date
import com.yossibank.kakeibot.core.concepts.recurring.RecurringCardBillFixture.entry
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class RecurringCardBillAmountTest {
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
        val payment = entry(
            Entry.Kind.transfer,
            45000,
            "2026-10-10",
            bill.walletId,
        ).copy(toWalletId = card)

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
        val late = entry(
            Entry.Kind.expense,
            3000,
            "2026-08-31",
            card,
        ).copy(billMonth = november.yearMonth)
        val moved = entry(
            Entry.Kind.expense,
            500,
            "2026-09-20",
            card,
        ).copy(billMonth = november.yearMonth)

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
        val moved = entry(
            Entry.Kind.expense,
            500,
            "2027-01-20",
            card,
        ).copy(billMonth = YearMonth.parse("2027-02"))

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

        assertEquals(
            listOf("2026-09-10", "2026-10-10", "2026-11-10"),
            dates.map {
                it.toString()
            },
        )
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

        assertEquals(
            listOf("2026-09-10", "2026-10-10", "2026-11-10"),
            dates.map {
                it.toString()
            },
        )
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
