package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryItemTotal
import com.yossibank.kakeibot.designsystem.components.text.AmountText

const val RECENT_ITEM_NAME_LIMIT = 50
const val ITEM_SUGGESTION_LIMIT = 8

val EntryModel.showsItems: Boolean
    get() = form.type != Entry.Kind.transfer

val EntryModel.itemTotals: EntryItemTotal
    get() = EntryItemTotal(
        items = form.items,
        taxIncluded = form.taxIncluded,
    )

val EntryModel.itemTotal: Long
    get() = itemTotals.total

val EntryModel.itemAdjustment: Long
    get() = amount - itemTotal

val EntryModel.itemCount: Int
    get() = form.items.sumOf { it.quantity }

val EntryModel.hasItemAdjustment: Boolean
    get() = form.items.isNotEmpty() && itemAdjustment != 0L

val EntryModel.canAdjustToItems: Boolean
    get() = itemTotal in 0..AmountCalculator.maxValue.toLong()

var EntryModel.store: String
    get() = form.store
    set(value) {
        update { withStore(value) }
    }

fun EntryModel.itemNameSuggestions(text: String): List<String> {
    val trimmed = text.trim()

    val names = if (trimmed.isEmpty()) {
        recentItemNames
    } else {
        recentItemNames.filter { it != trimmed && it.contains(trimmed, ignoreCase = true) }
    }

    return names.take(ITEM_SUGGESTION_LIMIT)
}

fun EntryModel.addItem(item: EntryItem.Draft) {
    changeItems {
        update { copy(items = items + item) }
    }
}

fun EntryModel.updateItem(
    index: Int,
    item: EntryItem.Draft,
) {
    if (index !in form.items.indices) {
        return
    }

    changeItems {
        update { copy(items = items.toMutableList().also { it[index] = item }) }
    }
}

fun EntryModel.removeItem(index: Int): RemovedItem? {
    val item = form.items.getOrNull(index) ?: return null

    changeItems {
        update { copy(items = items.toMutableList().also { it.removeAt(index) }) }
    }

    return RemovedItem(
        index = index,
        item = item,
    )
}

fun EntryModel.restoreItem(removed: RemovedItem) {
    changeItems {
        update {
            val restored = items.toMutableList()
            restored.add(minOf(removed.index, restored.size), removed.item)
            copy(items = restored)
        }
    }
}

fun EntryModel.setTaxIncluded(isIncluded: Boolean) {
    changeItems {
        update { copy(taxIncluded = isIncluded) }
    }
}

fun EntryModel.adjustToItems() {
    if (!canAdjustToItems) {
        return
    }

    setAmount(itemTotal.toInt())
}

fun EntryItem.Draft.quantityText(): String? {
    if (quantity <= 1) {
        return null
    }

    val price = unitPrice()

    return if (price.second > 1) {
        "${price.second} × ${AmountText.text(price.first)}"
    } else {
        "×$quantity"
    }
}

fun EntryItem.Draft.unitPrice(): Pair<Int, Int> {
    if (quantity <= 1 || amount % quantity != 0) {
        return amount to 1
    }

    return amount / quantity to quantity
}

private fun EntryModel.changeItems(change: () -> Unit) {
    val follows = amount == 0 || itemAdjustment == 0L

    change()

    if (follows) {
        adjustToItems()
    }
}
