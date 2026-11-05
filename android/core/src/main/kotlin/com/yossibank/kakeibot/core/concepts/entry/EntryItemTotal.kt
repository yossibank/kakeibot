package com.yossibank.kakeibot.core.concepts.entry

import kotlin.math.absoluteValue

@ConsistentCopyVisibility
data class EntryItemTotal private constructor(
    val subtotal: Long,
    val taxes: List<Tax>,
    val total: Long,
    val taxIncluded: Boolean,
) {
    data class Tax(
        val rate: AmountCalculator.TaxRate,
        val base: Long,
        val amount: Long,
    ) {
        internal companion object {
            fun of(
                rate: AmountCalculator.TaxRate,
                items: List<EntryItem.Draft>,
                taxIncluded: Boolean,
            ): Tax? {
                val rated = items.filter { it.taxRate == rate }

                if (rated.isEmpty()) {
                    return null
                }

                val base = rated.sumOf { it.amount.toLong() }

                val amount = if (taxIncluded) {
                    included(
                        base = base,
                        rate = rate.rawValue,
                    )
                } else {
                    base * rate.rawValue / 100
                }

                return Tax(
                    rate = rate,
                    base = base,
                    amount = amount,
                )
            }

            private fun included(
                base: Long,
                rate: Int,
            ): Long {
                val numerator = base.absoluteValue * rate * 2 + 100 + rate
                val rounded = numerator / ((100 + rate) * 2)

                return if (base < 0) -rounded else rounded
            }
        }
    }

    companion object {
        operator fun invoke(
            items: List<EntryItem.Draft>,
            taxIncluded: Boolean = false,
        ): EntryItemTotal {
            val subtotal = items.sumOf { it.amount.toLong() }

            val taxes = AmountCalculator.TaxRate.entries.mapNotNull { rate ->
                Tax.of(
                    rate = rate,
                    items = items,
                    taxIncluded = taxIncluded,
                )
            }

            val tax = taxes.sumOf { it.amount }

            return EntryItemTotal(
                subtotal = subtotal,
                taxes = taxes,
                total = if (taxIncluded) subtotal else subtotal + tax,
                taxIncluded = taxIncluded,
            )
        }
    }
}
