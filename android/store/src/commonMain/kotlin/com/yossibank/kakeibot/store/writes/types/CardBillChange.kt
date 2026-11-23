package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.entry.Entry

internal class CardBillChange(
    before: List<Entry> = emptyList(),
    after: List<Entry> = emptyList(),
) {
    val before: MutableList<Entry> = before.toMutableList()
    val after: MutableList<Entry> = after.toMutableList()
}
