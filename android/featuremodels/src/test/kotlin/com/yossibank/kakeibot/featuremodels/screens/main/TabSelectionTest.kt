package com.yossibank.kakeibot.featuremodels.screens.main

import org.junit.Test
import kotlin.test.assertEquals

class TabSelectionTest {
    @Test
    fun startsOnHome() {
        val tabs = MainModel.TabSelection()

        assertEquals(MainModel.Tab.Home, tabs.current)
        assertEquals(setOf(MainModel.Tab.Home), tabs.visited)
    }

    @Test
    fun remembersVisitedTabs() {
        val tabs = MainModel.TabSelection()
            .selected(MainModel.Tab.Review)
            .selected(MainModel.Tab.Home)

        assertEquals(MainModel.Tab.Home, tabs.current)
        assertEquals(setOf(MainModel.Tab.Home, MainModel.Tab.Review), tabs.visited)
    }
}
