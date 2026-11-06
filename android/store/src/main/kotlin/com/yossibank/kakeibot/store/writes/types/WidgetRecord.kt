package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier

data class WidgetRecord(
    val entryId: Identifier<Entry>,
    val clearedNoSpendDate: LocalDate? = null,
) {
    val text: String
        get() {
            val date = clearedNoSpendDate ?: return entryId.toString()

            return "$entryId,$date"
        }

    companion object {
        fun parse(text: String): WidgetRecord? {
            val trimmed = text.trimStart(',')
            val comma = trimmed.indexOf(',')
            val first = if (comma < 0) trimmed else trimmed.substring(0, comma)
            val rest = if (comma < 0) "" else trimmed.substring(comma + 1)

            if (first.isEmpty()) {
                return null
            }

            val entryId = Identifier.parse<Entry>(first) ?: return null
            val clearedNoSpendDate = rest.ifEmpty { null }?.let { LocalDate.parse(it) }

            return WidgetRecord(
                entryId = entryId,
                clearedNoSpendDate = clearedNoSpendDate,
            )
        }
    }
}
