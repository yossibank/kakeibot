package com.yossibank.kakeibot.appfeature.main

import androidx.compose.runtime.Composable
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.screens.main.MainModel

@Composable
internal fun rememberMainModel(): MainModel = rememberSaveable(saver = saver) { MainModel() }

private const val ENTRY = "entry"
private const val BUDGET = "budget"
private const val SETTINGS = "settings"
private const val SEPARATOR = ","

private val saver: Saver<MainModel, List<String>> = Saver(
    save = { model ->
        val tabs = listOf(
            model.state.tab.name,
            model.state.visitedTabs.joinToString(SEPARATOR) { it.name },
        )

        tabs + saved(model.state.sheet)
    },
    restore = { names ->
        MainModel(
            tab = MainModel.Tab.valueOf(names[0]),
            visitedTabs = names[1].split(SEPARATOR).map(MainModel.Tab::valueOf).toSet(),
            sheet = sheet(names.drop(2)),
        )
    },
)

private fun saved(sheet: MainModel.Sheet?): List<String> = when (sheet) {
    is MainModel.Sheet.Entry -> listOfNotNull(ENTRY, sheet.editing?.toString())
    MainModel.Sheet.Budget -> listOf(BUDGET)
    is MainModel.Sheet.Settings -> listOf(SETTINGS)
    null -> emptyList()
}

private fun sheet(names: List<String>): MainModel.Sheet? = when (names.firstOrNull()) {
    ENTRY -> MainModel.Sheet.Entry(editing = names.getOrNull(1)?.let { Identifier.parse(it) })
    BUDGET -> MainModel.Sheet.Budget
    SETTINGS -> MainModel.Sheet.Settings()
    else -> null
}
