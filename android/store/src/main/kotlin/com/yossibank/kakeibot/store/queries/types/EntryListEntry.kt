package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.entry.Entry

fun EntryList.title(of: Entry): String {
    val category = of.categoryId?.let { categories[it] }

    if (category != null) {
        return category.name
    }

    return when (of.type) {
        Entry.Kind.transfer -> "振替"
        Entry.Kind.expense, Entry.Kind.income -> "未分類"
    }
}
