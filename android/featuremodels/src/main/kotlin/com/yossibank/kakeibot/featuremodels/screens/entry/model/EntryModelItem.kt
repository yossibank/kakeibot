package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText

const val RECENT_ITEM_NAME_LIMIT = 50

var EntryModel.State.store: String
    get() = form.store
    set(value) {
        update { withStore(value) }
    }

fun EntryModel.addItem(item: EntryItem.Draft) {
    changeItems {
        state.update { copy(items = items + item) }
    }
}

fun EntryModel.updateItem(
    index: Int,
    item: EntryItem.Draft,
) {
    if (index !in state.form.items.indices) {
        return
    }

    changeItems {
        state.update { copy(items = items.toMutableList().also { it[index] = item }) }
    }
}

fun EntryModel.removeItem(index: Int): RemovedItem? {
    val item = state.form.items.getOrNull(index) ?: return null

    changeItems {
        state.update { copy(items = items.toMutableList().also { it.removeAt(index) }) }
    }

    return RemovedItem(
        index = index,
        item = item,
    )
}

fun EntryModel.restoreItem(removed: RemovedItem) {
    changeItems {
        state.update {
            val restored = items.toMutableList()
            restored.add(minOf(removed.index, restored.size), removed.item)

            copy(items = restored)
        }
    }
}

fun EntryModel.setTaxIncluded(isIncluded: Boolean) {
    changeItems {
        state.update { copy(taxIncluded = isIncluded) }
    }
}

fun EntryModel.adjustToItems() {
    if (!output.canAdjustToItems) {
        return
    }

    state.setAmount(output.itemTotal.toInt())
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
    val follows = output.amount == 0 || output.itemAdjustment == 0L

    change()

    if (follows) {
        adjustToItems()
    }
}
