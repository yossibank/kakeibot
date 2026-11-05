package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
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
class EntryFilterTest(
    private val fixture: FilterCase,
) {
    @Serializable
    data class FilterCase(
        val summary: String,
        val categories: List<String>,
        val wallets: List<String>,
        val tags: List<String>,
        val entries: List<EntryItem>,
        val keptIds: List<String>,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class EntryItem(
        val id: String,
        val category: String? = null,
        val wallet: String,
        val toWallet: String? = null,
        val tag: String? = null,
        val date: LocalDate,
    )

    @Test
    fun keepsChosenEntries() {
        val filter = EntryFilter(
            categoryIds = fixture.categories.map { identifier<EntryCategory>(it) }.toSet(),
            walletIds = fixture.wallets.map { identifier<Wallet>(it) }.toSet(),
            tagIds = fixture.tags.map { identifier<EntryTag>(it) }.toSet(),
        )

        val createdAt = Instant.ofEpochSecond(1_791_000_000)

        val entries = fixture.entries.map { item ->
            Entry(
                id = identifier(item.id),
                type = Entry.Kind.expense,
                amount = 100,
                date = item.date,
                categoryId = item.category?.let { identifier(it) },
                tagId = item.tag?.let { identifier(it) },
                walletId = identifier(item.wallet),
                toWalletId = item.toWallet?.let { identifier(it) },
                createdAt = createdAt,
                updatedAt = createdAt,
            )
        }

        val days = EntryDay.grouping(entries)
        val kept = filter.apply(to = days).flatMap { it.entries }

        assertEquals(fixture.keptIds.map { identifier<Entry>(it) }, kept.map { it.id })
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<FilterCase> = CoreFixture.cases("entry/entry-filter.json", FilterCase.serializer())
    }
}

private fun <Owner> identifier(text: String): Identifier<Owner> = Identifier.parse(text) ?: error("ID が読めない: $text")
