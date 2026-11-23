package com.yossibank.kakeibot.appfeature.main

import androidx.compose.runtime.saveable.Saver
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.concepts.entry.Entry as Record

sealed interface MainSheet {
    data object Budget : MainSheet

    data class Entry(
        val editing: Identifier<Record>?,
    ) : MainSheet

    data class Settings(
        val recurring: Identifier<Recurring>? = null,
        val round: Int = 0,
    ) : MainSheet

    companion object {
        private const val ENTRY = "entry"
        private const val BUDGET = "budget"
        private const val SETTINGS = "settings"

        val Saver: Saver<MainSheet?, List<String>> = Saver(
            save = { sheet ->
                when (sheet) {
                    is Entry -> listOfNotNull(ENTRY, sheet.editing?.toString())
                    Budget -> listOf(BUDGET)
                    is Settings -> listOf(SETTINGS)
                    null -> emptyList()
                }
            },
            restore = { names ->
                when (names.firstOrNull()) {
                    ENTRY -> Entry(editing = names.getOrNull(1)?.let { Identifier.parse(it) })
                    BUDGET -> Budget
                    SETTINGS -> Settings()
                    else -> null
                }
            },
        )
    }
}
