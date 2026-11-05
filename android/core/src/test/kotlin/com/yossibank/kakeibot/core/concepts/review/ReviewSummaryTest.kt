package com.yossibank.kakeibot.core.concepts.review

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
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

@RunWith(Parameterized::class)
class ReviewSummaryTest(
    private val fixture: SummaryCase,
) {
    @Serializable
    data class SummaryCase(
        val summary: String,
        val start: LocalDate,
        val end: LocalDate,
        val entries: List<Row>,
        val expense: Totals,
        val income: Totals,
        val balance: Int,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class Row(
        val type: Entry.Kind,
        val amount: Int,
        val date: LocalDate,
        val category: String? = null,
        val wallet: String,
    )

    @Serializable
    data class Totals(
        val total: Int,
        val categories: Map<String, Int>,
        val wallets: Map<String, Int>,
    )

    class Ids {
        val categories: Map<String, Identifier<EntryCategory>> = mapOf(
            "food" to Identifier(),
            "daily" to Identifier(),
            "salary" to Identifier(),
        )

        val wallets: Map<String, Identifier<Wallet>> = mapOf(
            "cash" to Identifier(),
            "card" to Identifier(),
            "bank" to Identifier(),
        )

        fun wallet(name: String): Identifier<Wallet> = wallets[name] ?: Identifier()

        fun named(breakdown: ReviewSummary.Breakdown): Totals {
            val categoryNames = categories.entries.associate { (name, id) -> id to name }
            val walletNames = wallets.entries.associate { (name, id) -> id to name }

            val categoryTotals = breakdown.byCategory.entries.associate { (id, amount) ->
                (categoryNames[id] ?: id.toString()) to amount
            }

            val walletTotals = breakdown.byWallet.entries.associate { (id, amount) ->
                (walletNames[id] ?: id.toString()) to amount
            }

            return Totals(
                total = breakdown.total,
                categories = categoryTotals,
                wallets = walletTotals,
            )
        }
    }

    @Test
    fun sumsEntriesInRange() {
        val ids = Ids()
        val now = Instant.ofEpochSecond(1_791_000_000)
        val range = fixture.start..fixture.end

        val entries = fixture.entries.map { row ->
            Entry(
                type = row.type,
                amount = row.amount,
                date = row.date,
                categoryId = row.category?.let { ids.categories[it] },
                walletId = ids.wallet(row.wallet),
                createdAt = now,
                updatedAt = now,
            )
        }

        val summary = ReviewSummary(
            entries = entries,
            range = range,
        )

        assertEquals(fixture.expense, ids.named(summary.expense))
        assertEquals(fixture.income, ids.named(summary.income))
        assertEquals(fixture.balance, summary.balance)
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<SummaryCase> = CoreFixture.cases("review/review-summary.json", SummaryCase.serializer())
    }
}
