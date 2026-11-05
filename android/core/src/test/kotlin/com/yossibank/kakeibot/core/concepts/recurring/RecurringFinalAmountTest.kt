package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@RunWith(Parameterized::class)
class RecurringFinalAmountTest(
    private val fixture: FinalCase,
) {
    @Serializable
    data class FinalCase(
        val summary: String,
        val amount: Int,
        val finalAmount: Int? = null,
        val day: Int,
        val startDate: LocalDate,
        val count: Int,
        val endDate: LocalDate,
        val total: Long,
    ) {
        override fun toString(): String = summary
    }

    @Test
    fun findsEndDateFromCount() {
        val recurring = recurring(endDate = null)

        assertEquals(fixture.endDate, recurring.endDate(afterCount = fixture.count))
    }

    @Test
    fun countsEndDateFromLaterDay() {
        val recurring = recurring(endDate = null).copy(
            amount = 16235,
            day = 27,
            startDate = date("2026-10-27"),
        )

        val end = recurring.endDate(
            afterCount = 2,
            from = date("2027-01-01"),
        )

        assertEquals(date("2027-02-27"), end)
    }

    @Test
    fun countsOccurrences() {
        val recurring = recurring(endDate = fixture.endDate)

        assertEquals(fixture.count, recurring.occurrenceCount)
    }

    @Test
    fun addsUpPlannedTotal() {
        val recurring = recurring(endDate = fixture.endDate)

        assertEquals(fixture.total, recurring.plannedTotal)
    }

    @Test
    fun limitsCount() {
        val recurring = recurring(endDate = null)

        assertNotNull(recurring.endDate(afterCount = Recurring.maxCount))
        assertNull(recurring.endDate(afterCount = Recurring.maxCount + 1))
    }

    @Test
    fun usesFinalAmountOnlyOnFinalDate() {
        val recurring = recurring(endDate = fixture.endDate)
        val final = recurring.finalAmount

        assertEquals(fixture.endDate, recurring.finalDate)
        assertEquals(final ?: fixture.amount, recurring.scheduledAmount(paidOn = fixture.endDate))
        assertEquals(fixture.amount, recurring.scheduledAmount(paidOn = fixture.startDate.adding(days = -1)))
    }

    private fun recurring(endDate: LocalDate?): Recurring {
        val now = Instant.ofEpochSecond(1_791_000_000)

        return Recurring(
            type = Entry.Kind.transfer,
            amount = fixture.amount,
            categoryId = null,
            walletId = Identifier<Wallet>(),
            toWalletId = Identifier<Wallet>(),
            frequency = Recurring.Frequency.monthly,
            day = fixture.day,
            finalAmount = fixture.finalAmount,
            startDate = fixture.startDate,
            endDate = endDate,
            createdAt = now,
            updatedAt = now,
        )
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<FinalCase> = CoreFixture.cases("recurring/final-amount.json", FinalCase.serializer())
    }
}

private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))
