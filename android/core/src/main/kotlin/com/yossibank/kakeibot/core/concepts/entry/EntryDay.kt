package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier

data class EntryDay(
    val date: LocalDate,
    val entries: List<Entry>,
) {
    val expenseTotal: Int
        get() = total(Entry.Kind.expense)

    val incomeTotal: Int
        get() = total(Entry.Kind.income)

    private fun total(type: Entry.Kind): Int = entries.filter { it.type == type }.sumOf { it.amount }

    companion object {
        fun grouping(
            entries: List<Entry>,
            categories: Map<Identifier<EntryCategory>, EntryCategory> = emptyMap(),
        ): List<EntryDay> {
            val order = compareBy<Entry>(
                { rank(it, categories).first },
                { rank(it, categories).second },
            )
                .thenByDescending { it.createdAt }
                .thenBy { it.id.toString() }

            return entries
                .groupBy { it.date }
                .map { (date, entries) ->
                    EntryDay(
                        date = date,
                        entries = entries.sortedWith(order),
                    )
                }
                .sortedByDescending { it.date }
        }

        private fun rank(
            entry: Entry,
            categories: Map<Identifier<EntryCategory>, EntryCategory>,
        ): Pair<Int, Int> {
            val category = entry.categoryId?.let { categories[it] } ?: return 2 to 0
            val kind = if (category.kind == EntryCategory.Kind.expense) 0 else 1

            return kind to category.sortOrder
        }
    }
}

fun List<EntryDay>.filtered(isIncluded: (Entry) -> Boolean): List<EntryDay> = mapNotNull { day ->
    val entries = day.entries.filter(isIncluded)

    if (entries.isEmpty()) {
        null
    } else {
        EntryDay(
            date = day.date,
            entries = entries,
        )
    }
}
