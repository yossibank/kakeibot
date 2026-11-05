package com.yossibank.kakeibot.core.concepts.review

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class ReviewSummaryTotalTest {
    @Test
    fun sumsWithoutWrappingAround() {
        val limit = 999_999_999
        val date = assertNotNull(LocalDate.parse("2026-10-01"))
        val now = Instant.ofEpochSecond(1_791_000_000)
        val category = Identifier<EntryCategory>()
        val wallet = Identifier<Wallet>()

        val entries = List(3) {
            Entry(
                type = Entry.Kind.expense,
                amount = limit,
                date = date,
                categoryId = category,
                walletId = wallet,
                createdAt = now,
                updatedAt = now,
            )
        }

        val summary = ReviewSummary(
            entries = entries,
            range = date..date,
        )

        assertEquals(3L * limit, summary.expense.total)
        assertEquals(3L * limit, summary.expense.byCategory[category])
        assertEquals(3L * limit, summary.expense.byWallet[wallet])
        assertEquals(-3L * limit, summary.balance)
    }
}
