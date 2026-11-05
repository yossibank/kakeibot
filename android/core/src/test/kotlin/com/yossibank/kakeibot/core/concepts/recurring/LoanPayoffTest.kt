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

@RunWith(Parameterized::class)
class LoanPayoffTest(
    private val fixture: PayoffCase,
) {
    @Serializable
    data class PayoffCase(
        val summary: String,
        val balance: Int,
        val today: LocalDate,
        val repayments: List<RepaymentCase>,
        val count: Int? = null,
        val lastDate: LocalDate? = null,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class RepaymentCase(
        val amount: Int,
        val day: Int,
        val endDate: LocalDate? = null,
        val finalAmount: Int? = null,
    )

    @Test
    fun findsLastRepayment() {
        val loan = Identifier<Wallet>()
        val now = Instant.ofEpochSecond(1_791_000_000)
        val startDate = assertNotNull(LocalDate.parse("2026-01-01"))

        val repayments = fixture.repayments.map { repayment ->
            Recurring(
                type = Entry.Kind.transfer,
                amount = repayment.amount,
                categoryId = null,
                walletId = Identifier(),
                toWalletId = loan,
                frequency = Recurring.Frequency.monthly,
                day = repayment.day,
                finalAmount = repayment.finalAmount,
                startDate = startDate,
                endDate = repayment.endDate,
                createdAt = now,
                updatedAt = now,
            )
        }

        val payoff = LoanPayoff.of(
            balance = fixture.balance,
            repayments = repayments,
            after = fixture.today,
        )

        assertEquals(fixture.count, payoff?.count)
        assertEquals(fixture.lastDate, payoff?.lastDate)
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<PayoffCase> = CoreFixture.cases("recurring/loan-payoff.json", PayoffCase.serializer())
    }
}
