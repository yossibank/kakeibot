package com.yossibank.kakeibot.featuremodels.screens.main

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier

fun MainModel.saved(): List<String> {
    val tabs = listOf(
        state.tab.name,
        state.visitedTabs.joinToString(SEPARATOR) { it.name },
    )

    return tabs + saved(state.sheet.current)
}

fun MainModel.Companion.restore(saved: List<String>): MainModel = MainModel(
    tab = MainModel.Tab.valueOf(saved[0]),
    visitedTabs = saved[1].split(SEPARATOR).map(MainModel.Tab::valueOf).toSet(),
    sheet = sheet(saved.drop(2)),
)

private fun saved(sheet: MainModel.Sheet?): List<String> = when (sheet) {
    is MainModel.Sheet.Entry -> listOf(
        ENTRY,
        sheet.editing?.toString().orEmpty(),
        sheet.date?.toString().orEmpty(),
    )

    MainModel.Sheet.Budget -> listOf(BUDGET)

    is MainModel.Sheet.Settings -> listOf(SETTINGS)

    null -> emptyList()
}

private fun sheet(names: List<String>): MainModel.Sheet? = when (names.firstOrNull()) {
    ENTRY -> MainModel.Sheet.Entry(
        editing = names.getOrNull(1)?.let { Identifier.parse(it) },
        date = names.getOrNull(2)?.let { LocalDate.parse(it) },
    )

    BUDGET -> MainModel.Sheet.Budget

    SETTINGS -> MainModel.Sheet.Settings()

    else -> null
}

private const val ENTRY = "entry"
private const val BUDGET = "budget"
private const val SETTINGS = "settings"
private const val SEPARATOR = ","
