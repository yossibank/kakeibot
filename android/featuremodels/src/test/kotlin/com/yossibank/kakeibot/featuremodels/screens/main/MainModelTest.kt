package com.yossibank.kakeibot.featuremodels.screens.main

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MainModelTest {
    private val date = checkNotNull(LocalDate.parse("2026-10-15"))

    @Test
    fun opensHomeRoute() {
        val model = MainModel()
        model.state.select(MainModel.Tab.Records)

        model.open(PlannedNotification.Route.Home)

        assertEquals(MainModel.Tab.Home, model.state.tab)
        assertNull(model.state.sheet)
        assertEquals(setOf(MainModel.Tab.Home, MainModel.Tab.Records), model.state.visitedTabs)
    }

    @Test
    fun opensEntryRouteOnCurrentTab() {
        val model = MainModel()
        model.state.select(MainModel.Tab.Assets)

        model.open(PlannedNotification.Route.Entry(date = date))

        assertEquals(MainModel.Tab.Assets, model.state.tab)
        assertEquals(MainModel.Sheet.Entry(editing = null), model.state.sheet)
    }

    @Test
    fun opensRecurringRouteOnCurrentTab() {
        val model = MainModel()
        val id = Identifier<Recurring>()
        model.state.select(MainModel.Tab.Review)

        model.open(PlannedNotification.Route.Recurring(id = id))
        val first = model.state.sheet
        model.open(PlannedNotification.Route.Recurring(id = id))

        assertEquals(MainModel.Tab.Review, model.state.tab)
        assertEquals(MainModel.Sheet.Settings(recurring = id, round = 1), first)
        assertEquals(MainModel.Sheet.Settings(recurring = id, round = 2), model.state.sheet)
    }

    @Test
    fun replacesOpenSheetWithRouteAtOnce() {
        val model = MainModel(sheet = MainModel.Sheet.Settings())
        model.state.select(MainModel.Tab.Records)

        model.open(PlannedNotification.Route.Entry(date = date))

        assertEquals(MainModel.Tab.Records, model.state.tab)
        assertEquals(MainModel.Sheet.Entry(editing = null), model.state.sheet)
    }

    @Test
    fun keepsTabsAndSheetWhenRestored() {
        val id = Identifier<Entry>()

        val model = MainModel(
            tab = MainModel.Tab.Review,
            visitedTabs = setOf(MainModel.Tab.Home, MainModel.Tab.Review),
            sheet = MainModel.Sheet.Entry(editing = id),
        )

        model.state.select(MainModel.Tab.Assets)

        assertEquals(MainModel.Tab.Assets, model.state.tab)
        assertEquals(MainModel.Tab.entries.toSet() - MainModel.Tab.Records, model.state.visitedTabs)
        assertEquals(MainModel.Sheet.Entry(editing = id), model.state.sheet)
    }
}
