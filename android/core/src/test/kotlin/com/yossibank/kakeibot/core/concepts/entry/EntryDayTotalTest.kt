package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class EntryDayTotalTest {
    @Test
    fun sumsWithoutWrappingAround() {
        val limit = 999_999_999
        val date = assertNotNull(LocalDate.parse("2026-10-01"))
        val now = Instant.ofEpochSecond(1_791_000_000)

        val entries = List(3) {
            Entry(
                type = Entry.Kind.expense,
                amount = limit,
                date = date,
                categoryId = Identifier(),
                walletId = Identifier(),
                createdAt = now,
                updatedAt = now,
            )
        }

        val day = EntryDay(
            date = date,
            entries = entries,
        )

        assertEquals(3L * limit, day.expenseTotal)
        assertEquals(0L, day.incomeTotal)
    }
}
