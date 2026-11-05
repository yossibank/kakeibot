package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class LoanPayoffBalanceTest {
    @Test
    fun countsRepaymentsBeyondIntRange() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val start = assertNotNull(LocalDate.parse("2026-01-01"))
        val today = assertNotNull(LocalDate.parse("2026-10-20"))

        val repayment = Recurring(
            type = Entry.Kind.transfer,
            amount = 999_999_999,
            categoryId = null,
            walletId = Identifier(),
            toWalletId = Identifier(),
            frequency = Recurring.Frequency.monthly,
            day = 27,
            startDate = start,
            createdAt = now,
            updatedAt = now,
        )

        val payoff = assertNotNull(
            LoanPayoff.of(
                balance = -3_000_000_000L,
                repayments = listOf(repayment),
                after = today,
            ),
        )

        assertEquals(4, payoff.count)
    }
}
