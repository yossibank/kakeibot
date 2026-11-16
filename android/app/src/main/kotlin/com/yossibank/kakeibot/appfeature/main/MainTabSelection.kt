package com.yossibank.kakeibot.appfeature.main

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.setValue

class MainTabSelection(
    value: MainTab = MainTab.Home,
    visited: Set<MainTab> = setOf(MainTab.Home),
) {
    var value: MainTab by mutableStateOf(value)
        private set

    var visited: Set<MainTab> by mutableStateOf(visited)
        private set

    fun select(tab: MainTab) {
        value = tab
        visited = visited + tab
    }

    companion object {
        val Saver: Saver<MainTabSelection, List<String>> = Saver(
            save = { selection ->
                listOf(selection.value.name) + selection.visited.map { it.name }
            },
            restore = { names ->
                MainTabSelection(
                    value = MainTab.valueOf(names.first()),
                    visited = names.drop(1).map(MainTab::valueOf).toSet(),
                )
            },
        )
    }
}
