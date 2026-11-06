package com.yossibank.kakeibot.core.concepts.reward

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class RewardBalanceTest {
    @Test
    fun sumsWithoutWrappingAround() {
        val limit = 999_999_999
        val now = Instant.ofEpochSecond(1_791_000_000)
        val date = assertNotNull(LocalDate.parse("2026-10-01"))

        val logs = List(3) {
            RewardLog(
                ruleId = Identifier(),
                date = date,
                amount = limit,
                createdAt = now,
            )
        }

        val amount = RewardBalance.amount(
            logs = logs,
            goals = emptyList(),
        )

        assertEquals(3L * limit, amount)
    }
}
