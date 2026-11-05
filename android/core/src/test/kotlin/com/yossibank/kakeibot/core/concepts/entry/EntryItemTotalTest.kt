package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class EntryItemTotalTest(
    private val fixture: TotalCase,
) {
    @Serializable
    data class TotalCase(
        val summary: String,
        val taxIncluded: Boolean,
        val items: List<Item>,
        val subtotal: Int,
        val taxes: List<Tax>,
        val total: Int,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class Item(
        val amount: Int,
        val taxRate: Int? = null,
    )

    @Serializable
    data class Tax(
        val rate: Int,
        val base: Int,
        val amount: Int,
    )

    @Test
    fun totalsItems() {
        val items = fixture.items.map { item ->
            EntryItem.Draft(
                name = "品目",
                amount = item.amount,
                taxRate = item.taxRate?.let { AmountCalculator.TaxRate.of(it) ?: error("知らない率: $it") },
            )
        }

        val total = EntryItemTotal(
            items = items,
            taxIncluded = fixture.taxIncluded,
        )

        val taxes = total.taxes.map { tax ->
            Tax(
                rate = tax.rate.rawValue,
                base = tax.base,
                amount = tax.amount,
            )
        }

        assertEquals(fixture.subtotal, total.subtotal)
        assertEquals(fixture.taxes, taxes)
        assertEquals(fixture.total, total.total)
        assertEquals(fixture.taxIncluded, total.taxIncluded)
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<TotalCase> = CoreFixture.cases("entry/entry-item-total.json", TotalCase.serializer())
    }
}
