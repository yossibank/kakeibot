package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class EntryItem(
    val id: Identifier<EntryItem> = Identifier(),
    val entryId: Identifier<Entry>,
    val name: String,
    val quantity: Int = 1,
    val amount: Int,
    val taxRate: AmountCalculator.TaxRate? = null,
    val sortOrder: Int,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    data class Draft(
        val name: String,
        val quantity: Int = 1,
        val amount: Int,
        val taxRate: AmountCalculator.TaxRate? = null,
        val readName: String? = null,
    ) {
        constructor(item: EntryItem) : this(
            name = item.name,
            quantity = item.quantity,
            amount = item.amount,
            taxRate = item.taxRate,
        )

        val trimmedName: String
            get() = name.trim()
    }
}
