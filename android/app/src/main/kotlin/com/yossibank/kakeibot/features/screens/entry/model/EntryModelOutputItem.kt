package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItemTotal

const val ITEM_SUGGESTION_LIMIT = 8

val EntryModel.Output.showsItems: Boolean
    get() = state.form.type != Entry.Kind.transfer

val EntryModel.Output.itemTotals: EntryItemTotal
    get() = EntryItemTotal(
        items = state.form.items,
        taxIncluded = state.form.taxIncluded,
    )

val EntryModel.Output.itemTotal: Long
    get() = itemTotals.total

val EntryModel.Output.itemAdjustment: Long
    get() = amount - itemTotal

val EntryModel.Output.itemCount: Int
    get() = state.form.items.sumOf { it.quantity }

val EntryModel.Output.hasItemAdjustment: Boolean
    get() = state.form.items.isNotEmpty() && itemAdjustment != 0L

val EntryModel.Output.canAdjustToItems: Boolean
    get() = itemTotal in 0..AmountCalculator.maxValue.toLong()

fun EntryModel.Output.itemNameSuggestions(text: String): List<String> {
    val trimmed = text.trim()

    val names = if (trimmed.isEmpty()) {
        input.recentItemNames
    } else {
        input.recentItemNames.filter { it != trimmed && it.contains(trimmed, ignoreCase = true) }
    }

    return names.take(ITEM_SUGGESTION_LIMIT)
}
